import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;

import '../models/playback_status.dart';
import '../models/playback_event.dart';
import '../models/playback_track.dart';
import 'playback_controller.dart';
import 'background_playback_experiment.dart';
import 'youtube_playback_engine.dart';

/// Returns an ISO-8601-like timestamp for diagnostic log lines.
String _ts() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}.'
      '${now.millisecond.toString().padLeft(3, '0')}';
}

/// Tagged diagnostic print — always present regardless of experiment flag.
void _diag(String msg) =>
    debugPrint('${_ts()} ${BackgroundPlaybackExperiment.tag} $msg');

// ---------------------------------------------------------------------------
// IframeYoutubePlaybackEngine
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// MediaKitPlaybackEngine
// ---------------------------------------------------------------------------


class IframeYoutubePlaybackEngine implements YoutubePlaybackEngine {
  final PlaybackController fallback;

  /// Factory for YouTube player controllers (used in tests and production).
  final yt.YoutubePlayerController Function(String, yt.YoutubePlayerParams)?
  youtubeControllerFactory;

  IframeYoutubePlaybackEngine({
    required this.fallback,
    this.youtubeControllerFactory,
  }) {
    _fallbackSubscriptions.add(
      fallback.statusStream.listen((status) {
        if (!_disposed && !_isYoutube) _updateStatus(status);
      }),
    );
    _fallbackSubscriptions.add(
      fallback.eventStream.listen((event) {
        if (!_disposed && !_isYoutube) _eventController.add(event);
      }),
    );
  }

  final List<StreamSubscription<dynamic>> _fallbackSubscriptions = [];
  bool _isYoutube = false;

  /// Informs the engine that the host activity is stopped (e.g. screen locked).
  /// Used to block IFrame playback dispatches when the WebView is frozen.
  static bool isActivityStopped = false;

  // ── Native session ─────────────────────────────────────────────────────────

  // ── YouTube/IFrame state ──────────────────────────────────────────────────
  yt.YoutubePlayerController? _youtubeController;

  /// Long-lived IFrame subscriptions, separate from session subscriptions.
  final List<StreamSubscription<dynamic>> _iframeSubscriptions = [];

  // ── Engine counters ────────────────────────────────────────────────────────
  int _playGeneration = 0;
  int _lastPlayedGeneration = 0;
  int _intentRevision = 0;
  bool _disposed = false;
  bool _attemptActive = false;
  Future<void>? _invalidationFuture;
  bool _recoveryUsed = false;
  bool _ready = false;
  int? _latePauseGeneration;
  int? _pauseIntentGeneration;

  // YouTube can repeat a paused value for metadata/quality updates. On iOS,
  // coalesce corrections and invalidate delayed checks when a newer playback
  // event or user intent arrives. A short cooldown still permits retries if
  // the first command did not actually resume playback.
  (int, int)? _iosPauseRecoveryEpisode;
  Object? _iosPauseRecoveryToken;
  Timer? _iosPauseRecoveryCooldown;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _cancelIOSPauseRecovery() {
    _iosPauseRecoveryCooldown?.cancel();
    _iosPauseRecoveryCooldown = null;
    _iosPauseRecoveryEpisode = null;
    _iosPauseRecoveryToken = null;
  }

  bool _valid(int generation) =>
      !_disposed && _attemptActive && generation == _playGeneration;

  double? _currentStartSeconds;
  Duration? _confirmedPlaybackPosition;
  int _confirmedPositionGeneration = -1;

  Timer? _watchdogTimer;
  Timer? _iframePositionTimer;

  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();

  PlaybackStatus _currentStatus = const PlaybackStatus(supportsSpeed: true);
  PlaybackState? _intendedState;

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // PlaybackController interface
  // ---------------------------------------------------------------------------

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackEvent> get eventStream => _eventController.stream;

  @override
  PlaybackStatus get currentStatus => _currentStatus;

  /// Returns the [VideoController] for the currently active native session,
  /// or null when no native session is active (idle, IFrame mode, or disposed).
  @override
  dynamic get renderer {
    if (!_isYoutube) return fallback.renderer;
    if (_youtubeController == null) return null;
    return yt.YoutubePlayer(
      key: const flutter.ValueKey('pp_youtube_iframe'),
      controller: _youtubeController!,
      backgroundColor: flutter.Colors.transparent,
    );
  }

