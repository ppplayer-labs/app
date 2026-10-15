import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';

/// Opt-in YouTube path; delegates other sources to [fallback].
class ChromiumPlaybackEngine implements PlaybackController {
  ChromiumPlaybackEngine({
    required this.fallback,
    required this.initializeCef,
    required this.createPlayer,
    this.startPlaybackService,
    this.stopPlaybackService,
    this.showBrowser = true,
    this.youtubeEnabled = true,
  }) {
    _subscriptions.add(
      fallback.statusStream.listen((status) {
        if (!_closed && !_chromium) _publish(status);
      }),
    );
    _subscriptions.add(
      fallback.eventStream.listen((event) {
        if (!_closed && !_chromium) _events.add(event);
      }),
    );
  }

  final PlaybackController fallback;
  final Future<void> Function() initializeCef;
  final ChromiumYoutubePlayerController Function() createPlayer;
  final Future<void> Function()? startPlaybackService;
  final Future<void> Function()? stopPlaybackService;
  final bool showBrowser;
  final bool youtubeEnabled;
  final _statuses = StreamController<PlaybackStatus>.broadcast();
  final _events = StreamController<PlaybackEvent>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  StreamSubscription<Map<String, Object?>>? _playerSubscription;
  ChromiumYoutubePlayerController? _player;
  Future<void>? _opening;
  Future<void>? _cef;
  Future<void>? _disposing;
  PlaybackStatus _status = const PlaybackStatus();
  bool _chromium = false;
  bool _closed = false;
  bool _wantsPlaying = false;
  bool _started = false;
  bool _ended = false;
  bool _correctingPause = false;
  int _generation = 0;
  Object? _durationRequest;
  DateTime? _durationAttempt;

  @override
  Stream<PlaybackStatus> get statusStream => _statuses.stream;
  @override
  Stream<PlaybackEvent> get eventStream => _events.stream;
  @override
  PlaybackStatus get currentStatus => _status;
  bool _valid(int generation) => !_closed && generation == _generation;
  void _checkOpen() {
    if (_closed) throw StateError('Chromium playback engine is disposed');
  }

  void _publish(PlaybackStatus status) {
    if (_closed) return;
    _status = status;
    _statuses.add(status);
  }

  void _event(PlaybackEventType type, {String? message}) {
    if (!_closed)
      _events.add(
        PlaybackEvent(
          type: type,
          track: _status.track,
          position: _status.position,
          generation: _generation,
          message: message,
        ),
      );
  }

