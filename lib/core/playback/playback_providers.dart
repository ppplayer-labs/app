import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:path_provider/path_provider.dart';

import 'chromium_playback_engine.dart';
import 'chromium_media_service.dart';
import '../models/track.dart';
import 'hybrid_playback_engine.dart';
import 'local_file_playback_controller.dart';
import '../network_outputs/network_output_providers.dart';

export 'playback_service.dart' show playbackServiceProvider, PlaybackService;

export 'package:pp_playback_engine/pp_playback_engine.dart';

// Extension to convert App Track to PlaybackTrack
extension TrackToPlayback on Track {
  PlaybackTrack toPlaybackTrack({Map<String, String>? httpHeaders}) {
    if (sourceType == TrackSourceType.online) {
      if (youtubeVideoId == null) {
        throw StateError(
          'Cannot create PlaybackTrack: youtubeVideoId is null for online track',
        );
      }
      if (youtubeVideoId!.length != 11 || youtubeVideoId!.contains('http')) {
        throw StateError(
          'Cannot create PlaybackTrack: Invalid online source ID "$youtubeVideoId"',
        );
      }
    }

    PlaybackLiveStatus mapLiveStatus(StreamLiveStatus status) {
      switch (status) {
        case StreamLiveStatus.live:
          return PlaybackLiveStatus.live;
        case StreamLiveStatus.onDemand:
          return PlaybackLiveStatus.onDemand;
        case StreamLiveStatus.unknown:
          return PlaybackLiveStatus.unknown;
      }
    }

    PlaybackSourceType playbackSource;
    String finalId = spotifyId;

    switch (sourceType) {
      case TrackSourceType.local:
        playbackSource = PlaybackSourceType.local;
        break;
      case TrackSourceType.networkStream:
        playbackSource = PlaybackSourceType.networkStream;
        if (networkStreamUrl != null) {
          for (var exp in [
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?(?:.*&)?v=([_\-a-zA-Z0-9]{10,11})(?:&.*)?$",
            ),
            RegExp(
              r"^https:\/\/(?:music\.)?youtube\.com\/watch\?(?:.*&)?v=([_\-a-zA-Z0-9]{10,11})(?:&.*)?$",
            ),
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/([_\-a-zA-Z0-9]{10,11})(?:\?.*)?$",
            ),
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{10,11})(?:\?.*)?$",
            ),
            RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{10,11})(?:\?.*)?$"),
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube\.com\/playlist\?(?:.*&)?list=([_\-a-zA-Z0-9]+)(?:&.*)?$",
            ),
          ]) {
            final match = exp.firstMatch(networkStreamUrl!.trim());
            if (match != null && match.groupCount >= 1) {
              playbackSource = PlaybackSourceType.online;
              finalId = match.group(1)!;
              break;
            }
          }
        }
        break;
      case TrackSourceType.online:
        playbackSource = PlaybackSourceType.online;
        finalId = youtubeVideoId!;
        break;
    }

    return PlaybackTrack(
      id: finalId,
      title: name,
      artist: artistName,
      album: albumName,
      artworkUrl: albumImage,
      duration: durationMs != null ? Duration(milliseconds: durationMs!) : null,
      sourceType: playbackSource,
      // Preserve the durable locator. Local/remote acquisition resolves it
      // immediately before reading, without persisting a temporary resolved path.
      localMediaUri: localFilePath,
      networkMediaUri: networkStreamUrl,
      isVideo: isVideoFile,
      liveStatus: mapLiveStatus(liveStatus),
      httpHeaders: httpHeaders,
    );
  }
}

/// The primary local playback engine.
final localPlaybackControllerProvider = Provider<PlaybackController>((ref) {
  PlaybackController engine;
  const chromiumEnabled = bool.fromEnvironment(
    'PPPLAYER_CHROMIUM',
    defaultValue: true,
  );
  final chromiumAndroid =
      chromiumEnabled &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  if (defaultTargetPlatform == TargetPlatform.android) {
    engine = HybridPlaybackEngine(
      backgroundEngine: chromiumAndroid
          ? NativeServicePlaybackEngine(startAutomatically: false)
          : null,
    );
  } else {
    final mediaKit = MediaKitPlaybackEngine();
    engine =
        {
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)
        ? LocalFilePlaybackController(
            mediaKit,
            acquireFileLease: acquireAppleOutputFileLease,
          )
        : mediaKit;
  }

  if (chromiumEnabled &&
      !kIsWeb &&
      {
        TargetPlatform.windows,
        TargetPlatform.android,
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.iOS,
      }.contains(defaultTargetPlatform)) {
    engine = ChromiumPlaybackEngine(
      fallback: engine,
      showBrowser: !chromiumAndroid,
      startPlaybackService: chromiumAndroid ? ChromiumMediaService.start : null,
      stopPlaybackService: chromiumAndroid ? ChromiumMediaService.stop : null,
      initializeCef: () async {
        final directory = await getApplicationSupportDirectory();
        if (!await ChromiumWebViewController.initialize(
          cachePath: directory.path,
        )) {
          throw StateError('CEF initialization failed');
        }
      },
      createPlayer: () => ChromiumYoutubePlayerController(
        documentUrl: const String.fromEnvironment(
          'PPPLAYER_CHROMIUM_DOCUMENT_URL',
          defaultValue: 'https://ppplayer.com/chromium/player.html',
        ),
        profileName: 'ppplayer_youtube_session',
      ),
    );
  }
  ref.onDispose(() {
    engine.dispose();
  });

  return engine;
});

/// The primary playback controller used by the app. This wraps the local engine
/// with network capabilities.
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  return ref.watch(networkOutputControllerProvider);
});

/// A persistent GlobalKey to keep the Video surface alive across navigation changes.
/// This prevents the "surface destroyed" error on Android when switching tabs.
final videoSurfaceKeyProvider = Provider<GlobalKey>((ref) {
  return GlobalKey(debugLabel: 'ppplayer_persistent_video_surface');
});

/// A stream provider that exposes the current player status.
final playbackStatusProvider = StreamProvider<PlaybackStatus>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.statusStream;
});
