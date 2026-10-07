import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\chromium_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

play_start = code.find('      final online =\n        track.sourceType == PlaybackSourceType.online &&\n        RegExp(r\'^[A-Za-z0-9_-]{11}$\').hasMatch(track.id);')
if play_start != -1:
    new_online = '      final online = track.sourceType == PlaybackSourceType.online;'
    code = code[:play_start] + new_online + code[play_start + 131:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