  void _fail(Object error, int generation) {
    if (!_valid(generation)) return;
    _publish(
      _status.copyWith(state: PlaybackState.error, error: error.toString()),
    );
    _event(PlaybackEventType.playbackError, message: error.toString());
  }

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) {
    _checkOpen();
    if (startAt.isNegative) throw ArgumentError.value(startAt, 'startAt');
    final online = track.sourceType == PlaybackSourceType.online;
    if (online && !youtubeEnabled) {
      return _rejectYoutube(track, startAt);
    }
    final generation = ++_generation;
    _durationRequest = null;
    _durationAttempt = null;
    _chromium = online;
    _wantsPlaying = play;
    _started = false;
    _ended = false;
    _publish(
      PlaybackStatus(
        track: track,
        state: PlaybackState.preparing,
        position: startAt,
        duration: track.duration ?? Duration.zero,
        volume: _status.volume,
        isIFrameMode: online,
        activeVideoId: online ? track.id : null,
        hasVideo: online ? showBrowser : track.isVideo,
        generation: generation,
        supportsSpeed: online ? false : fallback.supportsSpeed,
        isLive: track.liveStatus == PlaybackLiveStatus.live,
        isSeekable: track.liveStatus != PlaybackLiveStatus.live,
      ),
    );
    // Serialize native/browser replacement. A superseded initialization must
    // finish before its successor creates another browser or native session.
    final previousOpening = _opening;
    return _opening = () async {
      try {
        await previousOpening;
      } catch (_) {
        // A failed older generation does not prevent an explicit new request.
      }
      if (!_valid(generation)) return;
      await _open(track, startAt, online, generation);
    }();
  }

  Future<void> _rejectYoutube(PlaybackTrack track, Duration position) async {
    final generation = _generation + 1;
    await stop();
    if (!_valid(generation)) return;
    const message =
        'YouTube requires an enabled YouTube engine; MediaKit cannot play online IDs';
    _publish(
      _status.copyWith(
        track: track,
        position: position,
        state: PlaybackState.error,
        error: message,
      ),
    );
    _event(PlaybackEventType.playbackError, message: message);
    throw UnsupportedError(message);
  }

  Future<void> _open(
    PlaybackTrack track,
    Duration start,
    bool online,
    int generation,
  ) async {
    try {
      final previous = _player;
      _player = null;
      final subscription = _playerSubscription;
      _playerSubscription = null;
      await subscription?.cancel();
      await previous?.dispose();
      if (!_valid(generation)) return;
      if (!online) {
        await stopPlaybackService?.call();
        await fallback.setVolume(_status.volume);
        if (!_valid(generation)) return;
        await fallback.play(track, startAt: start, play: _wantsPlaying);
        return;
      }
      await fallback.stop();
      if (!_valid(generation)) return;
      if (_wantsPlaying) await startPlaybackService?.call();
      if (!_valid(generation)) return;
      int retries = 0;
      ChromiumYoutubePlayerController? player;
      while (true) {
        try {
          try {
            await (_cef ??= initializeCef());
          } catch (e) {
            _cef = null;
            rethrow;
          }
          if (!_valid(generation)) return;
          player = _player = createPlayer();
          _playerSubscription = player.events.listen(
            (event) => _receive(event, generation, player!),
          );
          await player.initialize();
          if (!_valid(generation)) return;
          await player.setVolume((_status.volume * 100).round());
          if (!_valid(generation)) return;
          final seconds = start.inMicroseconds / Duration.microsecondsPerSecond;
          if (_wantsPlaying) {
            if (track.youtubeSourceType == YoutubeSourceType.playlist) {
              await player.loadPlaylist(
                playlistId: track.id,
                startSeconds: seconds,
              );
            } else {
              await player.loadVideoById(
                videoId: track.id,
                startSeconds: seconds,
              );
            }
          } else {
            if (track.youtubeSourceType == YoutubeSourceType.playlist) {
              await player.cuePlaylist(
                playlistId: track.id,
                startSeconds: seconds,
              );
            } else {
              await player.cueVideoById(
                videoId: track.id,
                startSeconds: seconds,
              );
            }
          }
          if (_valid(generation)) {
            if (!_wantsPlaying) await player.pauseVideo();
            await _readDuration(player, generation);
          }
          break;
        } catch (e) {
          final isCrash = e is StateError && e.message == 'Browser crashed';
          final isPlatformFail =
              e is PlatformException &&
              const {
                'INIT_FAILED',
                'HOST_FAILED',
                'INIT_TIMEOUT',
                'NOT_READY',
              }.contains(e.code);
          if ((isCrash || isPlatformFail) && retries < 10) {
            _cef = null;
            retries++;
            await _playerSubscription?.cancel();
            _playerSubscription = null;
            await player?.dispose();
            _player = null;
            await Future.delayed(const Duration(milliseconds: 500));
            if (!_valid(generation)) return;
            continue;
          }
          _cef = null;
          rethrow;
        }
      }
    } catch (error) {
      if (!_valid(generation)) return;
      final failedPlayer = _player;
      _player = null;
      await _playerSubscription?.cancel();
      _playerSubscription = null;
      await failedPlayer?.dispose();
      await stopPlaybackService?.call();
      if (!_valid(generation)) return;
      // Report the original track/position without replaying through MediaKit.
      _fail(error, generation);
      rethrow;
    }
  }

  static Duration _seconds(num seconds) => Duration(
    microseconds: (seconds.toDouble() * Duration.microsecondsPerSecond).round(),
  );

  Future<void> _readDuration(
    ChromiumYoutubePlayerController player,
    int generation,
  ) async {
    if (_durationRequest != null || !_valid(generation)) return;
    if (_durationAttempt != null &&
        DateTime.now().difference(_durationAttempt!) <
            const Duration(seconds: 1))
      return;
    _durationAttempt = DateTime.now();
    final token = _durationRequest = Object();
    try {
      final duration = await player.duration;
      if (_valid(generation) &&
          identical(player, _player) &&
          duration > 0 &&
          duration.isFinite) {
        _publish(_status.copyWith(duration: _seconds(duration)));
      }
    } on StateError {
      // YouTube can return an undefined duration until video metadata arrives.
      // Progress events retry it without failing a successfully started track.
    } catch (error) {
      _fail(error, generation);
    } finally {
      if (identical(token, _durationRequest)) _durationRequest = null;
    }
  }

  void _receive(
    Map<String, Object?> event,
    int generation,
    ChromiumYoutubePlayerController player,
  ) {
    if (!_valid(generation) || !identical(player, _player)) return;
    if (event['BrowserCrashed'] == true) {
      final subscription = _playerSubscription;
      _playerSubscription = null;
      _player = null;
      // Serialize cleanup before a user or PlayerNotifier recovery opens a new
      // browser. Stale events from the dead browser must no longer be accepted.
      _opening = () async {
        await subscription?.cancel();
        await player.dispose();
        await stopPlaybackService?.call();
      }();
      unawaited(
        _opening!.catchError((Object error) {
          if (!_closed) _fail(error, _generation);
        }),
      );
      _fail(
        StateError('Browser crashed; retry through the playback coordinator'),
        generation,
      );
      ++_generation;
      return;
    }
    if (event['PlayerError'] != null || event['AutoplayBlocked'] == true) {
      _fail(
        StateError(
          event['AutoplayBlocked'] == true
              ? 'YouTube autoplay blocked'
              : 'YouTube error ${event['PlayerError']}',
        ),
        generation,
      );
      return;
    }
    final state = event['StateChange'];
    if (state is int) {
      final mapped = switch (state) {
        -1 => PlaybackState.preparing,
        0 => PlaybackState.ended,
        1 => PlaybackState.playing,
        2 => PlaybackState.paused,
        3 => PlaybackState.buffering,
        5 => PlaybackState.ready,
        _ => null,
      };
      if (mapped != null) {
        if (state == 0 &&
            _status.track?.youtubeSourceType == YoutubeSourceType.playlist) {
          unawaited(() async {
            try {
              final index = await player.getPlaylistIndex();
              final playlist = await player.getPlaylist();
              if (!_valid(generation) || !identical(player, _player)) return;
              if (index == playlist.length - 1) {
                _publish(
                  _status.copyWith(
                    state: PlaybackState.ended,
                    clearError: true,
                  ),
                );
                if (_started && !_ended) {
                  _ended = true;
                  _releaseService(generation);
                  _event(PlaybackEventType.trackEnded);
                }
              }
            } catch (_) {}
          }());
          return;
        }
        if (state == 1 && !_wantsPlaying) {
          if (!_correctingPause) {
            _correctingPause = true;
            unawaited(
              player
                  .pauseVideo()
                  .catchError((Object error) {
                    _fail(error, generation);
                  })
                  .whenComplete(() => _correctingPause = false),
            );
          }
          return;
        }
        final previous = _status.state;
        _publish(_status.copyWith(state: mapped, clearError: state == 1));
        if (state == 1 && !_started) {
          _started = true;
          _event(PlaybackEventType.trackStarted);
        } else if (state == 1 && previous != mapped) {
          _event(PlaybackEventType.playbackResumed);
        } else if (state == 2 && previous != mapped) {
          _event(PlaybackEventType.playbackPaused);
        } else if (state == 0 && _started && !_ended) {
          _ended = true;
          _releaseService(generation);
          _event(PlaybackEventType.trackEnded);
        }
        if (state == 3 && previous != mapped)
          _event(PlaybackEventType.bufferingStarted);
        if (previous == PlaybackState.buffering && state != 3)
          _event(PlaybackEventType.bufferingEnded);
      }
    }
    if (event['VideoState'] is String) {
      if (_status.duration == Duration.zero)
        unawaited(_readDuration(player, generation));
      final progress = jsonDecode(event['VideoState'] as String);
      if (progress is Map && progress['currentTime'] is num) {
        final time = progress['currentTime'] as num;
        final fraction = progress['loadedFraction'];
        if (time.isFinite && time >= 0)
          _publish(
            _status.copyWith(
              position: _seconds(time),
              buffered: fraction is num && fraction.isFinite
                  ? Duration(
                      microseconds:
                          (_status.duration.inMicroseconds *
                                  fraction.clamp(0, 1))
                              .round(),
                    )
                  : null,
            ),
          );
      }
    }
  }

  void _releaseService(int generation) {
    unawaited(
      (stopPlaybackService?.call() ?? Future<void>.value()).catchError((
        Object error,
      ) {
        _fail(error, generation);
      }),
    );
  }

  Future<ChromiumYoutubePlayerController?> _active() async {
    final generation = _generation;
    await _opening;
    _checkOpen();
    return _valid(generation) && _chromium ? _player : null;
  }

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    _checkOpen();
    _wantsPlaying = false;
    if (!_chromium)
      return fallback.pause(caller: caller, failOnTimeout: failOnTimeout);
    final player = await _active();
    if (player == null) return;
    final needsAcknowledgment =
        failOnTimeout &&
        (_status.state == PlaybackState.playing ||
            _status.state == PlaybackState.buffering);
    final acknowledgment = needsAcknowledgment
        ? statusStream
              .firstWhere(
                (status) =>
                    status.state == PlaybackState.paused ||
                    status.state == PlaybackState.idle,
              )
              .timeout(const Duration(seconds: 2))
        : null;
    if (acknowledgment != null)
      unawaited(
        acknowledgment.catchError((Object _) => const PlaybackStatus()),
      );
    await player.pauseVideo();
    await acknowledgment;
    // Paused playback does not require a second service to remain foreground.
    if (!_wantsPlaying) await stopPlaybackService?.call();
  }

  @override
  Future<void> resume() async {
    _checkOpen();
    _wantsPlaying = true;
    if (!_chromium) return fallback.resume();
    final generation = _generation;
    final player = await _active();
    if (!_valid(generation) || !_wantsPlaying) return;
    if (player == null) {
      final track = _status.track;
      if (track != null) await play(track, startAt: _status.position);
      return;
    }
    await startPlaybackService?.call();
    if (!_valid(generation) || !_wantsPlaying) return;
    await player.playVideo();
  }

  @override
  Future<void> stop() async {
    _checkOpen();
    final generation = ++_generation;
    _wantsPlaying = false;
    final player = _player;
    _player = null;
    final subscription = _playerSubscription;
    _playerSubscription = null;
    await subscription?.cancel();
    await player?.dispose();
    await stopPlaybackService?.call();
    if (!_valid(generation)) return;
    await fallback.stop();
    if (!_valid(generation)) return;
    _chromium = false;
    _publish(PlaybackStatus(volume: _status.volume, generation: _generation));
  }

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) =>
      play(track, startAt: position ?? Duration.zero, play: false);
  @override
  Future<void> seekTo(Duration position) async {
    _checkOpen();
    if (position.isNegative) throw ArgumentError.value(position, 'position');
    if (!_chromium) return fallback.seekTo(position);
    final generation = _generation;
    await (await _active())?.seekTo(
      seconds: position.inMicroseconds / Duration.microsecondsPerSecond,
    );
    if (_valid(generation)) {
      _publish(_status.copyWith(position: position));
      _event(PlaybackEventType.positionDiscontinuity);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _checkOpen();
    if (!volume.isFinite || volume < 0 || volume > 1)
      throw ArgumentError.value(volume, 'volume');
    _publish(_status.copyWith(volume: volume));
    if (!_chromium) return fallback.setVolume(volume);
    await (await _active())?.setVolume((volume * 100).round());
  }

  @override
  dynamic get renderer =>
      _chromium ? (!showBrowser ? null : _browserRenderer) : fallback.renderer;
  dynamic get _browserRenderer => (_player == null
      ? null
      : ChromiumWebView(
          controller: _player!.webViewController,
          disposeController: false,
        ));

  @override
  bool get supportsSpeed => !_chromium && fallback.supportsSpeed;
  @override
  bool get supportsVideoFitMode => !_chromium && fallback.supportsVideoFitMode;
  @override
  bool get supportsTrackSelection =>
      !_chromium && fallback.supportsTrackSelection;
  @override
  bool get supportsExternalSubtitles =>
      !_chromium && fallback.supportsExternalSubtitles;
  @override
  bool get supportsSubtitleDelay =>
      !_chromium && fallback.supportsSubtitleDelay;
  @override
  bool get supportsSubtitleTextSize =>
      !_chromium && fallback.supportsSubtitleTextSize;
  @override
  bool get supportsSubtitleBackgroundStyling =>
      !_chromium && fallback.supportsSubtitleBackgroundStyling;
  @override
  Future<void> setSpeed(double speed) {
    _checkOpen();
    if (_chromium)
      throw UnsupportedError(
        'Chromium YouTube speed control is not implemented',
      );
    return fallback.setSpeed(speed);
  }

  @override
  Future<void> setSubtitleTrack(String? uri) => _chromium
      ? Future.error(UnsupportedError('YouTube subtitles'))
      : fallback.setSubtitleTrack(uri);
  @override
  Future<void> setSubtitleDelay(Duration delay) => _chromium
      ? Future.error(UnsupportedError('YouTube subtitle delay'))
      : fallback.setSubtitleDelay(delay);
  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) => _chromium
      ? Future.value()
      : fallback.setSubtitleAppearance(
          textSize: textSize,
          backgroundColor: backgroundColor,
        );
  @override
  Future<void> dispose() => _disposing ??= _dispose();
  Future<void> _dispose() async {
    _closed = true;
    ++_generation;
    await _playerSubscription?.cancel();
    await _player?.dispose();
    await stopPlaybackService?.call();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await fallback.dispose();
    await _statuses.close();
    await _events.close();
  }
}
