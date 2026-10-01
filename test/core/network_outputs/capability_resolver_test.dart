import 'package:flutter_test/flutter_test.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/network_outputs/capability_resolver.dart';
import 'package:ppplayer/core/network_outputs/models.dart';

// ──────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────

const _resolver = OutputCapabilityResolver();

PlaybackOutput makeOutput({
  String id = 'dev-1',
  OutputKind kind = OutputKind.dlna,
  bool isAvailable = true,
  bool audio = true,
  bool video = false,
  bool live = false,
  Set<String> mimeTypes = const {'audio/mpeg', 'audio/mp4', 'audio/flac'},
  List<String> sinkProtocolInfos = const [],
}) => PlaybackOutput(
  id: id,
  name: 'Test Output',
  kind: kind,
  isAvailable: isAvailable,
  capabilities: OutputCapabilities(
    audio: audio,
    video: video,
    live: live,
    mimeTypes: mimeTypes,
    sinkProtocolInfos: sinkProtocolInfos,
  ),
  endpointUri: Uri.parse('http://192.168.1.1:1234/desc.xml'),
);

PlaybackTrack makeAudioTrack({
  PlaybackSourceType sourceType = PlaybackSourceType.local,
  String? uri,
  PlaybackLiveStatus liveStatus = PlaybackLiveStatus.onDemand,
  bool isVideo = false,
}) => PlaybackTrack(
  id: 'track-1',
  title: 'Test Song',
  sourceType: sourceType,
  localMediaUri: sourceType == PlaybackSourceType.local
      ? (uri ?? 'file:///music/song.mp3')
      : null,
  networkMediaUri: sourceType != PlaybackSourceType.local
      ? (uri ?? 'http://example.com/song.mp3')
      : null,
  liveStatus: liveStatus,
  isVideo: isVideo,
);

NetworkMediaItem makeItem({
  String mimeType = 'audio/mpeg',
  String url = 'http://192.168.1.1:8080/media/token',
}) => NetworkMediaItem(
  uri: Uri.parse(url),
  mimeType: mimeType,
  title: 'Test',
  isVideo: false,
);

// ──────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────

