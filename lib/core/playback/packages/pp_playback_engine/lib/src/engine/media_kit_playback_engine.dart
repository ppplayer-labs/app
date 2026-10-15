import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:media_kit_video/media_kit_video.dart';

import '../models/playback_status.dart';
import '../models/playback_event.dart';
import '../models/playback_track.dart';
import 'playback_controller.dart';
import 'background_playback_experiment.dart';

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
// INativePlayerAdapter — injectable for production and tests
// ---------------------------------------------------------------------------

/// Abstraction over a single native media_kit player instance.
///
/// The production implementation ([MediaKitPlayerAdapter]) wraps the real
/// [Player]. Tests inject a fake that exposes the same event streams so the
/// engine's lifecycle logic can be exercised without a real media_kit player.
abstract class INativePlayerAdapter {
  Stream<bool> get playingStream;
  Stream<bool> get bufferingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<Duration> get bufferStream;
  Stream<String> get errorStream;
  Stream<bool> get completedStream;
  Stream<VideoParams> get videoParamsStream;

  /// The [VideoController] associated with this player, or null for adapters
  /// that do not render video (e.g. audio-only test fakes).
  VideoController? get videoController;

  Future<void> open(
    String uri, {
    bool play = false,
    Map<String, String>? httpHeaders,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume100);
  Future<void> setRate(double rate);
  Future<void> setSubtitleTrack(SubtitleTrack track);
  Future<void> setSubtitleDelay(Duration delay);
  Future<void> setSubtitleAppearance({double? textSize, int? backgroundColor});

  bool get supportsTrackSelection;
  bool get supportsExternalSubtitles;
  bool get supportsSubtitleDelay;
  bool get supportsSubtitleTextSize;
  bool get supportsSubtitleBackgroundStyling;

  /// Dispose this adapter and its underlying player. Must be idempotent.
  Future<void> dispose();
}

/// Production adapter wrapping a real [media_kit] [Player].
class MediaKitPlayerAdapter implements INativePlayerAdapter {
  static Player? _sharedPlayer;
  static VideoController? _sharedVideoController;

