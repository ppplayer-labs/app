import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\engine\playback_controller.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

code = re.sub(r'\s*YoutubePlayerController\? get youtubeController;\n', '\n', code)
code = re.sub(r'import \'package:youtube_player_iframe/youtube_player_iframe\.dart\';\n', '', code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
