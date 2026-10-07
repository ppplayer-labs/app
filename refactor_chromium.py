import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\chromium_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Remove youtubeController getter
code = re.sub(r'\s*@override\n\s*dynamic get youtubeController => fallback.youtubeController;\n', '', code, flags=re.DOTALL)
code = re.sub(r'\s*@override\n\s*dynamic get youtubeController \{.*?\}\n', '', code, flags=re.DOTALL)
code = re.sub(r'\s*@override\n\s*dynamic get youtubeController => fallback\.youtubeController;\n', '', code, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