  MediaKitPlayerAdapter() {
    _sharedPlayer ??= Player(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.debug),
    );
    _sharedVideoController ??= VideoController(_sharedPlayer!);
    _player = _sharedPlayer!;
    _videoController = _sharedVideoController!;
    _logSubscription = _player.stream.log.listen(
      (event) =>
          print('MPV_LOG: ${event.level} - ${event.prefix}: ${event.text}'),
    );
    try {
      // Enable ffmpeg HTTPS reconnects to prevent EOF/partial file when seeking
      (_player.platform as dynamic).setProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_streamed=1,reconnect_delay_max=5,reconnect_on_network_error=1,reconnect_on_http_error=5xx',
      );
      // Keep some cache around
      (_player.platform as dynamic).setProperty('cache-secs', '100');
      // Increase demuxer cache to prevent stalling when skipping fragments
      (_player.platform as dynamic).setProperty(
        'demuxer-max-bytes',
        '150000000',
      ); // 150MB
      (_player.platform as dynamic).setProperty(
        'demuxer-max-back-bytes',
        '50000000',
      ); // 50MB
    } catch (e) {
      debugPrint('MediaKitPlaybackEngine: Failed to set mpv properties: $e');
    }
  }

  late final Player _player;
  late final VideoController _videoController;
  StreamSubscription<PlayerLog>? _logSubscription;
  bool _disposed = false;

  @override
  VideoController? get videoController => _videoController;

  @override
  Stream<bool> get playingStream => _player.stream.playing;
  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;
  @override
  Stream<Duration> get positionStream => _player.stream.position;
  @override
  Stream<Duration> get durationStream => _player.stream.duration;
  @override
  Stream<Duration> get bufferStream => _player.stream.buffer;
  @override
  Stream<String> get errorStream => _player.stream.error;
  @override
  Stream<bool> get completedStream => _player.stream.completed;
  @override
  Stream<VideoParams> get videoParamsStream => _player.stream.videoParams;

  Media? _currentMedia;
  Future<void>? _cacheReady;

  Future<void> _configureCacheDirectory() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      // Android has no desktop home/cache directory for mpv's disk-cache default.
      final directory = await Directory(
        '${Directory.systemTemp.path}/ppplayer-mpv-cache',
      ).create(recursive: true);
      await (_player.platform as dynamic).setProperty(
        'demuxer-cache-dir',
        directory.path,
      );
    } on FileSystemException catch (error) {
      // An unavailable temporary directory must not prevent memory-cached playback.
      await (_player.platform as dynamic).setProperty('cache-on-disk', 'no');
      debugPrint('MediaKitPlaybackEngine: Disk cache unavailable: $error');
    }
  }

  @override
  Future<void> open(
    String uri, {
    bool play = false,
    Map<String, String>? httpHeaders,
  }) async {
    await (_cacheReady ??= _configureCacheDirectory());
    final scheme =
        kIsWeb ? '' : (Uri.tryParse(uri)?.scheme.toLowerCase() ?? '');
    final local =
        !kIsWeb &&
        (scheme.isEmpty ||
            const {'asset', 'file', 'content'}.contains(scheme) ||
            RegExp(r'^[A-Za-z]:[\\/]').hasMatch(uri));
    if (!kIsWeb) {
      // Local files need precise seeks even when the target is between keyframes.
      // Keep keyframe seeking for network streams to avoid expensive HLS decoding.
      await (_player.platform as dynamic).setProperty(
        'hr-seek',
        local ? 'yes' : 'no',
      );
    }
    // Bug fix: do NOT inject HTTP headers for local-scheme URIs (file://, content://,
    // asset://). libmpv ignores them for local sources, but on Android passing a header
    // map with a content:// URI can trigger an HTTP-resource code path and cause
    // access-denied failures.
    Map<String, String> headers;
    if (local) {
      headers = httpHeaders ?? const {};
    } else {
      headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            ' (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
      };
      if (httpHeaders != null) {
        headers.addAll(httpHeaders);
      }
    }
    _currentMedia = Media(uri, httpHeaders: headers.isEmpty ? null : headers);
    return _player.open(_currentMedia!, play: play);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setVolume(double volume100) => _player.setVolume(volume100);
  @override
  Future<void> setRate(double rate) => _player.setRate(rate);
  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) =>
      _player.setSubtitleTrack(track);

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    if (_player.platform != null) {
      try {
        await (_player.platform as dynamic).setProperty(
          'sub-delay',
          (delay.inMilliseconds / 1000.0).toString(),
        );
      } catch (e) {
        debugPrint('Failed to set subtitle delay: $e');
      }
    }
  }

  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {
    if (_player.platform != null) {
      try {
        if (textSize != null) {
          await (_player.platform as dynamic).setProperty(
            'sub-font-size',
            textSize.toString(),
          );
        }
        if (backgroundColor != null) {
          final hexColor =
              '#${backgroundColor.toRadixString(16).padLeft(8, '0')}';
          await (_player.platform as dynamic).setProperty(
            'sub-back-color',
            hexColor,
          );
        }
      } catch (e) {
        debugPrint('Failed to set subtitle appearance: $e');
      }
    }
  }

  @override
  bool get supportsTrackSelection => true;
  @override
  bool get supportsExternalSubtitles => true;
  @override
  bool get supportsSubtitleDelay => true;
  @override
  bool get supportsSubtitleTextSize => true;
  @override
  bool get supportsSubtitleBackgroundStyling => true;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _logSubscription?.cancel();
    _logSubscription = null;
    // We do NOT dispose the shared player to avoid native FFI crashes.
  }
}

// ---------------------------------------------------------------------------
// NativePlaybackSession — one per play/prepare attempt
// ---------------------------------------------------------------------------

/// Owns one native player instance and all its event subscriptions.
///
/// Event callbacks capture this object directly. When the engine replaces
/// [_activeSession] the old session reference no longer matches, so any
/// late-arriving event from the old player is trivially discarded without
/// inspecting URIs, extras, or readiness flags.
class NativePlaybackSession {
  NativePlaybackSession({
    required this.generation,
    required this.adapter,
    Duration startPosition = Duration.zero,
  }) : progressBaseline = startPosition;

  final int generation;
  final INativePlayerAdapter adapter;
  Duration progressBaseline;
  bool hasPlaybackProgress = false;
  final List<StreamSubscription<dynamic>> subscriptions = [];
  bool _torn = false;

