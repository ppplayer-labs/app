import re

files = [
    r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\chromium_playback_engine.dart',
    r'C:\Users\User\Projects\ppplayermusic\app\test\core\player\player_notifier_playback_speed_test.dart',
]

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        code = f.read()
    code = re.sub(r'import \'package:youtube_player_iframe/youtube_player_iframe\.dart\';\n', '', code)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(code)

print("Done")
