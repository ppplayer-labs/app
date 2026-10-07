import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\ui\playback_view.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Remove youtube_player_iframe import
code = re.sub(r'import \'package:youtube_player_iframe/youtube_player_iframe\.dart\';\n', '', code)

# 2. Remove YoutubePlayer properties and Windows toggle hack (the hack should be moved to IframeYoutubePlaybackEngine later, but for now we remove it from PlaybackView)
code = re.sub(r'\s*Widget\? _cachedYoutubePlayer;\n\s*YoutubePlayerController\? _lastController;\n', '\n', code)

# 3. Simplify Windows resize hack (the hack is generic to any platform view?)
# Wait, let's keep the Windows toggle hack but apply it to ANY renderer if it's a widget on Windows!

# 4. Remove youtube specific branch
branch_start = code.find('    if (widget.status.isIFrameMode &&')
branch_end = code.find('    final renderer = widget.controller.renderer;', branch_start)
if branch_start != -1 and branch_end != -1:
    code = code[:branch_start] + code[branch_end:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
