import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'pip_handler.dart';

enum EngineOwner { foreground, background }

/// Chromium remains the owner in Android background/PiP. The legacy handoff
/// policy is retained only for explicitly selected service-backed controllers.
enum PlaybackOwnershipPolicy { nativeHandoff, persistentForeground }

class HybridPlaybackEngine implements PlaybackController {
  final PlaybackController _foregroundEngine;
  final PlaybackController _backgroundEngine;
  final PlaybackOwnershipPolicy ownershipPolicy;
  final Duration handoffTimeout;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  EngineOwner _owner = EngineOwner.foreground;
  bool _isTransferring = false;
  int _handoffGeneration = 0;

  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _eventController = StreamController<PlaybackEvent>.broadcast();

  PlaybackStatus _currentStatus = const PlaybackStatus();
  PlaybackState _intendedState = PlaybackState.idle;
  PlaybackTrack? _currentTrack;
  PlaybackTrack? _prewarmedTrack; // track currently cued in the inactive engine
  bool _disposed = false;
  int _playGeneration = 0;
  int _lastCompletedGeneration = -1;
  Timer? _handoffTimeout;

  // Exposed for testing only.
  @visibleForTesting
  EngineOwner get owner => _owner;

  HybridPlaybackEngine({
    PlaybackController? foregroundEngine,
    PlaybackController? backgroundEngine,
    this.ownershipPolicy = PlaybackOwnershipPolicy.nativeHandoff,
    this.handoffTimeout = const Duration(seconds: 5),
  }) : _foregroundEngine = foregroundEngine ?? MediaKitPlaybackEngine(),
       _backgroundEngine = backgroundEngine ?? NativeServicePlaybackEngine() {
    _subscriptions.add(
      _foregroundEngine.statusStream.listen((status) {
        _handleSubStatus(EngineOwner.foreground, status);
      }),
    );

    _subscriptions.add(
      _foregroundEngine.eventStream.listen((event) {
        _handleSubEvent(EngineOwner.foreground, event);
      }),
    );

    _subscriptions.add(
      _backgroundEngine.statusStream.listen((status) {
        _handleSubStatus(EngineOwner.background, status);
      }),
    );

    _subscriptions.add(
      _backgroundEngine.eventStream.listen((event) {
        _handleSubEvent(EngineOwner.background, event);
      }),
    );

    PipHandler.addActivityStoppedListener(_onActivityStopped);
    PipHandler.addActivityStartedListener(_onActivityStarted);
    PipHandler.addPipModeListener(_onPipModeChanged);
    PipHandler.addPipEntryFailedListener(_onPipEntryFailed);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle callbacks
  // ---------------------------------------------------------------------------

  void _onActivityStopped() {
    if (_disposed ||
        ownershipPolicy == PlaybackOwnershipPolicy.persistentForeground)
      return;
    // Guard against the ordering race:
    //   onActivityStopped fires BEFORE onPipModeChanged(true)
    // Both isPipRequestPending (set before the native call) and isInPipMode
    // (confirmed by Android) can protect this window.
    if (PipHandler.isPipRequestPending || PipHandler.isInPipMode) {
      _log(
        'Background handoff deferred: '
        'pipRequestPending=${PipHandler.isPipRequestPending} '
        'inPip=${PipHandler.isInPipMode} '
        'owner=$_owner gen=$_handoffGeneration',
      );
      return;
    }
    _initiateHandoff(EngineOwner.background);
  }

  void _onActivityStarted() {
    if (_disposed ||
        ownershipPolicy == PlaybackOwnershipPolicy.persistentForeground)
      return;

    // Only initiate if we are not already on foreground and not already
    // mid-transfer toward foreground, to avoid redundant handoffs.
    if (_owner == EngineOwner.foreground && !_isTransferring) return;
    _initiateHandoff(EngineOwner.foreground);
  }

  // SAFETY NET: onPipModeChanged(true) is the authoritative confirmation that
  // PiP is active. It also recovers from the race where onActivityStopped
  // arrived before this event and a background handoff slipped through.
  void _onPipModeChanged(bool inPip) {
    if (_disposed ||
        ownershipPolicy == PlaybackOwnershipPolicy.persistentForeground)
      return;
    if (inPip) {
      // PiP is now confirmed active. Clear the deferred flag (already on
      // foreground, or about to recover to it).

      if (_owner != EngineOwner.foreground) {
        _log(
          'SAFETY NET: PiP confirmed active but owner=$_owner; '
          'recovering to foreground. gen=$_handoffGeneration',
        );
        _initiateHandoff(EngineOwner.foreground);
      } else {
        _log(
          'PiP confirmed active; owner already foreground. gen=$_handoffGeneration',
        );
      }
    } else {
      // PiP ended. The correct action depends solely on whether the Activity
      // is currently stopped — not on the deferred flag, which may be stale.
      //
      // PiP false + Activity stopped  → background (user dismissed PiP window)
      // PiP false + Activity visible  → foreground (user expanded PiP; already owner)
      //
      // Snapshot isActivityStopped before clearing the deferred flag so the
      // decision is based on current state rather than a potentially stale bool.
      final shouldBackground = PipHandler.isActivityStopped;

      if (shouldBackground) {
        _log(
          'PiP exited while activity stopped; initiating background handoff. '
          'gen=$_handoffGeneration',
        );
        _initiateHandoff(EngineOwner.background);
      }
      // If activity is running (user expanded PiP → fullscreen), foreground
      // is already owner; nothing to do.
    }
  }

  // PiP entry failed — clear deferred flag and, if the activity is already
  // stopped, do the background handoff that was deferred unnecessarily.
  void _onPipEntryFailed() {
    if (_disposed ||
        ownershipPolicy == PlaybackOwnershipPolicy.persistentForeground)
      return;

    _log('PiP entry failed. activityStopped=${PipHandler.isActivityStopped}');
    if (PipHandler.isActivityStopped) {
      _initiateHandoff(EngineOwner.background);
    }
  }

  void _updateStatus(PlaybackStatus status) {
    if (_disposed) return;
    _currentStatus = status;
    _statusController.add(status);
  }

  void _handleSubStatus(EngineOwner source, PlaybackStatus status) {
    if (_disposed) return;
    if (source != _owner) {
      if (status.state == PlaybackState.playing) {
        _log(
          'Containment: Inactive engine $source emitted playing, pausing it.',
        );
        final engine = source == EngineOwner.foreground
            ? _foregroundEngine
            : _backgroundEngine;
        engine.pause(caller: 'containment');
      }
      return;
    }
    if (_isTransferring) return;
    if (_intendedState != PlaybackState.playing &&
        status.state == PlaybackState.playing) {
      unawaited(_activeEngine.pause(caller: 'intent_containment'));
      return;
    }
    // Route completion through unified handler; don't let raw 'ended' propagate.
    if (status.state == PlaybackState.ended) {
      _handleTrackCompletion(source, status.track, status.generation);
      return;
    }
    _updateStatus(status);
  }

  void _handleSubEvent(EngineOwner source, PlaybackEvent event) {
    if (event.type == PlaybackEventType.trackEnded) {
      // Route through unified handler — deduplication guards against both
      // the status path (background) and event path (foreground) firing.
      _handleTrackCompletion(source, event.track, event.generation);
      return;
    }
    if (source == _owner) {
      if (_isTransferring) return;
      if (!_disposed) _eventController.add(event);
    }
  }

  /// Single authority for track-completion logic.
  /// Validates: active owner, track identity, and generation deduplication.
  void _handleTrackCompletion(
    EngineOwner source,
    PlaybackTrack? completedTrack,
    int? generation,
  ) {
    if (source != _owner) return;
    if (completedTrack == null || completedTrack.id != _currentTrack?.id) {
      _log(
        'Completion rejected: track mismatch '
        '(completed=${completedTrack?.id}, current=${_currentTrack?.id})',
      );
      return;
    }
    final expectedGen = source == EngineOwner.foreground
        ? _activeForegroundGeneration
        : _activeBackgroundGeneration;
    if (generation != null &&
        expectedGen != null &&
        generation != expectedGen) {
      _log(
        'Completion rejected: child generation mismatch (completed=$generation, expected=$expectedGen)',
      );
      return;
    }
    if (_lastCompletedGeneration == _playGeneration) {
      _log('Completion rejected: duplicate for generation $_playGeneration');
      return;
    }
    if (_isTransferring) {
      _log(
        'Completion during transfer — advancing generation and passing through.',
      );
      _handoffGeneration++;
      _isTransferring = false;
    }
    _lastCompletedGeneration = _playGeneration;
    _log('Track completed: ${completedTrack.id} (gen: $_playGeneration)');
    if (!_disposed) {
      _eventController.add(
        PlaybackEvent(
          type: PlaybackEventType.trackEnded,
          track: completedTrack,
        ),
      );
      _updateStatus(_currentStatus.copyWith(state: PlaybackState.ended));
    }
  }

  void _log(String msg) {
    final time = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('$time [PipDebug][ENGINE] $msg');
  }

  PlaybackController get _activeEngine =>
      _owner == EngineOwner.foreground ? _foregroundEngine : _backgroundEngine;
  PlaybackController get _inactiveEngine =>
      _owner == EngineOwner.foreground ? _backgroundEngine : _foregroundEngine;

  int? _activeForegroundGeneration;
  int? _activeBackgroundGeneration;

  Future<void> _initiateHandoff(EngineOwner targetOwner) async {
    if (_disposed ||
        ownershipPolicy == PlaybackOwnershipPolicy.persistentForeground ||
        _owner == targetOwner ||
        _currentTrack?.sourceType != PlaybackSourceType.online)
      return;
    final sourceOwner = _owner;
    final source = _activeEngine;
    final destination = _inactiveEngine;
    final track = _currentTrack!;
    final generation = ++_handoffGeneration;
    bool current() =>
        !_disposed &&
        generation == _handoffGeneration &&
        _currentTrack?.id == track.id;
    _isTransferring = true;
    _owner = targetOwner;
    StreamSubscription<PlaybackStatus>? acknowledgment;
    try {
      await source
          .pause(caller: 'handoff', failOnTimeout: true)
          .timeout(handoffTimeout);
      if (!current()) return;
      final position = source.currentStatus.position;
      await destination.setVolume(_currentStatus.volume);
      if (!current()) return;
      if (_intendedState == PlaybackState.playing) {
        final playing = Completer<PlaybackStatus>();
        acknowledgment = destination.statusStream.listen((status) {
          if (status.state == PlaybackState.playing && !playing.isCompleted)
            playing.complete(status);
        });
        final results = await Future.wait<dynamic>([
          destination.play(track, startAt: position).timeout(handoffTimeout),
          playing.future.timeout(handoffTimeout),
        ], eagerError: true);
        if (!current()) return;
        final confirmed = results[1] as PlaybackStatus;
        if (targetOwner == EngineOwner.foreground) {
          _activeForegroundGeneration = confirmed.generation;
        } else {
          _activeBackgroundGeneration = confirmed.generation;
        }
        // A pause received while the destination opened must still win.
        if (_intendedState != PlaybackState.playing)
          await destination.pause(caller: 'handoff_intent');
      } else {
        await destination
            .play(track, startAt: position, play: false)
            .timeout(handoffTimeout);
      }
      if (!current()) return;
      _isTransferring = false;
      _updateStatus(destination.currentStatus);
    } catch (error) {
      if (!current()) return;
      // Invalidate outstanding acknowledgments before cleanup. Never restart the
      // source automatically: failed pause/initialization cannot grant autoplay.
      ++_handoffGeneration;
      try {
        await destination.stop().timeout(handoffTimeout);
      } catch (_) {}
      if (_disposed || _handoffGeneration != generation + 1) return;
      _owner = sourceOwner;
      _isTransferring = false;
      _intendedState = PlaybackState.paused;
      _updateStatus(
        _currentStatus.copyWith(
          state: PlaybackState.error,
          error: 'Playback handoff failed: $error',
        ),
      );
      _eventController.add(
        PlaybackEvent(
          type: PlaybackEventType.playbackError,
          track: track,
          message: 'Playback handoff failed: $error',
        ),
      );
    } finally {
      await acknowledgment?.cancel();
    }
  }

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<PlaybackEvent> get eventStream => _eventController.stream;

  @override
  PlaybackStatus get currentStatus => _currentStatus;

  @override
  dynamic get renderer => _foregroundEngine.renderer;
  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    _playGeneration++;
    ++_handoffGeneration;
    _isTransferring = false;
    _currentTrack = track;
    _intendedState = PlaybackState.paused;
    await _activeEngine.prepare(track, position: position);
  }

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    _playGeneration++;
    _handoffGeneration++;
    _statusController.add(const PlaybackStatus(state: PlaybackState.preparing));
    _isTransferring = false;
    _currentTrack = track;
    _prewarmedTrack = null; // new track supersedes any prior pre-warm
    _intendedState = play ? PlaybackState.playing : PlaybackState.paused;
    final generation = _playGeneration;
    final active = _activeEngine;
    if (ownershipPolicy == PlaybackOwnershipPolicy.nativeHandoff)
      await _inactiveEngine.stop();
    if (_disposed || generation != _playGeneration) return;

