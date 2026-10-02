import 'dart:io';
import 'package:windows_taskbar/windows_taskbar.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../player/player_provider.dart';
import '../services/favorites_provider.dart';

/// An [AudioHandler] that bridges the Flutter player state with the system media controls.
/// It doesn't play audio itself (the WebView does), but it reports the state to the OS.
class PpPlayerAudioHandler extends BaseAudioHandler with QueueHandler {
  static const _iosControlsChannel = MethodChannel(
    'com.ppplayer.app/ios_media_controls',
  );
  PpPlayerAudioHandler(this._containerProvider, {bool? enableIosCommands}) {
    _iosCommandsEnabled = enableIosCommands ?? (!kIsWeb && Platform.isIOS);
    if (_iosCommandsEnabled) {
      _iosControlsChannel.setMethodCallHandler((call) async {
        final source = call.arguments is Map
            ? (call.arguments as Map)['source'] ?? 'native'
            : 'native';
        debugPrint(
          '[MediaControls] iOS remote command=${call.method} source=$source',
        );
        switch (call.method) {
          case 'pause':
            await pause();
          case 'play':
            await play();
          case 'togglePlayPause':
            final player = _container.read(playerProvider);
            if (player.isPlaying) {
              await pause();
            } else {
              await play();
            }
          case 'next':
            await skipToNext();
          case 'previous':
            await skipToPrevious();
          case 'seek':
            final arguments = call.arguments as Map;
            await seek(
              Duration(milliseconds: (arguments['positionMs'] as num).round()),
            );
          default:
            throw MissingPluginException(
              'Unknown iOS media command: ${call.method}',
            );
        }
      });
    }
    // Initial state: stopped
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  final ProviderContainer Function() _containerProvider;
  late final bool _iosCommandsEnabled;
  ProviderContainer get _container => _containerProvider();

  Future<void> _publishIosNowPlaying() async {
    if (!_iosCommandsEnabled) return;
    try {
      if (playbackState.value.playing) await _ensureAudioSessionActive();
      final item = mediaItem.value;
      final state = playbackState.value;
      await _iosControlsChannel.invokeMethod('updateNowPlaying', {
        'id': item?.id,
        'title': item?.title,
        'artist': item?.artist,
        'album': item?.album,
        'durationMs': item?.duration?.inMilliseconds,
        'artCacheFile': item?.extras?['artCacheFile'],
        'playing': state.playing,
        'positionMs': state.updatePosition.inMilliseconds,
        'speed': state.speed,
      });
    } catch (error) {
      debugPrint('[MediaControls] iOS Now Playing update failed: $error');
    }
  }

  String? _lastTrackId;
  ProviderSubscription<AsyncValue<bool>>? _favoriteSub;
  bool _audioSessionActivated = false;

  /// Activates the iOS AVAudioSession before playback starts.
  /// This is deferred from app launch to avoid blocking the main thread.
  Future<void> _ensureAudioSessionActive() async {
    if (_audioSessionActivated) return;
    if (!kIsWeb && Platform.isIOS) {
      _audioSessionActivated = true;
      try {
        await _iosControlsChannel.invokeMethod('activateAudioSession');
      } catch (_) {
        // Non-fatal — playback will still proceed; session may already be active.
      }
    }
  }

  void _updateTaskbar(bool isFav, {bool? playing}) {
    if (kIsWeb ||
        !Platform.isWindows ||
        Platform.environment.containsKey('FLUTTER_TEST'))
      return;

    final playerState = _container.read(playerProvider);
    final isPlaying = playing ?? playerState.isPlaying;

    WindowsTaskbar.setThumbnailToolbar([
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon(
          isFav ? 'assets/icons/remove.ico' : 'assets/icons/add.ico',
        ),
        isFav ? 'Remove from library' : 'Add to library',
        () async {
          final currentTrack = _container.read(playerProvider).currentTrack;
          if (currentTrack != null) {
            final currentFav =
                _container
                    .read(
                      favoritesStatusProvider((
                        FavoriteType.track,
                        currentTrack.spotifyId,
                      )),
                    )
                    .value ??
                currentTrack.isFavorite;
            await _container
                .read(favoritesControllerProvider.notifier)
                .toggleTrackFavorite(currentTrack, currentFav);
          }
        },
      ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/icons/previous.ico'),
        'Previous',
        () => skipToPrevious(),
      ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon(
          isPlaying ? 'assets/icons/pause.ico' : 'assets/icons/play.ico',
        ),
        isPlaying ? 'Pause' : 'Play',
        () => isPlaying ? pause() : play(),
      ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/icons/next.ico'),
        'Next',
        () => skipToNext(),
      ),
    ]);
  }

  /// Update the OS metadata (Title, Artist, Album, Image).
  void updateMetadata({
    required String id,
    required String title,
    required String artist,
    String? album,
    String? artUri,
    String? artCacheFile,
    Duration? duration,
  }) {
    mediaItem.add(
      MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        displayTitle: title,
        displaySubtitle: artist,
        artUri: (artUri != null && artUri.isNotEmpty)
            ? Uri.parse(artUri)
            : null,
        duration: duration,
        extras: (artCacheFile != null && artCacheFile.isNotEmpty)
            ? {'artCacheFile': artCacheFile}
            : null,
      ),
    );
    _publishIosNowPlaying();
  }

  /// Update the OS playback state (Playing, Paused, Position).
  void updatePlaybackState({
    required bool playing,
    required Duration position,
    required Duration bufferedPosition,
    double speed = 1.0,
    AudioProcessingState processingState = AudioProcessingState.ready,
  }) {
    debugPrint(
      '${DateTime.now().toIso8601String()} AUDIO_HANDLER publish playing=$playing position=$position',
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: speed,
      ),
    );

    _publishIosNowPlaying();

    final track = _container.read(playerProvider).currentTrack;
    if (track?.spotifyId != _lastTrackId) {
      _lastTrackId = track?.spotifyId;
      _favoriteSub?.close();
      if (track != null) {
        _favoriteSub = _container.listen<AsyncValue<bool>>(
          favoritesStatusProvider((FavoriteType.track, track.spotifyId)),
          (prev, next) {
            _updateTaskbar(
              next.value ?? track.isFavorite,
              playing: playbackState.value.playing,
            );
          },
          fireImmediately: true,
        );
      } else {
        _updateTaskbar(false, playing: playing);
      }
    } else {
      bool isFav = false;
      if (track != null) {
        isFav =
            _container
                .read(
                  favoritesStatusProvider((
                    FavoriteType.track,
                    track.spotifyId,
                  )),
                )
                .value ??
            track.isFavorite;
      }
      _updateTaskbar(isFav, playing: playing);
    }
  }

  // --- Remote Command Handlers ---

  @override
  Future<void> play() async {
    await _ensureAudioSessionActive();
    _container.read(playerProvider.notifier).resume();
  }

  @override
  Future<void> pause() async {
    _container.read(playerProvider.notifier).pause();
  }

  @override
  Future<void> skipToNext() async {
    _container.read(playerProvider.notifier).skipNext();
  }

  @override
  Future<void> skipToPrevious() async {
    _container.read(playerProvider.notifier).skipPrevious();
  }

  @override
  Future<void> seek(Duration position) async {
    _container.read(playerProvider.notifier).seekTo(position);
  }

  @override
  Future<void> stop() async {
    _container.read(playerProvider.notifier).pause();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
    await super.stop();
  }
}

/// Provider for the AudioHandler.
final audioHandlerProvider = Provider<PpPlayerAudioHandler>((ref) {
  throw UnimplementedError('AudioHandler must be initialized in main()');
});
