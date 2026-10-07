import re
import os

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\network_outputs\network_output_controller.dart'
if os.path.exists(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        code = f.read()

    code = re.sub(r'\s*@override\n\s*YoutubePlayerController\? get youtubeController => _delegate\.youtubeController;\n', '', code, flags=re.DOTALL)
    code = re.sub(r'import \'package:youtube_player_iframe/youtube_player_iframe\.dart\';\n', '', code)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(code)
    print("Done")
else:
    print("Not found")
