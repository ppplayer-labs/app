import 'package:pp_playback_engine/pp_playback_engine.dart';

import 'models.dart';

class OutputCapabilityResolver {
  const OutputCapabilityResolver();

  OutputSupportResult sourceSupport(
    PlaybackTrack track,
    PlaybackOutput output,
  ) {
    if (output.kind == OutputKind.local) {
      return const OutputSupportResult.supported();
    }
    if (!output.isAvailable) {
      return const OutputSupportResult.unsupported(
        'This output is unavailable.',
      );
    }
    if (output.kind == OutputKind.airPlay) {
      return const OutputSupportResult.unsupported(
        'Use the AirPlay system picker for a verified local playback route.',
      );
    }
    if (track.sourceType == PlaybackSourceType.online) {
      return const OutputSupportResult.unsupported(
        "This source can't currently be played on this output.",
      );
    }
    if (track.isVideo
        ? !output.capabilities.video
        : !output.capabilities.audio) {
      return const OutputSupportResult.unsupported(
        'This output does not support this media type.',
      );
    }
    if (track.liveStatus == PlaybackLiveStatus.live &&
        !output.capabilities.live) {
      return const OutputSupportResult.unsupported(
        'This output does not support live streams.',
      );
    }
    return const OutputSupportResult.supported();
  }

  OutputSupportResult resolve(
    PlaybackTrack track,
    PlaybackOutput output, {
    NetworkMediaItem? item,
  }) {
    final source = sourceSupport(track, output);
    if (!source.supported || output.kind == OutputKind.local) return source;
    final mimeType = item?.mimeType ?? mimeTypeForTrack(track);
    if (mimeType == null || !output.capabilities.supportsMimeType(mimeType)) {
      return const OutputSupportResult.unsupported(
        'This output has not advertised support for this media format.',
      );
    }
    if (item != null &&
        (item.uri.scheme != 'http' && item.uri.scheme != 'https')) {
      return const OutputSupportResult.unsupported(
        'The output needs a reachable HTTP or HTTPS media address.',
      );
    }
    return const OutputSupportResult.supported();
  }

  static String? mimeTypeForTrack(PlaybackTrack track) {
    final raw = track.isLocal ? track.localMediaUri : track.networkMediaUri;
    if (raw == null) return null;
    return mimeTypeForUri(Uri.tryParse(raw));
  }

  static String? mimeTypeForUri(Uri? uri) {
    final path = uri?.path.toLowerCase();
    if (path == null) return null;
    final extension = path.split('.').last;
    return const {
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'opus': 'audio/ogg',
      'mp4': 'video/mp4',
      'm4v': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'mkv': 'video/x-matroska',
      'm3u8': 'application/vnd.apple.mpegurl',
      'mpd': 'application/dash+xml',
    }[extension];
  }
}
