import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'capability_resolver.dart';
import 'models.dart';
import 'network_output_backend.dart';

const _unchanged = Object();

class _Snapshot {
  const _Snapshot(this.status, this.playing);
  final PlaybackStatus status;
  final bool playing;
}

class _RemoteSession {
  _RemoteSession({
    required this.output,
    required this.backend,
    required this.sessionId,
    required this.itemId,
  });
  PlaybackOutput output;
  final NetworkOutputBackend backend;
  final String sessionId;
  String itemId;
  PlaybackTrack? track;
  NetworkMediaLease? lease;
  NetworkOutputSessionState? latest;
  bool loaded = false;
  bool authoritative = false;
  String? completedItem;

  OutputCapabilities get capabilities =>
      latest?.capabilities ?? output.capabilities;
}

class _Superseded implements Exception {}

/// Keeps the app's queue and media controls above protocol implementations.
/// The local controller and its rendering objects live for this router's lifetime.
class NetworkOutputController implements PlaybackController {
  NetworkOutputController({
    required PlaybackController localController,
    required Iterable<NetworkOutputBackend> backends,
    required NetworkMediaFactory mediaFactory,
    OutputCapabilityResolver capabilityResolver =
        const OutputCapabilityResolver(),
    this.operationTimeout = const Duration(seconds: 10),
  }) : _local = localController,
       _backends = {},
       _mediaFactory = mediaFactory,
       _capabilityResolver = capabilityResolver,
       _status = localController.currentStatus {
    _desiredPlaying = _status.isPlaying || _status.isBuffering;
    _subscriptions.add(_local.statusStream.listen(_onLocalStatus));
    _subscriptions.add(
      _local.eventStream.listen((event) {
        if (!_disposed && _remote == null && !_suppressLocal) {
          _events.add(event);
        }
      }),
    );
    for (final backend in backends) {
      registerBackend(backend);
    }
    _setOutput(availableOutputs: [PlaybackOutput.local]);
  }

  void registerBackend(NetworkOutputBackend backend) {
    if (_disposed) return;
    if (_backends.containsKey(backend.kind)) return;
    _backends[backend.kind] = backend;
    _subscriptions.add(
      backend.outputs.listen((list) => _onOutputs(backend, list)),
    );
    _subscriptions.add(
      backend.sessionState.listen((event) => _onSession(backend, event)),
    );
    if (_output.discoveryActive) {
      backend.startDiscovery();
    }
  }

  final PlaybackController _local;
  final Map<OutputKind, NetworkOutputBackend> _backends;
  final NetworkMediaFactory _mediaFactory;
  final OutputCapabilityResolver _capabilityResolver;
  final Duration operationTimeout;
  final _statuses = StreamController<PlaybackStatus>.broadcast();
  final _events = StreamController<PlaybackEvent>.broadcast();
  final _outputs = StreamController<NetworkOutputState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Map<OutputKind, List<PlaybackOutput>> _discovered = {};
  Future<void> _commands = Future.value();
  Future<void>? _disposeFuture;
  PlaybackStatus _status;
  NetworkOutputState _output = const NetworkOutputState();
  _RemoteSession? _remote;
  _RemoteSession? _pendingRemote;
  int _requestedGeneration = 0;
  int _sessionCounter = 0;
  int _itemCounter = 0;
  bool _disposed = false;
  bool _suppressLocal = false;
  bool _switching = false;
  bool _desiredPlaying = false;

  Stream<NetworkOutputState> get outputStateStream => _outputs.stream;
  Iterable<NetworkOutputBackend> get backends => _backends.values;
  NetworkOutputState get currentOutputState => _output;
  PlaybackController get localController => _local;
  bool get isRemoteActive => _remote?.authoritative ?? false;
  bool get hasRemoteSelection => _remote != null;

  void _log(String message) => debugPrint('[Output] $message');

