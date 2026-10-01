import 'dart:async';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../network_outputs/local_media_server.dart';
import '../network_outputs/network_media_factory.dart';

/// Resolves durable Apple locators only when the local engine needs file access.
/// Status retains the original locator for persisted queues and remote handoff.
class LocalFilePlaybackController implements PlaybackController {
  LocalFilePlaybackController(
    this._engine, {
    required AcquireOutputFileLease acquireFileLease,
  }) : _acquire = acquireFileLease;
  final PlaybackController _engine;
  final AcquireOutputFileLease _acquire;
  AuthorizedFileLease? _file;
  PlaybackTrack? _original;
  Future<void> _commands = Future.value();
  bool _disposed = false;

  Future<void> _enqueue(Future<void> Function() command) {
    final next = _commands.then((_) => command());
    _commands = next.then((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  PlaybackStatus _restore(PlaybackStatus status) =>
      _original != null && status.track?.id == _original!.id
      ? status.copyWith(track: _original)
      : status;
  @override
  Stream<PlaybackStatus> get statusStream => _engine.statusStream.map(_restore);
  @override
  Stream<PlaybackEvent> get eventStream => _engine.eventStream;
  @override
  PlaybackStatus get currentStatus => _restore(_engine.currentStatus);

  Future<void> _open(
    PlaybackTrack track,
    Future<void> Function(PlaybackTrack) open,
  ) => _enqueue(() async {
    if (_disposed) throw StateError('Playback controller is disposed');
    final next = track.isLocal ? await _acquire(track) : null;
    try {
      await _engine.stop();
      await _file?.release();
      _file = null;
      _original = track;
      final resolved = next == null
          ? track
          : PlaybackTrack(
              id: track.id,
              title: track.title,
              artist: track.artist,
              album: track.album,
              artworkUrl: track.artworkUrl,
              duration: track.duration,
              sourceType: track.sourceType,
              localMediaUri: Uri.file(next.canonicalPath).toString(),
              networkMediaUri: track.networkMediaUri,
              isVideo: track.isVideo,
              liveStatus: track.liveStatus,
              httpHeaders: track.httpHeaders,
            );
      _file = next;
      await open(resolved);
    } catch (_) {
      // Close the reader before releasing security-scoped access.
      await _engine.stop();
      await next?.release();
      if (identical(_file, next)) _file = null;
      rethrow;
    }
  });

  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) => _open(
    track,
    (resolved) => _engine.play(resolved, startAt: startAt, play: play),
  );
  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) =>
      _open(track, (resolved) => _engine.prepare(resolved, position: position));
  @override
  Future<void> stop() => _enqueue(() async {
    await _engine.stop();
    await _file?.release();
    _file = null;
  });
  @override
  Future<void> dispose() => _enqueue(() async {
    if (_disposed) return;
    _disposed = true;
    await _engine.dispose();
    await _file?.release();
    _file = null;
  });
  @override
  Future<void> pause({String caller = 'user', bool failOnTimeout = false}) =>
      _engine.pause(caller: caller, failOnTimeout: failOnTimeout);
  @override
  Future<void> resume() => _engine.resume();
  @override
  Future<void> seekTo(Duration position) => _engine.seekTo(position);
  @override
  Future<void> setVolume(double volume) => _engine.setVolume(volume);
  @override
  Future<void> setSpeed(double speed) => _engine.setSpeed(speed);
  @override
  Future<void> setSubtitleTrack(String? uri) => _engine.setSubtitleTrack(uri);
  @override
  Future<void> setSubtitleDelay(Duration delay) =>
      _engine.setSubtitleDelay(delay);
  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) => _engine.setSubtitleAppearance(
    textSize: textSize,
    backgroundColor: backgroundColor,
  );
  @override
  bool get supportsSpeed => _engine.supportsSpeed;
  @override
  bool get supportsTrackSelection => _engine.supportsTrackSelection;
  @override
  bool get supportsExternalSubtitles => _engine.supportsExternalSubtitles;
  @override
  bool get supportsSubtitleDelay => _engine.supportsSubtitleDelay;
  @override
  bool get supportsSubtitleTextSize => _engine.supportsSubtitleTextSize;
  @override
  bool get supportsSubtitleBackgroundStyling =>
      _engine.supportsSubtitleBackgroundStyling;
  @override
  bool get supportsVideoFitMode => _engine.supportsVideoFitMode;
  @override
  dynamic get renderer => _engine.renderer;
  @override
  YoutubePlayerController? get youtubeController => _engine.youtubeController;
}
