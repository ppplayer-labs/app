import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\chromium_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

code = re.sub(r'\s*@override\n\s*YoutubePlayerController\? get youtubeController =>.*?\n\s*_chromium \? null : fallback\.youtubeController;\n', '', code, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

test_path = r'C:\Users\User\Projects\ppplayermusic\app\test\core\playback\chromium_playback_engine_test.dart'
with open(test_path, 'r', encoding='utf-8') as f:
    test_code = f.read()

test_code = 'import \'package:ppplayer/core/playback/chromium_playback_engine.dart\';\n' + test_code
with open(test_path, 'w', encoding='utf-8') as f:
    f.write(test_code)

print("Done")