  Future<T> _serialize<T>(Future<T> Function() body) {
    if (_disposed)
      return Future.error(StateError('Output controller is disposed.'));
    final result = _commands.then((_) => body());
    _commands = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  bool _current(int generation) =>
      !_disposed && generation == _requestedGeneration;
  void _check(int generation) {
    if (!_current(generation)) throw _Superseded();
  }

  int _request({bool? playing}) {
    if (playing != null) _desiredPlaying = playing;
    return ++_requestedGeneration;
  }

  String _newSessionId() =>
      'output_${DateTime.now().microsecondsSinceEpoch}_${++_sessionCounter}';
  String _newItemId() => 'item_${++_itemCounter}';

  String _errorText(Object error) {
    final text = error is NetworkOutputException
        ? error.message
        : error.toString();
    return text.replaceAll(
      RegExp(r'(?:https?://|file://)\S+'),
      '[media address]',
    );
  }

  void _setOutput({
    PlaybackOutput? selectedOutput,
    List<PlaybackOutput>? availableOutputs,
    bool? discoveryActive,
    bool? connecting,
    bool? connected,
    bool? remoteActive,
    Object? connectingOutput = _unchanged,
    Object? session = _unchanged,
    bool? requiresSender,
    Object? error = _unchanged,
  }) {
    if (_disposed) return;
    _output = NetworkOutputState(
      selectedOutput: selectedOutput ?? _output.selectedOutput,
      availableOutputs: List.unmodifiable(
        availableOutputs ?? _output.availableOutputs,
      ),
      discoveryActive: discoveryActive ?? _output.discoveryActive,
      connecting: connecting ?? _output.connecting,
      connected: connected ?? _output.connected,
      remoteActive: remoteActive ?? _output.remoteActive,
      connectingOutput: identical(connectingOutput, _unchanged)
          ? _output.connectingOutput
          : connectingOutput as PlaybackOutput?,
      session: identical(session, _unchanged)
          ? _output.session
          : session as NetworkOutputSessionState?,
      generation: _requestedGeneration,
      requiresSender: requiresSender ?? _output.requiresSender,
      error: identical(error, _unchanged) ? _output.error : error as String?,
    );
    _outputs.add(_output);
  }

  void _publish(PlaybackStatus status) {
    if (_disposed) return;
    _status = status;
    _statuses.add(status);
  }

  void _onLocalStatus(PlaybackStatus status) {
    if (!_disposed && _remote == null && !_suppressLocal) _publish(status);
  }

  void _onOutputs(NetworkOutputBackend backend, List<PlaybackOutput> list) {
    if (_disposed) return;
    final unique = <String, PlaybackOutput>{};
    for (final output in list) {
      if (output.kind == backend.kind && output.kind != OutputKind.local) {
        unique[output.identity] = output;
      }
    }
    _discovered[backend.kind] = unique.values.toList();
    final available = [
      PlaybackOutput.local,
      ..._discovered.values.expand((list) => list),
    ];
    final active = _remote;
    if (active != null && active.backend == backend) {
      final refreshed = unique[active.output.identity];
      if (refreshed != null) active.output = refreshed;
    }
    _setOutput(availableOutputs: available, selectedOutput: active?.output);
  }

  bool _matches(
    _RemoteSession session,
    NetworkOutputBackend backend,
    NetworkOutputSessionState event,
  ) =>
      identical(session.backend, backend) &&
      session.output.id == event.endpointId &&
      session.sessionId == event.sessionId &&
      (event.itemId.isEmpty || session.itemId == event.itemId);

  void _onSession(
    NetworkOutputBackend backend,
    NetworkOutputSessionState event,
  ) {
    if (_disposed) return;
    final active = _remote;
    final pending = _pendingRemote;
    if (pending != null && _matches(pending, backend, event)) {
      pending.latest = event;
      return;
    }
    if (active == null || !_matches(active, backend, event) || !active.loaded) {
      _log(
        'stale_event_ignored kind=${backend.kind.name} active=${active != null} matches=${active != null ? _matches(active, backend, event) : false} loaded=${active?.loaded} pending=${pending != null} pending_matches=${pending != null ? _matches(pending, backend, event) : false} event_item=${event.itemId} pending_item=${pending?.itemId}',
      );
      return;
    }
    active.latest = event;
    if (_switching) return;
    if (!event.connected ||
        event.state == PlaybackState.error ||
        event.error != null) {
      _setOutput(
        session: event,
        connected: event.connected,
        remoteActive: event.connected && active.authoritative,
        error: event.error == null
            ? 'The output connection was lost.'
            : _errorText(event.error!),
      );
      _publish(_remoteStatus(active, PlaybackState.paused));
      return;
    }
    if (event.state == PlaybackState.ended) {
      if (active.completedItem == active.itemId) return;
      active.completedItem = active.itemId;
      _events.add(
        PlaybackEvent(
          type: PlaybackEventType.trackEnded,
          track: active.track,
          generation: _requestedGeneration,
        ),
      );
      active.loaded = false;
    }
    _setOutput(
      session: event,
      connected: true,
      remoteActive: active.authoritative,
      error: null,
    );
    _publish(_remoteStatus(active, event.state));
  }

  PlaybackStatus _remoteStatus(
    _RemoteSession session,
    PlaybackState state, {
    Duration? position,
  }) {
    final event = session.latest;
    final live =
        session.track?.liveStatus == PlaybackLiveStatus.live ||
        (event?.isLive ?? false);
    return PlaybackStatus(
      track: session.track,
      state: state,
      position: position ?? event?.position ?? Duration.zero,
      duration: live
          ? Duration.zero
          : event?.duration ?? session.track?.duration ?? Duration.zero,
      volume: event?.volume ?? _status.volume,
      speed: 1,
      generation: _requestedGeneration,
      isLive: live,
      isSeekable: !live && session.capabilities.seek,
      // A remote video never requests local PiP or replaces the local surface.
      hasVideo: false,
    );
  }

  _Snapshot _snapshot() =>
      _Snapshot(_status, _status.isPlaying || _status.isBuffering);

  Future<void> startDiscovery() => _serialize(() async {
    _setOutput(discoveryActive: true, error: null);
    _log('discovery.start');
    try {
      await Future.wait(
        _backends.values.map(
          (backend) => backend.startDiscovery().timeout(operationTimeout),
        ),
      );
    } catch (error) {
      _setOutput(discoveryActive: false, error: _errorText(error));
      rethrow;
    }
  });

  Future<void> stopDiscovery() => _serialize(() async {
    await Future.wait(
      _backends.values.map(
        (backend) => backend.stopDiscovery().timeout(operationTimeout),
      ),
    );
    _setOutput(discoveryActive: false);
  });

  Future<void> refreshDiscovery() => _serialize(() async {
    await Future.wait(
      _backends.values.map((backend) async {
        await backend.stopDiscovery().timeout(operationTimeout);
        await backend.startDiscovery().timeout(operationTimeout);
      }),
    );
    _setOutput(discoveryActive: true);
  });

  /// Idle local playback does no network work on resume. Connected backends may
  /// restore their monitoring/session using the same guarded identity.
  Future<void> refreshLifecycle() => _serialize(() async {
    final session = _remote;
    if (session != null && !_output.connected) {
      await session.backend
          .connect(session.output, sessionId: session.sessionId)
          .timeout(operationTimeout);
    }
    if (_output.discoveryActive) {
      await Future.wait(
        _backends.values.map(
          (backend) => backend.startDiscovery().timeout(operationTimeout),
        ),
      );
    }
  });

  Future<void> selectOutput(PlaybackOutput output) {
    if (output.kind == OutputKind.local) return returnToLocal();
    final generation = _request();
    return _serialize(() => _select(output, generation));
  }

  Future<void> _select(PlaybackOutput output, int generation) async {
    if (!_current(generation)) return;
    if (_remote?.output.identity == output.identity && _output.connected)
      return;
    final backend = _backends[output.kind];
    if (backend == null || output.kind == OutputKind.airPlay) {
      const error = NetworkOutputException(
        'This output requires its supported system integration.',
        code: 'unsupported_output',
      );
      _setOutput(error: error.message);
      throw error;
    }
    final before = _snapshot();
    final old = _remote;
    final track = before.status.track;
    if (track != null)
      _requireSupport(_capabilityResolver.sourceSupport(track, output));
    if (!output.isAvailable) {
      throw const NetworkOutputException(
        'This output is unavailable.',
        code: 'unavailable_output',
      );
    }
    final next = _RemoteSession(
      output: output,
      backend: backend,
      sessionId: _newSessionId(),
      itemId: _newItemId(),
    );
    _pendingRemote = next;
    _switching = true;
    var sourcePaused = false;
    var oldStopped = false;
    var transferPosition = before.status.position;
    _desiredPlaying = before.playing;
    _setOutput(connecting: true, connectingOutput: output, error: null);
    _log('connect.start kind=${output.kind.name}');
    try {
      await backend
          .connect(output, sessionId: next.sessionId)
          .timeout(operationTimeout);
      _check(generation);
      if (track != null) {
        next.track = track;
        next.lease = await _mediaFactory
            .prepare(
              track,
              output,
              sessionId: next.sessionId,
              itemId: next.itemId,
            )
            .timeout(operationTimeout);
        _check(generation);
        _requireSupport(
          _capabilityResolver.resolve(track, output, item: next.lease!.item),
        );
        _suppressLocal = true;
        if (old == null) {
          await _local
              .pause(caller: 'output-handoff', failOnTimeout: true)
              .timeout(operationTimeout);
          transferPosition = _local.currentStatus.position;
        } else if (old.loaded) {
          if (old.capabilities.pause) {
            await old.backend
                .pause(sessionId: old.sessionId, itemId: old.itemId)
                .timeout(operationTimeout);
          } else if (old.capabilities.stop) {
            await old.backend
                .stop(sessionId: old.sessionId, itemId: old.itemId)
                .timeout(operationTimeout);
            oldStopped = true;
          } else {
            throw const NetworkOutputException(
              'This output cannot be paused or stopped safely.',
              code: 'unsupported_operation',
            );
          }
          transferPosition = old.latest?.position ?? transferPosition;
        }
        sourcePaused = true;
        _check(generation);
        _log(
          'handoff.local_to_remote position=${transferPosition.inMilliseconds}',
        );
        final result = await backend
            .load(
              next.lease!.item,
              sessionId: next.sessionId,
              itemId: next.itemId,
              position: transferPosition,
              autoplay: _desiredPlaying,
            )
            .timeout(operationTimeout);
        _check(generation);
        if (!result.success)
          throw NetworkOutputException(
            result.error ?? 'The device did not accept this media.',
            code: 'load_failed',
          );
        next.loaded = true;
        next.authoritative = true;
        next.latest ??= NetworkOutputSessionState(
          endpointId: output.id,
          sessionId: next.sessionId,
          itemId: next.itemId,
          state: _desiredPlaying ? PlaybackState.playing : PlaybackState.paused,
          position: result.position ?? transferPosition,
          duration: result.duration ?? track.duration ?? Duration.zero,
          capabilities: result.capabilities,
          isLive: track.liveStatus == PlaybackLiveStatus.live,
        );
      }
      _remote = next;
      _pendingRemote = null;
      _commit(next);
      if (old != null) await _cleanup(old, stopPlayback: true);
    } catch (error, stack) {
      await _cleanup(next, stopPlayback: true);
      if (sourcePaused && !_disposed) {
        try {
          if (old == null) {
            await _restoreLocal(
              _Snapshot(
                before.status.copyWith(position: transferPosition),
                _desiredPlaying,
              ),
            );
          } else {
            await _restoreRemote(old, transferPosition, stopped: oldStopped);
          }
        } catch (_) {
          _setOutput(
            error: 'The output failed and playback could not be restored.',
          );
        }
      }
      if (error is! _Superseded && !_disposed) {
        debugPrint(
          '[Output] connect.error kind=${output.kind.name} error=$error stack=$stack',
        );
        _setOutput(error: _errorText(error));
        rethrow;
      } else if (error is _Superseded) {
        debugPrint('[Output] connect.superseded kind=${output.kind.name}');
      }
    } finally {
      if (identical(_pendingRemote, next)) _pendingRemote = null;
      _switching = false;
      _suppressLocal = false;
      _setOutput(connecting: false, connectingOutput: null);
      if (_remote == null && !_disposed) _publish(_local.currentStatus);
    }
  }

  void _requireSupport(OutputSupportResult support) {
    if (!support.supported) {
      final error = NetworkOutputException(
        support.reason ?? 'This media is unsupported.',
        code: 'unsupported_source',
      );
      _setOutput(error: error.message);
      throw error;
    }
  }

  void _commit(_RemoteSession session) {
    _setOutput(
      selectedOutput: session.output,
      session: session.latest,
      connected: true,
      remoteActive: session.authoritative,
      requiresSender: session.lease?.requiresSender ?? false,
      error: null,
    );
    if (session.latest != null)
      _publish(_remoteStatus(session, session.latest!.state));
    _log('connect.ready kind=${session.output.kind.name}');
  }

  Future<void> _restoreLocal(_Snapshot snapshot) async {
    final track = snapshot.status.track;
    if (track == null) return;
    await _local
        .prepare(track, position: snapshot.status.position)
        .timeout(operationTimeout);
    await _local.setVolume(snapshot.status.volume);
    if (_local.supportsSpeed) await _local.setSpeed(snapshot.status.speed);
    if (snapshot.playing) await _local.resume().timeout(operationTimeout);
  }

  Future<void> _restoreRemote(
    _RemoteSession session,
    Duration position, {
    required bool stopped,
  }) async {
    if (stopped && session.lease != null) {
      final result = await session.backend
          .load(
            session.lease!.item,
            sessionId: session.sessionId,
            itemId: session.itemId,
            position: position,
            autoplay: _desiredPlaying,
          )
          .timeout(operationTimeout);
      if (!result.success)
        throw const NetworkOutputException(
          'The previous output could not restore playback.',
        );
    } else if (_desiredPlaying) {
      await session.backend
          .play(sessionId: session.sessionId, itemId: session.itemId)
          .timeout(operationTimeout);
    }
    session.loaded = true;
    _commit(session);
  }

  Future<void> _cleanup(
    _RemoteSession session, {
    required bool stopPlayback,
  }) async {
    try {
      await session.backend
          .disconnect(sessionId: session.sessionId, stopPlayback: stopPlayback)
          .timeout(operationTimeout);
    } finally {
      await session.lease?.release();
      session.lease = null;
      session.loaded = false;
    }
  }

  Future<void> disconnect({bool stopPlayback = false}) {
    final generation = _request(playing: false);
    return _serialize(() async {
      if (!_current(generation)) return;
      final session = _remote;
      if (session == null) return;
      if (!stopPlayback && !_output.canDisconnectWithoutStop) {
        const error = NetworkOutputException(
          'This media needs this device to keep serving it. Use stop playback and disconnect.',
          code: 'sender_required',
        );
        _setOutput(error: error.message);
        throw error;
      }
      _remote = null;
      _switching = true;
      _suppressLocal = true;
      try {
        await _cleanup(session, stopPlayback: stopPlayback);
        _setOutput(
          selectedOutput: PlaybackOutput.local,
          connected: false,
          remoteActive: false,
          session: null,
          requiresSender: false,
          error: null,
        );
        // Plain disconnect intentionally leaves local playback paused.
        _publish(_local.currentStatus.copyWith(state: PlaybackState.paused));
      } finally {
        _switching = false;
        _suppressLocal = false;
      }
    });
  }

  Future<void> returnToLocal() {
    final generation = _request();
    return _serialize(() async {
      if (!_current(generation)) return;
      final session = _remote;
      if (session == null) return;
      final before = _snapshot();
      _desiredPlaying = before.playing;
      _switching = true;
      _suppressLocal = true;
      try {
        if (session.loaded) {
          if (!session.capabilities.stop)
            throw const NetworkOutputException(
              'This output cannot confirm stop playback.',
              code: 'unsupported_operation',
            );
          await session.backend
              .stop(sessionId: session.sessionId, itemId: session.itemId)
              .timeout(operationTimeout);
        }
        _check(generation);
        final position = session.latest?.position ?? before.status.position;
        await _cleanup(session, stopPlayback: true);
        _remote = null;
        _check(generation);
        await _restoreLocal(
          _Snapshot(
            before.status.copyWith(position: position),
            _desiredPlaying,
          ),
        );
        _check(generation);
        _setOutput(
          selectedOutput: PlaybackOutput.local,
          connected: false,
          remoteActive: false,
          session: null,
          requiresSender: false,
          error: null,
        );
        _publish(_local.currentStatus);
      } catch (error) {
        if (error is! _Superseded) {
          _setOutput(error: _errorText(error));
          rethrow;
        }
      } finally {
        _switching = false;
        _suppressLocal = false;
      }
    });
  }

  Future<void> _loadRemote(
    _RemoteSession session,
    PlaybackTrack track,
    Duration position,
    bool autoplay,
    int generation,
  ) async {
    NetworkMediaLease? lease;
    final previousLease = session.lease;
    session.loaded = false;
    session.itemId = _newItemId();
    session.track = track;
    session.latest = null;
    session.completedItem = null;
    try {
      _requireSupport(_capabilityResolver.sourceSupport(track, session.output));
      lease = await _mediaFactory
          .prepare(
            track,
            session.output,
            sessionId: session.sessionId,
            itemId: session.itemId,
          )
          .timeout(operationTimeout);
      _check(generation);
      _requireSupport(
        _capabilityResolver.resolve(track, session.output, item: lease.item),
      );
      final result = await session.backend
          .load(
            lease.item,
            sessionId: session.sessionId,
            itemId: session.itemId,
            position: position,
            autoplay: autoplay,
          )
          .timeout(operationTimeout);
      _check(generation);
      if (!result.success)
        throw NetworkOutputException(
          result.error ?? 'The output could not load this item.',
          code: 'load_failed',
        );
      session.lease = lease;
      lease = null;
      session.loaded = true;
      session.authoritative = true;
      session.latest ??= NetworkOutputSessionState(
        endpointId: session.output.id,
        sessionId: session.sessionId,
        itemId: session.itemId,
        state: autoplay ? PlaybackState.playing : PlaybackState.paused,
        position: result.position ?? position,
        duration: result.duration ?? track.duration ?? Duration.zero,
        capabilities: result.capabilities,
        isLive: track.liveStatus == PlaybackLiveStatus.live,
      );
      await previousLease?.release();
      _commit(session);
    } catch (error) {
      try {
        await session.backend
            .stop(sessionId: session.sessionId, itemId: session.itemId)
            .timeout(operationTimeout);
      } catch (_) {}
      await lease?.release();
      await previousLease?.release();
      session.lease = null;
      if (error is! _Superseded && !_disposed) {
        _setOutput(error: _errorText(error), requiresSender: false);
        // Output errors never enter PlayerNotifier's input-source recovery.
        _publish(
          _remoteStatus(session, PlaybackState.paused, position: position),
        );
        rethrow;
      }
    }
  }

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) {
    final generation = _request(playing: play);
    return _serialize(() async {
      if (!_current(generation)) return;
      final session = _remote;
      if (session == null) {
        await _local.play(track, startAt: startAt, play: play);
      } else {
        await _loadRemote(session, track, startAt, play, generation);
      }
    });
  }

  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) =>
      play(track, startAt: position ?? Duration.zero, play: false);

  @override
  Future<void> pause({String caller = 'user', bool failOnTimeout = false}) {
    final generation = _request(playing: false);
    return _serialize(() async {
      if (!_current(generation)) return;
      final session = _remote;
      if (session == null) {
        await _local.pause(caller: caller, failOnTimeout: failOnTimeout);
      } else if (session.loaded) {
        _requireOperation(session.capabilities.pause, 'Pause');
        await session.backend
            .pause(sessionId: session.sessionId, itemId: session.itemId)
            .timeout(operationTimeout);
      }
    });
  }

  @override
  Future<void> resume() {
    final generation = _request(playing: true);
    return _serialize(() async {
      if (!_current(generation)) return;
      final session = _remote;
      if (session == null) {
        await _local.resume();
      } else if (session.loaded) {
        _requireOperation(session.capabilities.play, 'Play');
        await session.backend
            .play(sessionId: session.sessionId, itemId: session.itemId)
            .timeout(operationTimeout);
      } else if (session.track != null) {
        await _loadRemote(
          session,
          session.track!,
          _status.position,
          true,
          generation,
        );
      }
    });
  }

  @override
  Future<void> stop() {
    final generation = _request(playing: false);
    return _serialize(() async {
      if (!_current(generation)) return;
      final session = _remote;
      if (session == null) {
        await _local.stop();
      } else {
        _requireOperation(session.capabilities.stop, 'Stop');
        session.loaded = false;
        await session.backend
            .stop(sessionId: session.sessionId, itemId: session.itemId)
            .timeout(operationTimeout);
        await session.lease?.release();
        session.lease = null;
        _setOutput(requiresSender: false);
        _publish(
          _remoteStatus(session, PlaybackState.idle, position: Duration.zero),
        );
      }
    });
  }

  void _requireOperation(bool supported, String operation) {
    if (supported) return;
    final error = NetworkOutputException(
      '$operation is not supported by this output.',
      code: 'unsupported_operation',
    );
    _setOutput(error: error.message);
    throw error;
  }

  @override
  Future<void> seekTo(Duration position) => _serialize(() async {
    final session = _remote;
    if (session == null) {
      await _local.seekTo(position);
    } else {
      _requireOperation(session.capabilities.seek && !_status.isLive, 'Seek');
      await session.backend
          .seek(position, sessionId: session.sessionId, itemId: session.itemId)
          .timeout(operationTimeout);
    }
  });

  @override
  Future<void> setVolume(double volume) => _serialize(() async {
    if (volume < 0 || volume > 1) throw ArgumentError.value(volume, 'volume');
    final session = _remote;
    if (session == null) {
      await _local.setVolume(volume);
    } else {
      _requireOperation(session.capabilities.volume, 'Volume');
      await session.backend
          .setVolume(
            volume,
            sessionId: session.sessionId,
            itemId: session.itemId,
          )
          .timeout(operationTimeout);
    }
  });

  Future<void> setMute(bool muted) => _serialize(() async {
    final session = _remote;
    if (session == null) {
      await _local.setVolume(muted ? 0 : _status.volume);
    } else {
      _requireOperation(session.capabilities.mute, 'Mute');
      await session.backend
          .setMute(muted, sessionId: session.sessionId, itemId: session.itemId)
          .timeout(operationTimeout);
    }
  });

  Future<void> _localSetting(Future<void> Function() command, String label) =>
      _serialize(() async {
        _requireOperation(_remote == null, label);
        await command();
      });

  @override
  Future<void> setSpeed(double speed) =>
      _localSetting(() => _local.setSpeed(speed), 'Playback speed');
  @override
  Future<void> setSubtitleTrack(String? uri) =>
      _localSetting(() => _local.setSubtitleTrack(uri), 'Subtitles');
  @override
  Future<void> setSubtitleDelay(Duration delay) =>
      _localSetting(() => _local.setSubtitleDelay(delay), 'Subtitle delay');
  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) => _localSetting(
    () => _local.setSubtitleAppearance(
      textSize: textSize,
      backgroundColor: backgroundColor,
    ),
    'Subtitle appearance',
  );
  @override
  Stream<PlaybackStatus> get statusStream => _statuses.stream;
  @override
  Stream<PlaybackEvent> get eventStream => _events.stream;
  @override
  PlaybackStatus get currentStatus => _status;
  @override
  dynamic get renderer => _local.renderer;
  @override
  YoutubePlayerController? get youtubeController => _local.youtubeController;
  @override
  bool get supportsSpeed => _remote == null && _local.supportsSpeed;
  @override
  bool get supportsTrackSelection =>
      _remote == null && _local.supportsTrackSelection;
  @override
  bool get supportsExternalSubtitles =>
      _remote == null && _local.supportsExternalSubtitles;
  @override
  bool get supportsSubtitleDelay =>
      _remote == null && _local.supportsSubtitleDelay;
  @override
  bool get supportsSubtitleTextSize =>
      _remote == null && _local.supportsSubtitleTextSize;
  @override
  bool get supportsSubtitleBackgroundStyling =>
      _remote == null && _local.supportsSubtitleBackgroundStyling;
  @override
  bool get supportsVideoFitMode =>
      _remote == null && _local.supportsVideoFitMode;

  @override
  Future<void> dispose() {
    if (_disposeFuture != null) return _disposeFuture!;
    _disposed = true;
    _requestedGeneration++;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _disposeFuture = _commands.then((_) async {
      final session = _remote;
      _remote = null;
      if (session != null) {
        try {
          await _cleanup(session, stopPlayback: true);
        } catch (_) {}
      }
      for (final backend in _backends.values) {
        try {
          await backend.dispose();
        } catch (_) {}
      }
      await _local.dispose();
      await _statuses.close();
      await _events.close();
      await _outputs.close();
    });
    return _disposeFuture!;
  }
}