    final playingFuture = _activeEngine.statusStream
        .firstWhere((s) => s.state == PlaybackState.playing)
        .timeout(const Duration(seconds: 5))
        .catchError((_) => const PlaybackStatus());

    await active.play(track, startAt: startAt, play: play);
    if (_disposed || generation != _playGeneration) return;

    if (_activeEngine.currentStatus.state == PlaybackState.playing) {
      if (_owner == EngineOwner.foreground) {
        _activeForegroundGeneration = _activeEngine.currentStatus.generation;
      } else {
        _activeBackgroundGeneration = _activeEngine.currentStatus.generation;
      }
    } else {
      playingFuture.then((status) {
        if (!_disposed &&
            generation == _playGeneration &&
            status.state == PlaybackState.playing) {
          if (_owner == EngineOwner.foreground) {
            _activeForegroundGeneration = status.generation;
          } else {
            _activeBackgroundGeneration = status.generation;
          }
        }
      });
    }

    // Pre-warm the inactive engine so it has the video cued and ready.
    // This drastically reduces handoff latency on minimize.
    _prewarmInactiveEngine(track);
  }

  /// Silently cues the given track on the inactive engine so it is ready
  /// to take over on the next handoff without a full prepare round-trip.
  void _prewarmInactiveEngine(PlaybackTrack track) {
    if (ownershipPolicy == PlaybackOwnershipPolicy.persistentForeground ||
        track.sourceType != PlaybackSourceType.online)
      return;
    final inactive = _inactiveEngine;
    _prewarmedTrack = track;
    // Use position=0 for pre-warm; actual position is seeked on handoff.
    inactive.prepare(track, position: Duration.zero).catchError((e) {
      _log('Pre-warm error (ignored): $e');
      if (_prewarmedTrack?.id == track.id) _prewarmedTrack = null;
    });
  }

  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    _intendedState = PlaybackState.paused;
    _updateStatus(_currentStatus.copyWith(state: PlaybackState.paused));
    await _activeEngine.pause(caller: caller, failOnTimeout: failOnTimeout);
  }

  @override
  Future<void> resume() async {
    _intendedState = PlaybackState.playing;
    _updateStatus(_currentStatus.copyWith(state: PlaybackState.playing));
    await _activeEngine.resume();
  }

  @override
  Future<void> stop() async {
    _handoffGeneration++;
    _isTransferring = false;
    _intendedState = PlaybackState.idle;
    _currentTrack = null;
    _updateStatus(
      _currentStatus.copyWith(
        state: PlaybackState.idle,
        track: null,
        activeVideoId: null,
      ),
    );
    await _foregroundEngine.stop();
    await _backgroundEngine.stop();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _updateStatus(_currentStatus.copyWith(position: position));
    await _activeEngine.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _updateStatus(_currentStatus.copyWith(volume: volume));
    await _foregroundEngine.setVolume(volume);
    if (ownershipPolicy == PlaybackOwnershipPolicy.nativeHandoff)
      await _backgroundEngine.setVolume(volume);
  }

  @override
  bool get supportsSpeed => _activeEngine.supportsSpeed;

  /// Reports the capability of the foreground engine, which is the one
  /// rendering the visible video surface. The background engine never serves
  /// the UI, so its value is not relevant here.
  @override
  bool get supportsVideoFitMode => _foregroundEngine.supportsVideoFitMode;

  @override
  Future<void> setSpeed(double speed) async {
    await _foregroundEngine.setSpeed(speed);
    await _backgroundEngine.setSpeed(speed);
  }

  @override
  Future<void> setSubtitleTrack(String? uri) async {
    await _foregroundEngine.setSubtitleTrack(uri);
    await _backgroundEngine.setSubtitleTrack(uri);
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    await _foregroundEngine.setSubtitleDelay(delay);
    await _backgroundEngine.setSubtitleDelay(delay);
  }

  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {
    await _foregroundEngine.setSubtitleAppearance(
      textSize: textSize,
      backgroundColor: backgroundColor,
    );
    await _backgroundEngine.setSubtitleAppearance(
      textSize: textSize,
      backgroundColor: backgroundColor,
    );
  }

  @override
  bool get supportsTrackSelection => _activeEngine.supportsTrackSelection;

  @override
  bool get supportsExternalSubtitles => _activeEngine.supportsExternalSubtitles;

  @override
  bool get supportsSubtitleDelay => _activeEngine.supportsSubtitleDelay;

  @override
  bool get supportsSubtitleTextSize => _activeEngine.supportsSubtitleTextSize;

  @override
  bool get supportsSubtitleBackgroundStyling =>
      _activeEngine.supportsSubtitleBackgroundStyling;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_playGeneration;
    ++_handoffGeneration;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    PipHandler.removeActivityStoppedListener(_onActivityStopped);
    PipHandler.removeActivityStartedListener(_onActivityStarted);
    PipHandler.removePipModeListener(_onPipModeChanged);
    PipHandler.removePipEntryFailedListener(_onPipEntryFailed);
    _handoffTimeout?.cancel();
    await _foregroundEngine.dispose();
    await _backgroundEngine.dispose();
    _statusController.close();
    _eventController.close();
  }
}
