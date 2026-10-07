import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\local_file_playback_controller.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

code = re.sub(r'\s*@override\n\s*YoutubePlayerController\? get youtubeController => _delegate\.youtubeController;\n', '', code, flags=re.DOTALL)
code = re.sub(r'import \'package:youtube_player_iframe/youtube_player_iframe\.dart\';\n', '', code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