  VideoController? get videoController => adapter.videoController;

  /// Cancel subscriptions and dispose the adapter exactly once (idempotent).
  Future<void> tear() async {
    if (_torn) return;
    _torn = true;
    for (final sub in subscriptions) {
      sub.cancel();
    }
    subscriptions.clear();
    await adapter.dispose();
  }
}

// ---------------------------------------------------------------------------
// MediaKitPlaybackEngine
// ---------------------------------------------------------------------------

class MediaKitPlaybackEngine implements PlaybackController {
  /// Factory for native player adapters.
  ///
  /// Defaults to creating a [MediaKitPlayerAdapter] (production).
  /// Inject a controlled fake in tests to exercise the production engine's
  /// lifecycle logic without a real media_kit player.
  final INativePlayerAdapter Function()? nativeAdapterFactory;

  MediaKitPlaybackEngine({this.nativeAdapterFactory}) {
    _initMediaKit();
  }

  void _initMediaKit() {
    try {
      MediaKit.ensureInitialized();
    } catch (e) {
      debugPrint(
        'MediaKitPlaybackEngine: MediaKit.ensureInitialized skipped (test env?): $e',
      );
    }
  }

  /// Informs the engine that the host activity is stopped (e.g. screen locked).
  /// Used to block IFrame playback dispatches when the WebView is frozen.
  static bool isActivityStopped = false;

  // ── Native session ─────────────────────────────────────────────────────────
  NativePlaybackSession? _activeSession;

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
  bool _valid(int generation) =>
      !_disposed && _attemptActive && generation == _playGeneration;

  double? _currentStartSeconds;
  Duration? _confirmedPlaybackPosition;
  int _confirmedPositionGeneration = -1;

  Timer? _watchdogTimer;
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();

  PlaybackStatus _currentStatus = const PlaybackStatus(supportsSpeed: true);
  PlaybackState? _intendedState;

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  INativePlayerAdapter _makeAdapter() =>
      nativeAdapterFactory != null
          ? nativeAdapterFactory!()
          : MediaKitPlayerAdapter();

  /// Immediately detach [_activeSession] (so its callbacks are rejected), then
  /// stop + dispose it asynchronously. Must be called *before* any await so
  /// a superseded open() cannot race with cleanup.
  Future<void> _invalidateActiveSession() async {
    final old = _activeSession;
    _activeSession =
        null; // detach synchronously — callbacks rejected immediately

    if (old == null) {
      await _invalidationFuture;
      return;
    }

    Future<void> doInvalidate() async {
      try {
        await old.adapter.stop().timeout(const Duration(seconds: 1));
      } catch (_) {}
      await old.tear();
    }

    final previous = _invalidationFuture;
    final current =
        (previous == null)
            ? doInvalidate()
            : previous.whenComplete(doInvalidate);

    _invalidationFuture = current;
    // The production adapters share one native player. Finish each queued
    // teardown once before opening a replacement on that player.
    await current;
  }

