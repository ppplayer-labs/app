import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'package:media_kit_video/media_kit_video.dart' show Video;
import 'package:pp_playback_engine/pp_playback_engine.dart'
    show MediaKitPlayerAdapter;

// Separate validation entry point: the regular app entry point is unchanged.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MaterialApp(home: NativeReleaseProbe()));
}

class NativeReleaseProbe extends StatefulWidget {
  const NativeReleaseProbe({super.key});

  @override
  State<NativeReleaseProbe> createState() => _NativeReleaseProbeState();
}

class _NativeReleaseProbeState extends State<NativeReleaseProbe> {
  final _player = MediaKitPlayerAdapter();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _errors = <String>[];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  int _width = 0;
  int _height = 0;
  bool _showVideo = true;
  String _status = 'Preparing playback check';

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _player.positionStream.listen((value) => _position = value),
      _player.durationStream.listen((value) => _duration = value),
      _player.playingStream.listen((value) => _playing = value),
      _player.errorStream.listen(_errors.add),
      _player.videoParamsStream.listen((value) {
        _width = value.w ?? 0;
        _height = value.h ?? 0;
      }),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  Future<void> _wait(bool Function() condition, String check) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (!condition()) {
      if (_errors.isNotEmpty) throw StateError('Native errors: $_errors');
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('$check; position=$_position playing=$_playing');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  void _require(bool condition, String message) {
    // Dart assertions are disabled in release builds; these checks must throw.
    if (!condition) throw StateError(message);
  }

  Future<void> _run() async {
    Directory? fixtureDirectory;
    Object? failure;
    StackTrace? failureStack;
    try {
      _require(kReleaseMode, 'Probe must run in release mode');
      print(
        'NATIVE_RELEASE_BEGIN mode=release platform=${Platform.operatingSystem}',
      );
      fixtureDirectory = await Directory.systemTemp.createTemp(
        'ppplayer-release-',
      );
      final data = await rootBundle.load('assets/test_fixtures/test_video.mp4');
      final file = File('${fixtureDirectory.path}/video.mp4');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      for (var round = 1; round <= 3; round++) {
        setState(() {
          _showVideo = true;
          _status = 'Checking playback ($round/3)';
        });
        await WidgetsBinding.instance.endOfFrame;
        _position = Duration.zero;
        _duration = Duration.zero;
        _width = _height = 0;
        await _player.open(file.path, play: true);
        await _wait(
          () =>
              _playing &&
              _position.inMilliseconds >= 800 &&
              _width > 0 &&
              _height > 0,
          'Video decode and playback progress',
        );
        _require(
          _duration.inSeconds >= 4,
          'Fixture is too short for seek validation',
        );
        await _player.pause();
        await _wait(() => !_playing, 'Pause acknowledgement');
        // Let the final position event arrive before checking a paused interval.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final paused = _position;
        print('NATIVE_RELEASE_VIDEO_READY round=$round');
        await Future<void>.delayed(const Duration(seconds: 1));
        _require(
          (_position - paused).abs().inMilliseconds < 250,
          'Paused video advanced',
        );
        final target = Duration(milliseconds: _duration.inMilliseconds ~/ 2);
        await _player.seek(target);
        await _wait(
          () => (_position - target).abs().inMilliseconds < 500,
          'Seek result',
        );
        await _player.play();
        await _wait(
          () =>
              _playing &&
              _position > target + const Duration(milliseconds: 500),
          'Playback progress after seek',
        );
        _require(_errors.isEmpty, 'Native errors: $_errors');
        print(
          'NATIVE_RELEASE_ROUND_PASS round=$round position=$_position video=${_width}x$_height',
        );
        await _player.stop();
        await _wait(() => !_playing, 'Stop acknowledgement');
        setState(() => _showVideo = false);
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      _require(_errors.isEmpty, 'Native errors: $_errors');
    } catch (error, stack) {
      failure = error;
      failureStack = stack;
    } finally {
      try {
        await _player.stop();
        for (final subscription in _subscriptions) {
          await subscription.cancel();
        }
        await _player.dispose();
        // Freshly created by this probe; it contains only the test fixture.
        if (fixtureDirectory != null) {
          await fixtureDirectory.delete(recursive: true);
        }
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }
    if (failure != null) {
      setState(() => _status = 'Playback check failed');
      print('NATIVE_RELEASE_FAIL $failure\n$failureStack');
    } else {
      setState(() => _status = 'Playback checks passed');
      print('NATIVE_RELEASE_PASS rounds=3');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Playback validation')),
    body: Column(
      children: [
        Expanded(
          child: _showVideo
              ? Video(controller: _player.videoController!, controls: null)
              : const SizedBox(),
        ),
        Padding(padding: const EdgeInsets.all(16), child: Text(_status)),
      ],
    ),
  );
}