  yt.YoutubePlayerController? get youtubeController => _isYoutube ? _youtubeController : null;

  // ---------------------------------------------------------------------------
  // prepare()
  // ---------------------------------------------------------------------------

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    if (_disposed) return;
    final isOnline = track.sourceType == PlaybackSourceType.online && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(track.id);
    if (!isOnline) {
      _isYoutube = false;
      return fallback.prepare(track, position: position);
    }
    _isYoutube = true;

    _attemptActive = true;
    _intentRevision++;
    _intendedState = PlaybackState.paused;
    _playGeneration++;
    final myGenYt = _playGeneration;

    final ss =
        position?.inMilliseconds != null
            ? position!.inMilliseconds / 1000.0
            : null;
    _currentStartSeconds = ss;

    _updateStatus(
      _currentStatus.copyWith(
        track: track,
        state: PlaybackState.preparing,
        isIFrameMode: true,
        hasVideo: true,
        activeVideoId: track.id,
      ),
    );

    if (_youtubeController == null) {
      await _enterIFrameMode(track, generation: myGenYt);
    }

    if (_disposed || myGenYt != _playGeneration) return;

    try {
      _diag(
        'PREPARE cueVideo/Playlist gen=$myGenYt videoId=${track.id} ss=$ss',
      );
      if (track.youtubeSourceType == YoutubeSourceType.playlist) {
        await _youtubeController!.cuePlaylist(
          list: [track.id],
          listType: yt.ListType.playlist,
          startSeconds: ss,
        );
      } else {
        await _youtubeController!.cueVideoById(
          videoId: track.id,
          startSeconds: ss,
        );
      }
    } catch (e) {
      debugPrint(
        'MediaKitPlaybackEngine: prepare cueVideo/Playlist failed: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // play()
  // ---------------------------------------------------------------------------

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    if (_disposed) return;
    final isOnline = track.sourceType == PlaybackSourceType.online && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(track.id);
    if (!isOnline) {
      _isYoutube = false;
      return fallback.play(track, startAt: startAt, play: play);
    }
    _isYoutube = true;

    _attemptActive = false;
    _intentRevision++;
    _intendedState = play ? PlaybackState.playing : PlaybackState.paused;
    _playGeneration++;
    final myGenYt = _playGeneration;

    _watchdogTimer?.cancel();
    if (_currentStatus.isIFrameMode) {
      try {
        await _youtubeController?.pauseVideo().timeout(
          const Duration(seconds: 1),
        );
      } catch (e) {
        debugPrint('MediaKitPlaybackEngine: pauseVideo failed/timed out: $e');
      }
    }

    if (_disposed || myGenYt != _playGeneration) return;
    _attemptActive = true;
    _recoveryUsed = false;
    _ready = false;
    _latePauseGeneration = null;

    _updateStatus(
      _currentStatus.copyWith(
        track: track,
        state: PlaybackState.preparing,
        clearError: true,
        activeVideoId: track.id,
        hasVideo: true,
        isIFrameMode: true,
        generation: myGenYt,
      ),
    );

    final ss =
        startAt.inMilliseconds > 0 ? startAt.inMilliseconds / 1000.0 : null;
    _currentStartSeconds = ss;
    await _enterIFrameMode(track, generation: myGenYt, startSeconds: ss);
  }

  // ---------------------------------------------------------------------------
  // YouTube helpers (unchanged logic, adapted variable names)
  // ---------------------------------------------------------------------------

  void _failAttempt(int generation, String error) {
    if (!_valid(generation)) return;
    _attemptActive = false;
    _watchdogTimer?.cancel();
    _updateStatus(
      _currentStatus.copyWith(state: PlaybackState.error, error: error),
    );
  }

  void _armWatchdog(int generation, {required bool loading}) {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(Duration(seconds: _recoveryUsed ? 10 : 20), () {
      if (!_valid(generation) || _intendedState != PlaybackState.playing)
        return;
      if (_currentStatus.state == PlaybackState.playing) return;
      if (!BackgroundPlaybackExperiment.enabled && isActivityStopped) return;
      if (_recoveryUsed) {
        _failAttempt(
          generation,
          loading
              ? 'error: YouTube loading timed out (gen=$generation)'
              : 'error: YouTube playback start timed out (gen=$generation)',
        );
        return;
      }
      _recoveryUsed = true;
      _ready = false;
      _lastPlayedGeneration = -1;
      if (!_valid(generation)) return;
      _armWatchdog(generation, loading: true);
      final recoveryStart =
          (_confirmedPositionGeneration == generation &&
                  _confirmedPlaybackPosition != null)
              ? _confirmedPlaybackPosition!.inMilliseconds / 1000.0
              : _currentStartSeconds;
      unawaited(
        _load(
          generation,
          _currentStatus.track!,
          startSeconds: recoveryStart,
        ),
      );
    });
  }

  Future<void> _enterIFrameMode(
    PlaybackTrack track, {
    required int generation,
    double? startSeconds,
  }) async {
    if (_youtubeController == null) {
      debugPrint(
        'MediaKitPlaybackEngine: [INIT] Creating YoutubePlayerController (persistent singleton)',
      );

      _youtubeController = yt.YoutubePlayerController(
        params: const yt.YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          loop: false,
          strictRelatedVideos: true,
          origin: 'https://ppplayer.com',
          pointerEvents: yt.PointerEvents.none,
        ),
      );

      // ignore: invalid_use_of_internal_member
      _youtubeController!.webViewController.addJavaScriptChannel(
        'NativeLog',
        onMessageReceived: (msg) {
          debugPrint('MediaKitPlaybackEngine: [NativeLog] ${msg.message}');
        },
      );

      // Persistent generation-aware listener. This is the ONLY place that
      // calls playVideo() in response to a 'cued' state.
      _iframeSubscriptions.add(
        _youtubeController!.listen((ytState) {
          if (!_currentStatus.isIFrameMode || !_valid(_playGeneration)) return;
          final eventId = ytState.metaData.videoId;
          if (eventId.isNotEmpty && eventId != _currentStatus.track?.id) return;

          final gen = _playGeneration;
          if (_isIOS && ytState.playerState != yt.PlayerState.paused) {
            _cancelIOSPauseRecovery();
          }
          _diag(
            'BRIDGE gen=$gen iframeState=${ytState.playerState} '
            'engineState=${_currentStatus.state} intended=$_intendedState '
            'activityStopped=$isActivityStopped',
          );

          if (ytState.hasError && ytState.error != yt.YoutubeError.none) {
            debugPrint(
              'MediaKitPlaybackEngine: [ERROR] YouTube IFrame error: ${ytState.error}',
            );
            final eventVideoId = ytState.metaData.videoId;
            final currentVideoId = _currentStatus.track?.id;
            if (eventVideoId.isNotEmpty &&
                currentVideoId != null &&
                eventVideoId != currentVideoId) {
              debugPrint(
                'MediaKitPlaybackEngine: [BRIDGE] Ignoring stale error for $eventVideoId (current: $currentVideoId).',
              );
              return;
            }
            if (ytState.error == yt.YoutubeError.videoNotFound ||
                ytState.error == yt.YoutubeError.notEmbeddable ||
                ytState.error == yt.YoutubeError.cannotFindVideo ||
                ytState.error == yt.YoutubeError.sameAsNotEmbeddable ||
                ytState.error == yt.YoutubeError.invalidParam) {
              _failAttempt(gen, 'unavailable_media:${ytState.error.name}');
              return;
            }
            // Transient errors are ignored.
          }

          switch (ytState.playerState) {
            case yt.PlayerState.cued:
            case yt.PlayerState.unStarted:
              _ready = true;
              // Repeated readiness events must not restart the start deadline.
              if (_lastPlayedGeneration != gen) {
                if (_intendedState == PlaybackState.paused) {
                  // prepare() path: resolve to paused with saved position.
                  final savedPos =
                      _currentStartSeconds != null
                          ? Duration(
                            milliseconds:
                                (_currentStartSeconds! * 1000).toInt(),
                          )
                          : Duration.zero;
                  _updateStatus(
                    _currentStatus.copyWith(
                      state: PlaybackState.paused,
                      position: savedPos,
                      activeVideoId: _currentStatus.track?.id,
                    ),
                  );
                } else {
                  unawaited(_dispatchIFramePlay(gen, ytState.playerState.name));
                }
              }
              break;
            default:
              break;
          }

          final newState = switch (ytState.playerState) {
            yt.PlayerState.playing => PlaybackState.playing,
            yt.PlayerState.paused => PlaybackState.paused,
            yt.PlayerState.unStarted => PlaybackState.paused,
            yt.PlayerState.buffering => PlaybackState.buffering,
            yt.PlayerState.ended => PlaybackState.ended,
            // A cued video is ready-but-paused.
            yt.PlayerState.cued => PlaybackState.paused,
            _ => _currentStatus.state,
          };

          if (newState == PlaybackState.ended) {
            final eventVideoId = ytState.metaData.videoId;
            final currentVideoId = _currentStatus.track?.id;
            if (eventVideoId.isNotEmpty &&
                currentVideoId != null &&
                eventVideoId != currentVideoId) {
              debugPrint(
                'MediaKitPlaybackEngine: [BRIDGE] Ignoring stale ended event for $eventVideoId (current: $currentVideoId).',
              );
              return;
            }
            _eventController.add(
              PlaybackEvent(
                type: PlaybackEventType.trackEnded,
                track: _currentStatus.track,
                generation: gen,
              ),
            );
          }

          if ((newState == PlaybackState.playing ||
                  newState == PlaybackState.buffering) &&
              _intendedState == PlaybackState.paused) {
            if (!BackgroundPlaybackExperiment.enabled) {
              _diag(
                'BRIDGE SPURIOUS-PLAY: intendedState=paused. [BASELINE] forcing pauseVideo().',
              );
              unawaited(
                _youtubeController?.pauseVideo().catchError((Object error) {
                  _diag('Corrective pause failed: $error');
                }),
              );
              return;
            } else {
              _diag(
                'BRIDGE SPURIOUS-PLAY: intendedState=paused. [EXPERIMENT] OBSERVE ONLY.',
              );
            }
          }

          if (ytState.playerState == yt.PlayerState.paused &&
              _intendedState == PlaybackState.paused) {
            _latePauseGeneration = null;
          }
          var finalNewState = newState;
          if (newState == PlaybackState.paused &&
              _intendedState == PlaybackState.playing) {
            if (ytState.playerState == yt.PlayerState.paused &&
                _latePauseGeneration == gen) {
              _latePauseGeneration = null;
              unawaited(_dispatchIFramePlay(gen, 'late-pause'));
            } else if (ytState.playerState == yt.PlayerState.paused) {
              if (_isIOS) {
                // Keep the last observed state while checking for a stale
                // callback. A recovery command is not a playing acknowledgement.
                finalNewState = _currentStatus.state;
                unawaited(_recoverIOSIFramePause(gen));
              } else if (_pauseIntentGeneration != gen) {
                // Preserve background-suspension recovery until this playback
                // attempt receives an explicit pause intent.
                finalNewState = PlaybackState.playing;
                unawaited(_dispatchIFramePlay(gen, 'spurious-pause'));
              } else {
                // A pending pause superseded by resume gets one correction
                // above. Other renderer pauses may come from media controls
                // or audio focus; accept them rather than restarting playback.
                _watchdogTimer?.cancel();
                _intendedState = PlaybackState.paused;
              }
            }
            if (ytState.playerState == yt.PlayerState.unStarted) return;
          }
          if (newState == PlaybackState.playing) {
            _watchdogTimer?.cancel();
            _confirmedPositionGeneration = gen;
          }

          if (finalNewState != _currentStatus.state) {
            _updateStatus(_currentStatus.copyWith(state: finalNewState));
          }
        }),
      );
    }

    if (generation != _playGeneration) {
      debugPrint(
        'MediaKitPlaybackEngine: Stale enterIFrameMode (gen: $generation). Aborting.',
      );
      return;
    }

    _updateStatus(_currentStatus);
    _armWatchdog(generation, loading: true);
    await _load(generation, track, startSeconds: startSeconds);
  }