  /// Bind session-owned adapter streams to engine update handlers.
  ///
  /// Each closure captures [session] by reference. If [session] is no longer
  /// [_activeSession] when the event fires the update is dropped with a single
  /// identity check — no URI comparison, no extras, no readiness flag.
  void _bindSession(NativePlaybackSession session) {
    final a = session.adapter;
    session.subscriptions.addAll([
      a.positionStream.listen((pos) {
        if (session != _activeSession || _disposed) return;
        // A playing acknowledgement can precede a failed native output.
        // Only position beyond the requested seek point proves playback started.
        if (_intendedState == PlaybackState.playing &&
            pos > session.progressBaseline) {
          session.hasPlaybackProgress = true;
          _watchdogTimer?.cancel();
        }
        _updateStatus(
          _currentStatus.copyWith(
            position: pos,
            isLive: _currentStatus.track?.liveStatus == PlaybackLiveStatus.live,
          ),
        );
      }),
      a.durationStream.listen((dur) {
        if (session != _activeSession || _disposed) return;
        final track = _currentStatus.track;
        bool isSeekable =
            dur > Duration.zero ||
            (track?.duration != null && track!.duration! > Duration.zero);
        // Conservatively disable seeking for explicitly live streams.
        if (track?.liveStatus == PlaybackLiveStatus.live) {
          isSeekable = false;
        }
        _updateStatus(
          _currentStatus.copyWith(
            duration: dur,
            isSeekable: isSeekable,
            isLive: track?.liveStatus == PlaybackLiveStatus.live,
          ),
        );
      }),
      a.bufferStream.listen((buf) {
        if (session != _activeSession || _disposed) return;
        _updateStatus(_currentStatus.copyWith(buffered: buf));
      }),
      a.playingStream.listen((playing) {
        if (session != _activeSession || _disposed) return;
        // Don't overwrite preparing — wait for buffering/playing stream events.
        if (_currentStatus.state == PlaybackState.preparing) return;
        _updateStatus(
          _currentStatus.copyWith(
            state: playing ? PlaybackState.playing : PlaybackState.paused,
          ),
        );
      }),
      a.errorStream.listen((err) {
        print('MediaKitPlaybackEngine: [ERROR] $err');
        if (session != _activeSession || _disposed) return;
        final errStr = err.toLowerCase();
        String errorCode = 'error:playback_failed';
        if (errStr.contains('403') || errStr.contains('forbidden')) {
          errorCode = 'error:forbidden';
        } else if (errStr.contains('404') || errStr.contains('not found')) {
          errorCode = 'error:not_found';
        } else if (errStr.contains('timeout') ||
            errStr.contains('unreachable') ||
            errStr.contains('connection refused') ||
            errStr.contains('no route')) {
          errorCode = 'error:playback_timeout';
        } else if (errStr.contains('format') ||
            errStr.contains('codec') ||
            errStr.contains('corrupt')) {
          errorCode = 'error:unsupported_format';
        } else if (errStr.contains('access') ||
            errStr.contains('permission')) {
          errorCode = 'error:file_inaccessible';
        }
        _watchdogTimer?.cancel();
        _updateStatus(
          _currentStatus.copyWith(state: PlaybackState.error, error: errorCode),
        );
      }),
      a.completedStream.listen((completed) {
        if (!completed) return;
        if (session != _activeSession || _disposed) return;
        _watchdogTimer?.cancel();
        _updateStatus(_currentStatus.copyWith(state: PlaybackState.ended));
      }),
      a.bufferingStream.listen((buffering) {
        if (session != _activeSession || _disposed) return;
        // Don't regress from a valid non-preparing state to "not-buffering"
        // unless we're already in buffering/playing.
        if (_currentStatus.state == PlaybackState.preparing && !buffering) {
          return;
        }
        _updateStatus(
          _currentStatus.copyWith(
            state:
                buffering
                    ? PlaybackState.buffering
                    : (_intendedState ?? PlaybackState.paused),
          ),
        );
      }),
      a.videoParamsStream.listen((params) {
        if (session != _activeSession || _disposed) return;
        final w = params.w ?? 0;
        final h = params.h ?? 0;
        final hasDimensions = w > 0 && h > 0;

        // If the track is statically known to be a video, don't let a transient 0x0
        // size param hide the view, which breaks native macOS texture binding.
        // Local audio with embedded cover art reports video dimensions too, so a
        // local track only shows video when it was classified isVideo at import.
        final hasVideo =
            (_currentStatus.track?.isVideo == true) ||
            (_currentStatus.track?.isLocal != true && hasDimensions);

        _updateStatus(
          _currentStatus.copyWith(
            hasVideo: hasVideo,
            activeVideoId: hasVideo ? _currentStatus.track?.id : null,
            videoAspectRatio: hasDimensions ? w / h : null,
          ),
        );
      }),
    ]);
  }

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
  dynamic get renderer => _activeSession?.videoController;
  // ---------------------------------------------------------------------------
  // prepare()
  // ---------------------------------------------------------------------------

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    if (_disposed) return;

