import 'models.dart';

/// Implementations must retain and echo these identities in every callback.
/// AirPlay system routing remains outside this remote-URI contract.
abstract interface class NetworkOutputBackend {
  OutputKind get kind;
  Stream<List<PlaybackOutput>> get outputs;
  Stream<NetworkOutputSessionState> get sessionState;

  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> connect(PlaybackOutput output, {required String sessionId});
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  });
  Future<RemoteLoadResult> load(
    NetworkMediaItem item, {
    required String sessionId,
    required String itemId,
    Duration position = Duration.zero,
    bool autoplay = true,
  });
  Future<void> play({required String sessionId, required String itemId});
  Future<void> pause({required String sessionId, required String itemId});
  Future<void> stop({required String sessionId, required String itemId});
  Future<void> seek(
    Duration position, {
    required String sessionId,
    required String itemId,
  });
  Future<void> setVolume(
    double volume, {
    required String sessionId,
    required String itemId,
  });
  Future<void> setMute(
    bool muted, {
    required String sessionId,
    required String itemId,
  });
  Future<void> dispose();
}
