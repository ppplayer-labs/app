import sys

with open("lib/core/playback/chromium_playback_engine.dart", "r") as f:
    content = f.read()

old_code = """      int retries = 0;
      late ChromiumYoutubePlayerController player;
      while (true) {
        try {
          try { await (_cef ??= initializeCef()); } catch (e) { _cef = null; rethrow; }
          if (!_valid(generation)) return;
          player = _player = createPlayer();
          _playerSubscription = player.events.listen(
            (event) => _receive(event, generation, player),
          );
          await player.initialize();
          break;
        } catch (e) {
          if (e is PlatformException && const {'INIT_FAILED', 'HOST_FAILED', 'INIT_TIMEOUT'}.contains(e.code) && retries < 10) {
            _cef = null;
            retries++;
            await Future.delayed(const Duration(milliseconds: 500));
            if (!_valid(generation)) return;
            continue;
          }
          _cef = null;
          rethrow;
        }
      }
      if (!_valid(generation)) return;
      await player.setVolume((_status.volume * 100).round());
      if (!_valid(generation)) return;
      final seconds = start.inMicroseconds / Duration.microsecondsPerSecond;
      if (_wantsPlaying) {
        if (track.youtubeSourceType == YoutubeSourceType.playlist) {
          await player.loadPlaylist(playlistId: track.id, startSeconds: seconds);
        } else {
          await player.loadVideoById(videoId: track.id, startSeconds: seconds);
        }
      } else {
        if (track.youtubeSourceType == YoutubeSourceType.playlist) {
          await player.cuePlaylist(playlistId: track.id, startSeconds: seconds);
        } else {
          await player.cueVideoById(videoId: track.id, startSeconds: seconds);
        }
      }
      if (_valid(generation)) {
        if (!_wantsPlaying) await player.pauseVideo();
        await _readDuration(player, generation);
      }"""

new_code = """      int retries = 0;
      ChromiumYoutubePlayerController? player;
      while (true) {
        try {
          try { await (_cef ??= initializeCef()); } catch (e) { _cef = null; rethrow; }
          if (!_valid(generation)) return;
          player = _player = createPlayer();
          _playerSubscription = player.events.listen(
            (event) => _receive(event, generation, player!),
          );
          await player.initialize();
          if (!_valid(generation)) return;
          await player.setVolume((_status.volume * 100).round());
          if (!_valid(generation)) return;
          final seconds = start.inMicroseconds / Duration.microsecondsPerSecond;
          if (_wantsPlaying) {
            if (track.youtubeSourceType == YoutubeSourceType.playlist) {
              await player.loadPlaylist(playlistId: track.id, startSeconds: seconds);
            } else {
              await player.loadVideoById(videoId: track.id, startSeconds: seconds);
            }
          } else {
            if (track.youtubeSourceType == YoutubeSourceType.playlist) {
              await player.cuePlaylist(playlistId: track.id, startSeconds: seconds);
            } else {
              await player.cueVideoById(videoId: track.id, startSeconds: seconds);
            }
          }
          if (_valid(generation)) {
            if (!_wantsPlaying) await player.pauseVideo();
            await _readDuration(player, generation);
          }
          break;
        } catch (e) {
          final isCrash = e is StateError && e.message == 'Browser crashed';
          final isPlatformFail = e is PlatformException && const {'INIT_FAILED', 'HOST_FAILED', 'INIT_TIMEOUT', 'NOT_READY'}.contains(e.code);
          if ((isCrash || isPlatformFail) && retries < 10) {
            _cef = null;
            retries++;
            await player?.dispose();
            await Future.delayed(const Duration(milliseconds: 500));
            if (!_valid(generation)) return;
            continue;
          }
          _cef = null;
          rethrow;
        }
      }"""

content = content.replace(old_code, new_code)
with open("lib/core/playback/chromium_playback_engine.dart", "w") as f:
    f.write(content)