    if (track.isLocal || track.sourceType == PlaybackSourceType.networkStream) {
      final uri = track.isLocal ? track.localMediaUri : track.networkMediaUri;
      if (uri == null) {
        _updateStatus(
          _currentStatus.copyWith(
            track: track,
            state: PlaybackState.error,
            error: 'Media URI is missing for ${track.id}',
          ),
        );
        return;
      }

      // ── Invalidate immediately BEFORE any await ───────────────────────────
      _intentRevision++;
      _intendedState = PlaybackState.paused;
      _playGeneration++;
      final myGen = _playGeneration;

      await _invalidateActiveSession();
      if (_disposed || _playGeneration != myGen) return;

      // ── Create and activate the new session ───────────────────────────────
      final session = NativePlaybackSession(
        generation: myGen,
        adapter: _makeAdapter(),
      );
      // Assign _activeSession first so its callbacks are accepted and the
      // renderer getter immediately returns the new VideoController.
      _activeSession = session;
      _attemptActive = true;
      _recoveryUsed = false;
      _ready = false;
      _latePauseGeneration = null;

      // Bind callbacks BEFORE opening so initialization events during open()
      // are accepted.
      _bindSession(session);

      // Arm watchdog to prevent hanging on inaccessible files or broken streams
      _watchdogTimer?.cancel();
      _watchdogTimer = Timer(Duration(seconds: track.isLocal ? 5 : 20), () {
        if (_disposed || _activeSession != session) return;
        if (_currentStatus.state == PlaybackState.preparing ||
            _currentStatus.state == PlaybackState.buffering) {
          _failAttempt(
            myGen,
            track.isLocal
                ? 'error:file_inaccessible'
                : 'error:playback_timeout',
          );
        }
      });

      // Publish the new renderer and status BEFORE opening media.
      _updateStatus(
        _currentStatus.copyWith(
          track: track,
          state: PlaybackState.preparing,
          clearError: true,
          activeVideoId: track.isVideo ? track.id : null,
          hasVideo: track.isVideo,
          isIFrameMode: false,
          generation: myGen,
          isLive: track.liveStatus == PlaybackLiveStatus.live,
          isSeekable: false,
          position: Duration.zero,
          duration: Duration.zero,
          buffered: Duration.zero,
        ),
      );

      try {
        // Non-autoplay: open without starting playback.
        await session.adapter
            .open(uri, play: false, httpHeaders: track.httpHeaders)
            .timeout(const Duration(seconds: 10));
        if (_disposed || _activeSession != session) return;

        // Apply settings AFTER open() to avoid hanging media_kit on Android.
        await session.adapter.setVolume(_currentStatus.volume * 100);
        if (_disposed || _activeSession != session) return;
        await session.adapter.setRate(_currentStatus.speed);
        if (_disposed || _activeSession != session) return;

        if (position != null) {
          await session.adapter.seek(position);
          if (_disposed || _activeSession != session) return;
        }

        // Do not overwrite a terminal state (error/ended) that may have arrived
        // from a stream event during open().
        if (_currentStatus.state == PlaybackState.preparing) {
          _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
        }
      } catch (e) {
        if (_disposed || _activeSession != session) return;
        final errStr = e.toString().toLowerCase();
        String errorCode = 'error:playback_failed';
        if (errStr.contains('403') || errStr.contains('forbidden')) {
          errorCode = 'error:forbidden';
        } else if (errStr.contains('404') || errStr.contains('not found')) {
          errorCode = 'error:not_found';
        } else if (errStr.contains('timeout') ||
            errStr.contains('unreachable') ||
            errStr.contains('connection refused') ||
            errStr.contains('no route')) {
          errorCode = 'error:playback_timeout';
        } else if (errStr.contains('format') || errStr.contains('codec')) {
          errorCode = 'error:unsupported_format';
        } else if (errStr.contains('access') ||
            errStr.contains('no such file')) {
          errorCode = 'error:file_inaccessible';
        }
        _updateStatus(
          _currentStatus.copyWith(state: PlaybackState.error, error: errorCode),
        );
      }
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

    if (track.isLocal || track.sourceType == PlaybackSourceType.networkStream) {
      final uri = track.isLocal ? track.localMediaUri : track.networkMediaUri;
      if (uri == null) {
        _updateStatus(
          _currentStatus.copyWith(
            track: track,
            state: PlaybackState.error,
            error: 'Media URI is missing for ${track.id}',
          ),
        );
        return;
      }

      // ── Invalidate immediately BEFORE any await ───────────────────────────
      _attemptActive = false;
      _intentRevision++;
      _intendedState = play ? PlaybackState.playing : PlaybackState.paused;
      _playGeneration++;
      final myGen = _playGeneration;
      _watchdogTimer?.cancel();

      await _invalidateActiveSession();
      if (_disposed || _playGeneration != myGen) return;

      // ── Create and activate the new session ───────────────────────────────
      final session = NativePlaybackSession(
        generation: myGen,
        adapter: _makeAdapter(),
        startPosition: startAt,
      );
      _activeSession = session;
      _attemptActive = true;
      _recoveryUsed = false;
      _ready = false;
      _latePauseGeneration = null;

      // Bind callbacks BEFORE opening so initialization events during open()
      // are accepted.
      _bindSession(session);

      // Arm watchdog to prevent hanging on inaccessible files or broken streams
      _watchdogTimer?.cancel();
      _watchdogTimer = Timer(Duration(seconds: track.isLocal ? 5 : 20), () {
        if (_disposed || _activeSession != session) return;
        final stalledStart =
            _currentStatus.state == PlaybackState.playing &&
            _intendedState == PlaybackState.playing &&
            !session.hasPlaybackProgress;
        if (stalledStart ||
            _currentStatus.state == PlaybackState.preparing ||
            _currentStatus.state == PlaybackState.buffering) {
          _failAttempt(
            myGen,
            track.isLocal && !stalledStart
                ? 'error:file_inaccessible'
                : 'error:playback_timeout',
          );
        }
      });

      // Publish the new renderer and status BEFORE opening media.
      _updateStatus(
        _currentStatus.copyWith(
          track: track,
          state: PlaybackState.preparing,
          clearError: true,
          activeVideoId: track.isVideo ? track.id : null,
          hasVideo: track.isVideo,
          isIFrameMode: false,
          generation: myGen,
          isLive: track.liveStatus == PlaybackLiveStatus.live,
          isSeekable: false,
          position: Duration.zero,
          duration: Duration.zero,
          buffered: Duration.zero,
        ),
      );

      try {
        // Non-autoplay open: explicitly start after verifying session ownership.
        await session.adapter
            .open(uri, play: false, httpHeaders: track.httpHeaders)
            .timeout(const Duration(seconds: 10));
        if (_disposed || _activeSession != session) return;

        // Apply user settings AFTER open() to prevent Android deadlocks.
        // Bug fix: guard each async call so a concurrent stop()/play() that
        // replaces _activeSession does not apply settings to a stale player.
        await session.adapter.setVolume(_currentStatus.volume * 100);
        if (_disposed || _activeSession != session) return;
        await session.adapter.setRate(_currentStatus.speed);
        if (_disposed || _activeSession != session) return;

        if (startAt > Duration.zero) {
          await session.adapter.seek(startAt);
          if (_disposed || _activeSession != session) return;
        }

        if (_intendedState == PlaybackState.playing) {
          await session.adapter.play();
          if (_disposed || _activeSession != session) return;
        }

        // Reconcile: move out of preparing if no terminal state arrived yet.
        final terminalStates = {PlaybackState.error, PlaybackState.ended};
        if (!terminalStates.contains(_currentStatus.state) &&
            _currentStatus.state == PlaybackState.preparing) {
          _updateStatus(
            _currentStatus.copyWith(state: PlaybackState.buffering),
          );
        }
      } catch (e) {
        if (_disposed || _activeSession != session) return;
        if (_valid(myGen)) {
          final errStr = e.toString().toLowerCase();
          String errorCode = 'error:playback_failed';
          if (errStr.contains('403') || errStr.contains('forbidden')) {
            errorCode = 'error:forbidden';
          } else if (errStr.contains('404') || errStr.contains('not found')) {
            errorCode = 'error:not_found';
          } else if (errStr.contains('timeout') ||
              errStr.contains('unreachable') ||
              errStr.contains('connection refused') ||
              errStr.contains('no route')) {
            errorCode = 'error:playback_timeout';
          } else if (errStr.contains('format') || errStr.contains('codec')) {
            errorCode = 'error:unsupported_format';
          } else if (errStr.contains('access') ||
              errStr.contains('no such file')) {
            errorCode = 'error:file_inaccessible';
          }
          _failAttempt(myGen, errorCode);
        }
      }
    }
  }

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    if (_disposed) return;
    if (_currentStatus.state == PlaybackState.paused ||
        _currentStatus.state == PlaybackState.idle) {
      return;
    }
    _intendedState = PlaybackState.paused;
    _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
    await _activeSession?.adapter.pause();
  }

  @override
  Future<void> resume() async {
    _intentRevision++;
    if (BackgroundPlaybackExperiment.enabled &&
        _currentStatus.isIFrameMode &&
        isActivityStopped) {
      _diag(
        'ENGINE resume() PASS-THROUGH [EXPERIMENT]: activity stopped but guard disabled.',
      );
    }

    _intendedState = PlaybackState.playing;
    await _activeSession?.adapter.play();
  }

  @override
  Future<void> stop() async {
    _playGeneration++;
    _intentRevision++;
    _attemptActive = false;
    _watchdogTimer?.cancel();
    _intendedState = PlaybackState.paused;

    // Optimistically update before awaiting so the UI reflects idle immediately.
    _updateStatus(
      _currentStatus.copyWith(
        state: PlaybackState.idle,
        track: null,
        activeVideoId: null,
      ),
    );

    await _invalidateActiveSession();
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (!_currentStatus.isSeekable) {
      debugPrint(
        'MediaKitPlaybackEngine: Blocked seek attempt to $position '
        '(isSeekable=false). Network capability is unknown or stream is live.',
      );
      return;
    }

    final wasPlaying = _currentStatus.state == PlaybackState.playing;

    final session = _activeSession;
    if (session == null) return;
    // A seek acknowledgement is not playback progress. Move the baseline
    // before dispatch so a backward seek during startup can still advance.
    session.progressBaseline = position;
    await session.adapter.seek(position);
    if (wasPlaying && _activeSession == session) {
      await session.adapter.play();
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    await _activeSession?.adapter.setVolume(volume * 100);
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
    await _activeSession?.adapter.setRate(speed);
  }

  @override
  Future<void> setSubtitleTrack(String? uri) async {
    if (uri == null) {
      await _activeSession?.adapter.setSubtitleTrack(SubtitleTrack.no());
    } else {
      await _activeSession?.adapter.setSubtitleTrack(SubtitleTrack.uri(uri));
    }
  }

  @override
  bool get supportsTrackSelection =>
      _activeSession?.adapter.supportsTrackSelection ?? false;

  @override
  bool get supportsExternalSubtitles =>
      _activeSession?.adapter.supportsExternalSubtitles ?? false;

  @override
  bool get supportsSubtitleDelay =>
      _activeSession?.adapter.supportsSubtitleDelay ?? false;

  @override
  bool get supportsSubtitleTextSize =>
      _activeSession?.adapter.supportsSubtitleTextSize ?? false;

  @override
  bool get supportsSubtitleBackgroundStyling =>
      _activeSession?.adapter.supportsSubtitleBackgroundStyling ?? false;

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    await _activeSession?.adapter.setSubtitleDelay(delay);
  }

  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {
    await _activeSession?.adapter.setSubtitleAppearance(
      textSize: textSize,
      backgroundColor: backgroundColor,
    );
  }
  // ---------------------------------------------------------------------------
  // Status update + IFrame position polling
  // ---------------------------------------------------------------------------

  void _failAttempt(int generation, String error) {
    if (!_valid(generation)) return;
    _attemptActive = false;
    _watchdogTimer?.cancel();
    _updateStatus(
      _currentStatus.copyWith(state: PlaybackState.error, error: error),
    );
  }

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
  }

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _attemptActive = false;
    _playGeneration++;
    _watchdogTimer?.cancel();

    // Detach and cancel the active session's subscriptions synchronously;
    // adapter disposal is awaited to ensure native resources are freed.
    // Subscriptions must be cancelled BEFORE the native object is freed to
    // prevent a callback firing into a freed object (SIGABRT in libmpv).
    final session = _activeSession;
    _activeSession = null;
    if (session != null) {
      for (final sub in session.subscriptions) {
        sub.cancel();
      }
      session.subscriptions.clear();
      try {
        await session.adapter.dispose().timeout(const Duration(seconds: 2));
      } catch (e) {
        // Native cleanup failed or timed out, but Dart state is isolated.
      }
    }
    _statusController.close();
    _eventController.close();
  }
}
