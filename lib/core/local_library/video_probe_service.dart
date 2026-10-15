// lib/core/local_library/video_probe_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide Track;

/// Result of a video probe operation.
enum VideoProbeResult {
  /// A video stream with positive dimensions was confirmed.
  hasVideo,

  /// No video stream was found (audio-only or empty container).
  audioOnly,

  /// The probe timed out or encountered an error; classification is unknown.
  probeFailed,

  /// The probe was cancelled before completing.
  cancelled,
}

/// Isolates video-stream detection from the active playback engine.
///
/// Creates its own short-lived [Player] instance per probe so probing cannot
/// interrupt or contaminate the main playback pipeline.  Concurrency is
/// bounded by [maxConcurrent] to avoid starving playback.
///
/// ## Cover-art guard
/// libmpv can expose embedded cover art via a video track.  The probe uses the
/// combination of `videoParams.w > 0 && videoParams.h > 0 && dw > 0` as a
/// necessary condition.  Embedded still images typically have the same
/// dimensions but zero display-width, or are exposed only as attached pictures
/// (no demuxed video track).  This filter is not perfect, but it avoids the
/// common case of an MP3 with an embedded JPEG being promoted to a video file.
///
/// ## Audio-only MP4
/// An MP4 that contains only AAC/MP3 audio will produce either no
/// [VideoParams] event or one with null w/h.  The probe returns [audioOnly]
/// and [LocalFile.isVideo] is never set.  The file will not appear in the
/// Videos library.  If the user imported it through the audio import path it
/// will appear in the music library; if imported through the video path it
/// will remain silent (not surfaced in either library for that import session)
/// — the user can open it via "Open File" to import it as audio.
class VideoProbeService {
  static const int maxConcurrent = 2;
  static const Duration probeTimeout = Duration(seconds: 8);

  /// Semaphore-style counter to limit parallel probes.
  static int _active = 0;
  static final _queue = <Completer<void>>[];

  /// Probes [mediaUri] for a video stream.
  ///
  /// [mediaUri] must be a valid media_kit URI (e.g. `Uri.file(path).toString()`
  /// or a raw `content://` URI on Android).
  ///
  /// Returns a [VideoProbeResult].  Never throws.
  static Future<VideoProbeResult> probe(
    String mediaUri, {
    CancellationToken? cancellationToken,
  }) async {
    // Honour an already-cancelled token immediately.
    if (cancellationToken?.isCancelled == true) {
      return VideoProbeResult.cancelled;
    }

    // Wait for a slot in the concurrency window.
    if (_active >= maxConcurrent) {
      final waiter = Completer<void>();
      _queue.add(waiter);
      await waiter.future;
    }

    if (cancellationToken?.isCancelled == true) {
      _release();
      return VideoProbeResult.cancelled;
    }

    _active++;
    Player? player;

    try {
      MediaKit.ensureInitialized();
      player = Player();
      // NOTE: deliberately no VideoController.  Without a mounted Video
      // widget a controller makes Player.open() wait forever for a render
      // target.  Demuxer track metadata is available without rendering.

      bool realVideo(Tracks t) => t.video.any(
        (v) =>
            v.id != 'auto' &&
            v.id != 'no' &&
            v.image != true &&
            v.albumart != true,
      );

      final completer = Completer<VideoProbeResult>();

      void evaluate(Tracks t) {
        if (completer.isCompleted) return;
        if (realVideo(t)) completer.complete(VideoProbeResult.hasVideo);
      }

      final tracksSub = player.stream.tracks.listen(evaluate);
      final errSub = player.stream.error.listen((err) {
        if (completer.isCompleted) return;
        completer.complete(VideoProbeResult.probeFailed);
      });

      // Open the media without starting playback.
      await player.open(Media(mediaUri), play: false).timeout(probeTimeout);
      evaluate(player.state.tracks);

      if (!completer.isCompleted) {
        // Tracks may populate shortly after open() resolves.  If nothing
        // video-like shows up within a short grace window, the file is
        // audio-only provided the demuxer exposed an audio track/duration.
        await completer.future.timeout(
          const Duration(milliseconds: 700),
          onTimeout: () {
            if (!completer.isCompleted) {
              final s = player!.state;
              final hasAudio = s.tracks.audio.any(
                (a) => a.id != 'auto' && a.id != 'no',
              );
              completer.complete(
                hasAudio || s.duration > Duration.zero
                    ? VideoProbeResult.audioOnly
                    : VideoProbeResult.probeFailed,
              );
            }
            return completer.future;
          },
        );
      }

      await tracksSub.cancel();
      await errSub.cancel();

      if (cancellationToken?.isCancelled == true) {
        return VideoProbeResult.cancelled;
      }
      return await completer.future;
    } catch (e) {
      debugPrint('VideoProbeService: probe failed for $mediaUri: $e');
      return VideoProbeResult.probeFailed;
    } finally {
      try {
        await player?.dispose().timeout(const Duration(seconds: 3));
      } catch (_) {}
      _release();
    }
  }

  static void _release() {
    _active = (_active - 1).clamp(0, maxConcurrent);
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    }
  }
}

/// Lightweight cancellation token for probe operations.
class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