  Future<void> _load(
    int generation,
    PlaybackTrack track, {
    double? startSeconds,
  }) async {
    if (!_valid(generation)) return;
    bool eligible() =>
        _valid(generation) &&
        (BackgroundPlaybackExperiment.enabled || !isActivityStopped);
    try {
      if (!eligible()) {
        if (_intendedState != PlaybackState.paused) {
          _diag('ENGINE _load() BLOCKED: not eligible to play.');
          _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
        } else {
          _diag(
            'ENGINE _load() BLOCKED (prepare path): skipping spurious paused emit.',
          );
        }
        return;
      }
      if (_intendedState == PlaybackState.paused) {
        if (track.youtubeSourceType == YoutubeSourceType.playlist) {
          await _youtubeController!.cuePlaylist(
            list: [track.id],
            listType: yt.ListType.playlist,
            startSeconds: startSeconds,
          );
        } else {
          await _youtubeController!.cueVideoById(
            videoId: track.id,
            startSeconds: startSeconds,
          );
        }
      } else {
        if (track.youtubeSourceType == YoutubeSourceType.playlist) {
          await _youtubeController!.loadPlaylist(
            list: [track.id],
            listType: yt.ListType.playlist,
            startSeconds: startSeconds,
          );
        } else {
          await _youtubeController!.loadVideoById(
            videoId: track.id,
            startSeconds: startSeconds,
          );
        }
      }
    } catch (error) {
      _failAttempt(generation, 'YouTube loading failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // pause / resume / stop / seekTo / setVolume / setSpeed / setSubtitleTrack
  // ---------------------------------------------------------------------------

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    if (!_isYoutube) return fallback.pause(caller: caller, failOnTimeout: failOnTimeout);
    if ((_currentStatus.state == PlaybackState.paused ||
            _currentStatus.state == PlaybackState.idle) &&
        _intendedState != PlaybackState.playing) {
      return;
    }

    _diag(
      'ENGINE pause() caller=$caller failOnTimeout=$failOnTimeout '
      'intendedWas=$_intendedState gen=$_playGeneration',
    );
    _intentRevision++;
    _cancelIOSPauseRecovery();
    _watchdogTimer?.cancel();
    _intendedState = PlaybackState.paused;
    _pauseIntentGeneration = _playGeneration;

    final pauseAck = statusStream
        .firstWhere(
          (s) =>
              s.state == PlaybackState.paused || s.state == PlaybackState.idle,
        )
        .timeout(const Duration(seconds: 2));

    if (!failOnTimeout) {
      // Optimistically update the state so the UI and OS MediaSession reflect
      // the paused state immediately, rather than waiting for the JS bridge
      // (which may be suspended by the OS and never fire the event).
      _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
    }

    if (_currentStatus.isIFrameMode) {
      _latePauseGeneration = _playGeneration;
      try {
        await _youtubeController?.pauseVideo().timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint('MediaKitPlaybackEngine: pauseVideo failed/timed out: $e');
        if (failOnTimeout) {
          throw TimeoutException(
            'Source pause failed (IFrame error)',
            const Duration(seconds: 2),
          );
        }
        if (_intendedState == PlaybackState.paused) {
          _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
        }
        return;
      }
    }

    try {
      await pauseAck;
    } catch (e) {
      // TimeoutException: ack didn't arrive within 2 s.
      // StateError ("No element"): engine disposed while pause was pending.
      debugPrint(
        'MediaKit: pause ack timeout/close (caller=$caller, failOnTimeout=$failOnTimeout): $e',
      );
      if (failOnTimeout && e is TimeoutException) {
        throw TimeoutException(
          'Source pause unconfirmed by IFrame',
          const Duration(seconds: 2),
        );
      }
      _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
    }
  }

  Future<void> _recoverIOSIFramePause(int generation) async {
    final revision = _intentRevision;
    final episode = (generation, revision);
    if (_iosPauseRecoveryEpisode == episode) return;
    _iosPauseRecoveryEpisode = episode;
    final token = Object();
    _iosPauseRecoveryToken = token;

    bool eligibleWithoutToken() =>
        _valid(generation) &&
        revision == _intentRevision &&
        _intendedState == PlaybackState.playing;
    bool eligible() =>
        identical(_iosPauseRecoveryToken, token) && eligibleWithoutToken();

    try {
      final liveState = await _youtubeController!.playerState.timeout(
        const Duration(milliseconds: 400),
      );
      if (!eligible()) return;
      if (liveState != yt.PlayerState.paused) {
        _iosPauseRecoveryEpisode = null;
        _diag(
          'IOS PAUSE-RECOVERY skipped: liveState=$liveState gen=$generation',
        );
        return;
      }
      _diag('IOS PAUSE-RECOVERY confirmed paused gen=$generation');
      _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
      await _dispatchIFramePlay(
        generation,
        'ios-confirmed-pause',
        restoreVolume: false,
        recoveryIsCurrent: eligible,
      );
    } catch (error) {
      if (eligible()) {
        // A failed state query gives no reason to poke an already-playing
        // player. Allow a later pause update to retry the check.
        _iosPauseRecoveryEpisode = null;
        _diag('IOS PAUSE-RECOVERY state check failed: $error');
      }
    } finally {
      if (identical(_iosPauseRecoveryToken, token)) {
        _iosPauseRecoveryToken = null;
        if (_iosPauseRecoveryEpisode == episode && eligibleWithoutToken()) {
          _iosPauseRecoveryCooldown?.cancel();
          _iosPauseRecoveryCooldown = Timer(const Duration(seconds: 1), () {
            if (_iosPauseRecoveryEpisode == episode) {
              _iosPauseRecoveryEpisode = null;
            }
            _iosPauseRecoveryCooldown = null;
          });
        }
      }
    }
  }

  Future<void> _dispatchIFramePlay(
    int expectedGeneration,
    String source, {
    bool restoreVolume = true,
    bool Function()? recoveryIsCurrent,
  }) async {
    bool eligible() =>
        _valid(expectedGeneration) &&
        _intendedState == PlaybackState.playing &&
        (recoveryIsCurrent?.call() ?? true) &&
        (BackgroundPlaybackExperiment.enabled || !isActivityStopped);
    if (!eligible()) {
      if (_valid(expectedGeneration) && isActivityStopped) {
        _watchdogTimer?.cancel();
        _intendedState = PlaybackState.paused;
        _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
      }
      return;
    }
    final revision = _intentRevision;
    _lastPlayedGeneration = expectedGeneration;
    try {
      if (restoreVolume) {
        await _youtubeController!.setVolume(
          (_currentStatus.volume * 100).toInt(),
        );
      }
      if (!eligible() || revision != _intentRevision) return;
      _diag('DISPATCH playVideo gen=$expectedGeneration source=$source');
      final command = _youtubeController!.playVideo();
      _armWatchdog(expectedGeneration, loading: false);
      await command;
    } catch (error) {
      if (eligible() && revision == _intentRevision) {
        _failAttempt(
          expectedGeneration,
          'YouTube playback dispatch failed: $error',
        );
      }
    }
  }

  @override
  Future<void> resume() async {
    if (!_isYoutube) return fallback.resume();
    _intentRevision++;
    _cancelIOSPauseRecovery();
    _diag(
      'ENGINE resume() iframeMode=${_currentStatus.isIFrameMode} '
      'activityStopped=$isActivityStopped gen=$_playGeneration',
    );

    // Activity-stopped guard (baseline only).
    if (!BackgroundPlaybackExperiment.enabled &&
        _currentStatus.isIFrameMode &&
        isActivityStopped) {
      _diag(
        'ENGINE resume() BLOCKED [BASELINE guard]: activity stopped. '
        'Setting intendedState=paused, emitting paused.',
      );
      _intendedState = PlaybackState.paused;
      _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
      return;
    }

    if (BackgroundPlaybackExperiment.enabled &&
        _currentStatus.isIFrameMode &&
        isActivityStopped) {
      _diag(
        'ENGINE resume() PASS-THROUGH [EXPERIMENT]: activity stopped but guard disabled.',
      );
    }

    _intendedState = PlaybackState.playing;
    if (_currentStatus.isIFrameMode) {
      if (_ready) {
        // Ensure _attemptActive is set so _valid() passes inside
        // _dispatchIFramePlay. prepare() already sets it to true, but
        // an intermediate pause() call can clear it; reassert here.
        _attemptActive = true;
        await _dispatchIFramePlay(_playGeneration, 'resume');
      } else if (_valid(_playGeneration)) {
        _armWatchdog(_playGeneration, loading: true);
        await _load(
          _playGeneration,
          _currentStatus.track!,
          startSeconds: _currentStartSeconds,
        );
      }
    }
  }

  @override
  Future<void> stop() async {
    if (!_isYoutube) return fallback.stop();
    _playGeneration++;
    _intentRevision++;
    _cancelIOSPauseRecovery();
    _attemptActive = false;
    _latePauseGeneration = null;
    _watchdogTimer?.cancel();
    _stopIFramePolling();
    _intendedState = PlaybackState.paused;

    // Optimistically update before awaiting so the UI reflects idle immediately.
    _updateStatus(
      _currentStatus.copyWith(
        state: PlaybackState.idle,
        track: null,
        activeVideoId: null,
      ),
    );

    if (_currentStatus.isIFrameMode) {
      try {
        await _youtubeController?.pauseVideo().timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint(
          'MediaKitPlaybackEngine: stop() pauseVideo threw/timed out: $e',
        );
      }
      // Keep IFrame controller alive to avoid recreating the platform view.
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (!_isYoutube) return fallback.seekTo(position);
    if (!_currentStatus.isSeekable) {
      debugPrint(
        'MediaKitPlaybackEngine: Blocked seek attempt to $position '
        '(isSeekable=false). Network capability is unknown or stream is live.',
      );
      return;
    }

    final generation = _playGeneration;
    final revision = _intentRevision;
    final wasPlaying = _currentStatus.state == PlaybackState.playing;

    if (_currentStatus.isIFrameMode) {
      if (!_valid(generation)) return;
      if (!_ready) {
        // If not ready, we must load to prepare the offset.
        await _load(
          generation,
          _currentStatus.track!,
          startSeconds: position.inMilliseconds / 1000,
        );
      } else {
        await _youtubeController?.seekTo(
          seconds: position.inMilliseconds / 1000.0,
          allowSeekAhead: true,
        );
        // Seeking a paused video can start it implicitly; enforce intent.
        if (_intendedState != PlaybackState.playing) {
          unawaited(_youtubeController?.pauseVideo());
        }
      }
      if (_valid(generation)) {
        _currentStartSeconds = position.inMilliseconds / 1000.0;
        _updateStatus(_currentStatus.copyWith(position: position));
      }
      if (wasPlaying && revision == _intentRevision) {
        await _dispatchIFramePlay(generation, 'seek');
      }
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    if (!_isYoutube) return fallback.setVolume(volume);
    if (_currentStatus.isIFrameMode) {
      await _youtubeController?.setVolume((volume * 100).toInt());
    }
    _updateStatus(_currentStatus.copyWith(volume: volume));
  }

  @override
  bool get supportsSpeed => true;

  /// True only when MediaKit is rendering the video surface (not YouTube iframe).
  @override
  bool get supportsVideoFitMode =>
      _currentStatus.hasVideo && !_currentStatus.isIFrameMode;

  @override
  Future<void> setSpeed(double speed) async {
    if (!_isYoutube) return fallback.setSpeed(speed);
    if (_currentStatus.isIFrameMode) {
      await _youtubeController?.setPlaybackRate(speed);
    }
  }

  @override
  Future<void> setSubtitleTrack(String? uri) async {
    if (!_isYoutube) return fallback.setSubtitleTrack(uri);
  }

  @override
  bool get supportsTrackSelection =>
      fallback.supportsTrackSelection;

  @override
  bool get supportsExternalSubtitles =>
      fallback.supportsExternalSubtitles;

  @override
  bool get supportsSubtitleDelay =>
      fallback.supportsSubtitleDelay;

  @override
  bool get supportsSubtitleTextSize =>
      fallback.supportsSubtitleTextSize;

  @override
  bool get supportsSubtitleBackgroundStyling =>
      fallback.supportsSubtitleBackgroundStyling;

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    if (!_isYoutube) return fallback.setSubtitleDelay(delay);
  }

  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {
    if (!_isYoutube) return fallback.setSubtitleAppearance(textSize: textSize, backgroundColor: backgroundColor);
  }
  // ---------------------------------------------------------------------------
  // Status update + IFrame position polling
  // ---------------------------------------------------------------------------

  void _updateStatus(PlaybackStatus status) {
    if (_disposed) return;
    if (status.state != _currentStatus.state) {
      _diag(
        'STATE ${_currentStatus.state} → ${status.state} '
        'gen=$_playGeneration intended=$_intendedState '
        'activityStopped=$isActivityStopped',
      );
    }
    _currentStatus = status.copyWith(generation: _playGeneration);
    _statusController.add(_currentStatus);

    // Manage IFrame position polling.
    if (status.isIFrameMode && status.state == PlaybackState.playing) {
      if (_iframePositionTimer == null) {
        _startIFramePolling();
      }
    } else if (status.state != PlaybackState.playing) {
      _stopIFramePolling();
    }
  }

  // Tracks consecutive ticks where getCurrentTime returned the same frozen
  // value. A position that hasn't advanced for ~2 seconds while >= duration is
  // treated as a synthetic end-of-track signal.
  double _lastPolledPosition = -1;
  int _frozenPositionTicks = 0;
  static const int _frozenTicksThreshold = 4; // 4 × 500 ms = 2 s

  void _startIFramePolling() {
    final generation = _playGeneration;
    _lastPolledPosition = -1;
    _frozenPositionTicks = 0;
    _iframePositionTimer?.cancel();
    final serialize = _isIOS;
    var pollInFlight = false;
    if (serialize) {
      _diag('IOS position polling: serialized, using cached metadata duration');
    }
    _iframePositionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (_youtubeController == null || !_currentStatus.isIFrameMode) {
        timer.cancel();
        return;
      }
      if (serialize && pollInFlight) return;
      pollInFlight = true;

      double currentTime;
      double duration;
      try {
        // Each JS bridge call is individually guarded so a single hung call
        // does not block the timer indefinitely.
        currentTime = await _youtubeController!.currentTime.timeout(
          const Duration(milliseconds: 400),
        );
        final metadata = _youtubeController!.value.metaData;
        if (serialize &&
            _currentStatus.track?.liveStatus == PlaybackLiveStatus.onDemand &&
            metadata.videoId == _currentStatus.track?.id &&
            metadata.duration > Duration.zero) {
          duration = metadata.duration.inMilliseconds / 1000.0;
        } else {
          duration = await _youtubeController!.duration.timeout(
            const Duration(milliseconds: 400),
          );
        }
      } catch (e) {
        return;
      } finally {
        pollInFlight = false;
      }
      if (serialize && !_valid(generation)) return;

      // Synthetic end-of-track detection (for macOS App Nap).
      if (duration > 0 &&
          currentTime >= duration - 0.5 &&
          _intendedState == PlaybackState.playing) {
        final positionFrozen = (currentTime - _lastPolledPosition).abs() < 0.01;
        if (positionFrozen) {
          _frozenPositionTicks++;
        } else {
          _frozenPositionTicks = 0;
        }
        _lastPolledPosition = currentTime;

        if (_frozenPositionTicks >= _frozenTicksThreshold) {
          _diag(
            'RENDERER gen=$generation synthetic end-of-track: '
            'pos=$currentTime dur=$duration frozen=$_frozenPositionTicks ticks',
          );
          timer.cancel();
          _iframePositionTimer = null;
          if (!_disposed) {
            _eventController.add(
              PlaybackEvent(
                type: PlaybackEventType.trackEnded,
                track: _currentStatus.track,
                generation: _playGeneration,
              ),
            );
          }
          _updateStatus(_currentStatus.copyWith(state: PlaybackState.ended));
          return;
        }
      } else {
        _frozenPositionTicks = 0;
        _lastPolledPosition = currentTime;
      }

      if (!_valid(generation)) return;

      if (_currentStatus.state == PlaybackState.playing) {
        _diag(
          'RENDERER gen=$generation position=$currentTime duration=$duration',
        );
        final positionDuration = Duration(
          milliseconds: (currentTime * 1000).toInt(),
        );
        // Update confirmed position for watchdog recovery.
        if (_confirmedPositionGeneration == generation) {
          _confirmedPlaybackPosition = positionDuration;
        }
        _updateStatus(
          _currentStatus.copyWith(
            position: positionDuration,
            duration: Duration(milliseconds: (duration * 1000).toInt()),
          ),
        );
      }
    });
  }

  void _stopIFramePolling() {
    _iframePositionTimer?.cancel();
    _iframePositionTimer = null;
  }

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cancelIOSPauseRecovery();
    _attemptActive = false;
    _playGeneration++;
    _watchdogTimer?.cancel();
    _iframePositionTimer?.cancel();

    // Detach and cancel the active session's subscriptions synchronously;
    // adapter disposal is awaited to ensure native resources are freed.
    // Subscriptions must be cancelled BEFORE the native object is freed to
    // prevent a callback firing into a freed object (SIGABRT in libmpv).
    for (final sub in _iframeSubscriptions) {
      sub.cancel();
    }
    _iframeSubscriptions.clear();

    _youtubeController?.close();
    _statusController.close();
    _eventController.close();
  }
}
