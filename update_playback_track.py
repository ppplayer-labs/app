import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\models\playback_track.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Add isPlaylist field
code = re.sub(r'  final bool isVideo;\n', '  final bool isVideo;\n  final bool isPlaylist;\n', code)
code = re.sub(r'    this\.isVideo = false,\n', '    this.isVideo = false,\n    this.isPlaylist = false,\n', code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