void main() {
  // ── sourceSupport ────────────────────────────────────────────────────────
  group('OutputCapabilityResolver.sourceSupport', () {
    test('local output always supported', () {
      final result = _resolver.sourceSupport(
        makeAudioTrack(),
        PlaybackOutput.local,
      );
      expect(result.supported, isTrue);
    });

    test('unavailable output is unsupported', () {
      final out = makeOutput(isAvailable: false);
      final result = _resolver.sourceSupport(makeAudioTrack(), out);
      expect(result.supported, isFalse);
    });

    test('AirPlay output is always unsupported (system route)', () {
      final out = makeOutput(kind: OutputKind.airPlay);
      final result = _resolver.sourceSupport(makeAudioTrack(), out);
      expect(result.supported, isFalse);
      expect(result.reason, isNotNull);
    });

    test('online source is unsupported on any remote output', () {
      final out = makeOutput();
      final result = _resolver.sourceSupport(
        makeAudioTrack(sourceType: PlaybackSourceType.online),
        out,
      );
      expect(result.supported, isFalse);
    });

    test('video track unsupported on audio-only output', () {
      final out = makeOutput(audio: true, video: false);
      final result = _resolver.sourceSupport(
        makeAudioTrack(isVideo: true),
        out,
      );
      expect(result.supported, isFalse);
    });

    test('audio track unsupported on video-only output', () {
      final out = makeOutput(
        audio: false,
        video: true,
        mimeTypes: {'video/mp4'},
      );
      final result = _resolver.sourceSupport(makeAudioTrack(), out);
      expect(result.supported, isFalse);
    });

    test('live stream unsupported on output without live flag', () {
      final out = makeOutput(live: false);
      final result = _resolver.sourceSupport(
        makeAudioTrack(liveStatus: PlaybackLiveStatus.live),
        out,
      );
      expect(result.supported, isFalse);
    });

    test('live stream supported on output with live flag', () {
      final out = makeOutput(live: true);
      final result = _resolver.sourceSupport(
        makeAudioTrack(liveStatus: PlaybackLiveStatus.live),
        out,
      );
      expect(result.supported, isTrue);
    });

    test('local audio track supported on capable DLNA output', () {
      final out = makeOutput();
      final result = _resolver.sourceSupport(makeAudioTrack(), out);
      expect(result.supported, isTrue);
    });
  });

  // ── resolve ──────────────────────────────────────────────────────────────
  group('OutputCapabilityResolver.resolve', () {
    test('local output is always supported (bypasses MIME check)', () {
      final result = _resolver.resolve(makeAudioTrack(), PlaybackOutput.local);
      expect(result.supported, isTrue);
    });

    test('known MIME type supported by output → supported', () {
      final out = makeOutput(mimeTypes: {'audio/mpeg', 'audio/mp4'});
      final track = makeAudioTrack(uri: 'file:///music/song.mp3');
      final item = makeItem(mimeType: 'audio/mpeg');
      final result = _resolver.resolve(track, out, item: item);
      expect(result.supported, isTrue);
    });

    test('MIME type not in output caps → unsupported', () {
      final out = makeOutput(mimeTypes: {'video/mp4'});
      final item = makeItem(mimeType: 'audio/mpeg');
      final result = _resolver.resolve(makeAudioTrack(), out, item: item);
      expect(result.supported, isFalse);
    });

    test('wildcard * MIME in output accepts any type', () {
      final out = makeOutput(mimeTypes: {'*'});
      final item = makeItem(mimeType: 'audio/flac');
      final result = _resolver.resolve(makeAudioTrack(), out, item: item);
      expect(result.supported, isTrue);
    });

    test('wildcard */* MIME in output accepts any type', () {
      final item = makeItem(mimeType: 'video/webm');
      final result = _resolver.resolve(
        makeAudioTrack(isVideo: true),
        makeOutput(audio: true, video: true, mimeTypes: {'*/*'}),
        item: item,
      );
      expect(result.supported, isTrue);
    });

    test('audio/* MIME wildcard matches audio/mpeg', () {
      final out = makeOutput(mimeTypes: {'audio/*'});
      final item = makeItem(mimeType: 'audio/mpeg');
      final result = _resolver.resolve(makeAudioTrack(), out, item: item);
      expect(result.supported, isTrue);
    });

    test('audio/* MIME wildcard does not match video/mp4', () {
      final item = makeItem(mimeType: 'video/mp4');
      final result = _resolver.resolve(
        makeAudioTrack(isVideo: true),
        makeOutput(audio: true, video: true, mimeTypes: {'audio/*'}),
        item: item,
      );
      expect(result.supported, isFalse);
    });

    test('MIME matched via sinkProtocolInfos', () {
      final out = makeOutput(
        mimeTypes: {},
        sinkProtocolInfos: ['http-get:*:audio/mpeg:*'],
      );
      final item = makeItem(mimeType: 'audio/mpeg');
      final result = _resolver.resolve(makeAudioTrack(), out, item: item);
      expect(result.supported, isTrue);
    });

    test('non-HTTP item URI → unsupported', () {
      final out = makeOutput(mimeTypes: {'audio/mpeg'});
      final item = makeItem(
        mimeType: 'audio/mpeg',
        url: 'ftp://server/file.mp3',
      );
      final result = _resolver.resolve(makeAudioTrack(), out, item: item);
      expect(result.supported, isFalse);
    });

    test('HTTPS item URI is accepted', () {
      final out = makeOutput(mimeTypes: {'audio/mpeg'});
      final item = makeItem(
        mimeType: 'audio/mpeg',
        url: 'https://cdn.example.com/song.mp3',
      );
      final result = _resolver.resolve(makeAudioTrack(), out, item: item);
      expect(result.supported, isTrue);
    });

    test('online source rejected before MIME check', () {
      final out = makeOutput(mimeTypes: {'audio/mpeg'});
      final track = makeAudioTrack(sourceType: PlaybackSourceType.online);
      final item = makeItem(mimeType: 'audio/mpeg');
      final result = _resolver.resolve(track, out, item: item);
      expect(result.supported, isFalse);
    });
  });

  // ── mimeTypeForTrack ─────────────────────────────────────────────────────
  group('OutputCapabilityResolver.mimeTypeForTrack', () {
    test('mp3 → audio/mpeg', () {
      final track = makeAudioTrack(uri: 'file:///music/song.mp3');
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), 'audio/mpeg');
    });

    test('m4a → audio/mp4', () {
      final track = makeAudioTrack(uri: 'file:///music/track.m4a');
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), 'audio/mp4');
    });

    test('flac → audio/flac', () {
      final track = makeAudioTrack(uri: 'file:///music/track.flac');
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), 'audio/flac');
    });

    test('wav → audio/wav', () {
      final track = makeAudioTrack(uri: 'file:///music/track.wav');
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), 'audio/wav');
    });

    test('ogg → audio/ogg', () {
      final track = makeAudioTrack(uri: 'file:///music/track.ogg');
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), 'audio/ogg');
    });

    test('mp4 → video/mp4', () {
      final track = makeAudioTrack(
        uri: 'file:///video/clip.mp4',
        isVideo: true,
      );
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), 'video/mp4');
    });

    test('mkv → video/x-matroska', () {
      final track = makeAudioTrack(
        uri: 'file:///video/clip.mkv',
        isVideo: true,
      );
      expect(
        OutputCapabilityResolver.mimeTypeForTrack(track),
        'video/x-matroska',
      );
    });

    test('m3u8 → application/vnd.apple.mpegurl', () {
      final track = makeAudioTrack(
        sourceType: PlaybackSourceType.networkStream,
        uri: 'http://stream.example.com/live.m3u8',
      );
      expect(
        OutputCapabilityResolver.mimeTypeForTrack(track),
        'application/vnd.apple.mpegurl',
      );
    });

    test('unknown extension → null', () {
      final track = makeAudioTrack(uri: 'file:///music/track.xyz');
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), isNull);
    });

    test('track with null URI → null', () {
      final track = const PlaybackTrack(
        id: 't',
        title: 'T',
        sourceType: PlaybackSourceType.online,
      );
      expect(OutputCapabilityResolver.mimeTypeForTrack(track), isNull);
    });
  });

  // ── OutputCapabilities.supportsMimeType ──────────────────────────────────
  group('OutputCapabilities.supportsMimeType', () {
    test('exact match', () {
      final caps = const OutputCapabilities(mimeTypes: {'audio/mpeg'});
      expect(caps.supportsMimeType('audio/mpeg'), isTrue);
    });

    test('case insensitive', () {
      final caps = const OutputCapabilities(mimeTypes: {'AUDIO/MPEG'});
      expect(caps.supportsMimeType('audio/mpeg'), isTrue);
    });

    test('semicolon parameters stripped before compare', () {
      final caps = const OutputCapabilities(mimeTypes: {'audio/mpeg'});
      expect(caps.supportsMimeType('audio/mpeg; charset=utf-8'), isTrue);
    });

    test('wildcard /* in supported matches subtype', () {
      final caps = const OutputCapabilities(mimeTypes: {'audio/*'});
      expect(caps.supportsMimeType('audio/flac'), isTrue);
    });

    test('sinkProtocolInfo MIME extracted and matched', () {
      final caps = const OutputCapabilities(
        sinkProtocolInfos: ['http-get:*:audio/mpeg:DLNA.ORG_PN=MP3'],
      );
      expect(caps.supportsMimeType('audio/mpeg'), isTrue);
    });

    test('no match returns false', () {
      final caps = const OutputCapabilities(mimeTypes: {'audio/mpeg'});
      expect(caps.supportsMimeType('video/mp4'), isFalse);
    });
  });
}
