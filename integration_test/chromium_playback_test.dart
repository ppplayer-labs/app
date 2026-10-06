import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_chromium_webview/chromium_youtube_player.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:ppplayer/core/playback/chromium_playback_engine.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native Chromium facade controls and local fallback', (
    tester,
  ) async {
    MediaKit.ensureInitialized();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      request.response.headers.contentType = ContentType(
        'application',
        'javascript',
      );
      request.response.write(r'''
window.YT={Player:class {
 constructor(id,config){this.events=config.events;this.time=0;this.volume=100;this.video='';this.playing=false;
  this.timer=setInterval(()=>{if(this.playing)this.time+=0.1;},100);
  setTimeout(()=>this.events.onReady({target:this}),20);}
 loadVideoById(v){this.video=v.videoId;this.time=v.startSeconds;this.playing=true;this.events.onStateChange({data:1});}
 cueVideoById(v){this.video=v.videoId;this.time=v.startSeconds;this.playing=false;this.events.onStateChange({data:5});}
 playVideo(){this.playing=true;this.events.onStateChange({data:1});}
 pauseVideo(){this.playing=false;this.events.onStateChange({data:2});}
 seekTo(v){this.time=v;}
 setVolume(v){this.volume=v;}
 getVolume(){return this.volume;}
 getCurrentTime(){return this.time;}
 getDuration(){return 120;}
 getVideoLoadedFraction(){return 0.5;}
 getVideoData(){return {video_id:this.video,title:'Fixture '+this.volume};}
 destroy(){clearInterval(this.timer);}
}};
onYouTubeIframeAPIReady();
''');
      await request.response.close();
    });
    final players = <ChromiumYoutubePlayerController>[];
    final engine = ChromiumPlaybackEngine(
      fallback: MediaKitPlaybackEngine(),
      initializeCef: () async {
        final initialized = await ChromiumWebViewController.initialize(
          cachePath: Directory.systemTemp
              .createTempSync('ppplayer-chromium-')
              .path,
        );
        if (!initialized)
          throw StateError('Native browser initialization failed');
      },
      createPlayer: () {
        final player = ChromiumYoutubePlayerController(
          documentUrl: '$origin/player',
          iframeApiUrl: '$origin/api.js',
        );
        players.add(player);
        return player;
      },
    );
    final events = <PlaybackEvent>[];
    final subscription = engine.eventStream.listen(events.add);

    Future<T> finish<T>(Future<T> future) async {
      var done = false;
      T? value;
      Object? error;
      future.then(
        (result) {
          value = result;
          done = true;
        },
        onError: (Object failure) {
          error = failure;
          done = true;
        },
      );
      final deadline = DateTime.now().add(const Duration(seconds: 40));
      while (!done && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(done, isTrue, reason: 'Native playback operation timed out');
      if (error != null) throw error!;
      return value as T;
    }

    Future<void> waitFor(bool Function() predicate, String description) async {
      final deadline = DateTime.now().add(const Duration(seconds: 12));
      while (!predicate() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(predicate(), isTrue, reason: description);
    }

    Future<void> surface() => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 360,
            child: PlaybackView(
              controller: engine,
              status: engine.currentStatus,
            ),
          ),
        ),
      ),
    );

    try {
      await finish(engine.setVolume(0.35));
      await finish(
        engine.play(const PlaybackTrack(id: 'M7lc1UVf-VE', title: 'First')),
      );
      await surface();
      expect(find.byType(ChromiumWebView), findsOneWidget);
      await waitFor(
        () => engine.currentStatus.position.inMilliseconds > 500,
        'Browser fixture did not advance through ppplayer status stream',
      );
      expect(await finish(players.last.volume), 35);
      await finish(engine.pause(caller: 'integration-test'));
      await waitFor(
        () => engine.currentStatus.state == PlaybackState.paused,
        'Pause not reflected',
      );
      final paused = await finish(players.last.currentTime);
      await tester.pump(const Duration(milliseconds: 700));
      expect((await finish(players.last.currentTime)) - paused, lessThan(0.2));
      await finish(engine.seekTo(const Duration(milliseconds: 10250)));
      expect(await finish(players.last.currentTime), closeTo(10.25, 0.1));
      await finish(engine.resume());
      await waitFor(
        () => engine.currentStatus.isPlaying,
        'Resume not reflected',
      );
      await tester.pumpWidget(const SizedBox());
      final detached = await finish(players.last.currentTime);
      await tester.pump(const Duration(seconds: 1));
      expect(
        (await finish(players.last.currentTime)) - detached,
        greaterThan(0.5),
      );
      await finish(
        engine.prepare(
          const PlaybackTrack(id: 'aqz-KE-bpKQ', title: 'Second'),
          position: const Duration(seconds: 3),
        ),
      );
      expect(engine.currentStatus.track!.id, 'aqz-KE-bpKQ');
      expect(await finish(players.last.currentTime), 3);
      expect(players.last.intendedPlaying, isFalse);
      await surface();
      expect(find.byType(ChromiumWebView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await finish(
        engine.play(
          const PlaybackTrack(
            id: 'local-fixture',
            title: 'Local video',
            sourceType: PlaybackSourceType.local,
            localMediaUri: 'asset://assets/test_fixtures/test_video.mp4',
            isVideo: true,
          ),
        ),
      );
      await surface();
      expect(find.byType(ChromiumWebView), findsNothing);
      await waitFor(
        () => engine.currentStatus.position.inMilliseconds > 400,
        'Local media fallback did not advance',
      );
      await finish(engine.pause());
      await waitFor(
        () => !engine.currentStatus.isPlaying,
        'Local pause not reflected',
      );
      expect(engine.currentStatus.isSeekable, isTrue);
      await finish(engine.seekTo(const Duration(milliseconds: 1250)));
      await waitFor(
        () => (engine.currentStatus.position.inMilliseconds - 1250).abs() < 100,
        'Paused native video did not seek precisely to the requested timestamp',
      );
      expect(engine.currentStatus.isPlaying, isFalse);
      expect(
        events.any((event) => event.type == PlaybackEventType.playbackError),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await finish(engine.stop());
      expect(engine.currentStatus.state, PlaybackState.idle);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await finish(engine.dispose());
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
