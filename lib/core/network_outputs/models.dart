import 'dart:async';

import 'package:pp_playback_engine/pp_playback_engine.dart';

enum OutputKind { local, airPlay, googleCast, dlna, roon }

class OutputCapabilities {
  const OutputCapabilities({
    this.audio = false,
    this.video = false,
    this.play = true,
    this.pause = false,
    this.stop = true,
    this.seek = false,
    this.volume = false,
    this.mute = false,
    this.queue = false,
    this.subtitles = false,
    this.live = false,
    this.disconnectWithoutStop = true,
    this.mimeTypes = const {},
    this.sinkProtocolInfos = const [],
  });

  final bool audio;
  final bool video;
  final bool play;
  final bool pause;
  final bool stop;
  final bool seek;
  final bool volume;
  final bool mute;
  final bool queue;
  final bool subtitles;
  final bool live;
  final bool disconnectWithoutStop;
  final Set<String> mimeTypes;
  final List<String> sinkProtocolInfos;

  bool supportsMimeType(String mimeType) {
    final candidate = mimeType.toLowerCase().split(';').first.trim();
    bool matches(String supported) {
      final normalized = supported.toLowerCase().split(';').first.trim();
      return normalized == '*' ||
          normalized == '*/*' ||
          normalized == candidate ||
          (normalized.endsWith('/*') &&
              candidate.startsWith(
                normalized.substring(0, normalized.length - 1),
              ));
    }

    return mimeTypes.any(matches) ||
        sinkProtocolInfos.any((protocol) {
          final parts = protocol.split(':');
          return parts.length >= 3 && matches(parts[2]);
        });
  }
}

class PlaybackOutput {
  const PlaybackOutput({
    required this.id,
    required this.name,
    required this.kind,
    required this.capabilities,
    this.isAvailable = true,
    this.endpointUri,
    this.manufacturer,
    this.model,
    this.metadata = const {},
  });

  static const local = PlaybackOutput(
    id: 'local',
    name: 'This device',
    kind: OutputKind.local,
    capabilities: OutputCapabilities(
      audio: true,
      video: true,
      pause: true,
      seek: true,
      volume: true,
      mute: true,
      queue: true,
      subtitles: true,
      live: true,
      mimeTypes: {'*/*'},
    ),
  );

  final String id;
  final String name;
  final OutputKind kind;
  final bool isAvailable;
  final OutputCapabilities capabilities;
  final Uri? endpointUri;
  final String? manufacturer;
  final String? model;
  final Map<String, Object?> metadata;

  String get identity => '${kind.name}:$id';
}

class NetworkMediaItem {
  const NetworkMediaItem({
    required this.uri,
    required this.mimeType,
    required this.title,
    this.artist,
    this.album,
    this.artworkUri,
    this.duration,
    this.protocolInfo,
    this.isVideo = false,
    this.isLive = false,
  });

  final Uri uri;
  final String mimeType;
  final String title;
  final String? artist;
  final String? album;
  final Uri? artworkUri;
  final Duration? duration;
  final String? protocolInfo;
  final bool isVideo;
  final bool isLive;
}

/// The factory owns source access and temporary LAN URLs, never the backend.
class NetworkMediaLease {
  NetworkMediaLease({
    required this.item,
    required this._release,
    this.requiresSender = false,
  });

  final NetworkMediaItem item;
  final bool requiresSender;
  final Future<void> Function() _release;
  Future<void>? _releaseFuture;

  Future<void> release() => _releaseFuture ??= Future.sync(_release);
}

abstract interface class NetworkMediaFactory {
  Future<NetworkMediaLease> prepare(
    PlaybackTrack track,
    PlaybackOutput output, {
    required String sessionId,
    required String itemId,
  });
}

/// All three identities are required, including idle/disconnection events.
class NetworkOutputSessionState {
  const NetworkOutputSessionState({
    required this.endpointId,
    required this.sessionId,
    required this.itemId,
    required this.state,
    this.connected = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1,
    this.muted = false,
    this.isLive = false,
    this.error,
    this.capabilities,
  });

  final String endpointId;
  final String sessionId;
  final String itemId;
  final PlaybackState state;
  final bool connected;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool muted;
  final bool isLive;
  final String? error;
  final OutputCapabilities? capabilities;
}

class RemoteLoadResult {
  const RemoteLoadResult({
    required this.success,
    this.error,
    this.position,
    this.duration,
    this.capabilities,
  });

  final bool success;
  final String? error;
  final Duration? position;
  final Duration? duration;
  final OutputCapabilities? capabilities;
}

class OutputSupportResult {
  const OutputSupportResult.supported() : supported = true, reason = null;
  const OutputSupportResult.unsupported(this.reason) : supported = false;

  final bool supported;
  final String? reason;
}

class NetworkOutputState {
  const NetworkOutputState({
    this.selectedOutput = PlaybackOutput.local,
    this.availableOutputs = const [],
    this.discoveryActive = false,
    this.connecting = false,
    this.connected = false,
    this.remoteActive = false,
    this.connectingOutput,
    this.session,
    this.generation = 0,
    this.requiresSender = false,
    this.error,
  });

  final PlaybackOutput selectedOutput;
  final List<PlaybackOutput> availableOutputs;
  final bool discoveryActive;
  final bool connecting;
  final bool connected;
  final bool remoteActive;
  final PlaybackOutput? connectingOutput;
  final NetworkOutputSessionState? session;
  final int generation;
  final bool requiresSender;
  final String? error;

  Duration get remotePosition => session?.position ?? Duration.zero;
  Duration get remoteDuration => session?.duration ?? Duration.zero;
  double get remoteVolume => session?.volume ?? 1;
  PlaybackState get remotePlaybackState => session?.state ?? PlaybackState.idle;
  OutputCapabilities get capabilities =>
      session?.capabilities ?? selectedOutput.capabilities;
  String? get sessionId => session?.sessionId;
  bool get canDisconnectWithoutStop =>
      capabilities.disconnectWithoutStop && !requiresSender;
}

class NetworkOutputException implements Exception {
  const NetworkOutputException(this.message, {this.code = 'output_operation'});

  final String message;
  final String code;

  @override
  String toString() => message;
}
