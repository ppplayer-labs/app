import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\chromium_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# I need to change:
# Future<void> _open(
#       PlaybackTrack track,
#       Duration start,
#       bool online,
#       int generation,
#     ) async {
# inside _open:
#         if (_wantsPlaying) {
#           await player.loadVideoById(videoId: track.id, startSeconds: seconds);
#         } else {
#           await player.cueVideoById(videoId: track.id, startSeconds: seconds);
#         }

open_start = code.find('      if (_wantsPlaying) {')
open_end = code.find('      } else {\n          await player.cueVideoById(videoId: track.id, startSeconds: seconds);\n        }', open_start) + 104

if open_start != -1 and open_end != -1:
    new_open = '''      if (_wantsPlaying) {
          if (track.isPlaylist) {
            await player.loadPlaylist(playlistId: track.id, startSeconds: seconds);
          } else {
            await player.loadVideoById(videoId: track.id, startSeconds: seconds);
          }
        } else {
          if (track.isPlaylist) {
            await player.cuePlaylist(playlistId: track.id, startSeconds: seconds);
          } else {
            await player.cueVideoById(videoId: track.id, startSeconds: seconds);
          }
        }'''
    code = code[:open_start] + new_open + code[open_end:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
