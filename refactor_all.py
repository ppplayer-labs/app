import re
import os
import glob

files_to_check = glob.glob(r'C:\Users\User\Projects\ppplayermusic\app\lib\**\*.dart', recursive=True) + glob.glob(r'C:\Users\User\Projects\ppplayermusic\app\test\**\*.dart', recursive=True)

for file_path in files_to_check:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            code = f.read()

        if 'youtubeController' in code:
            if 'iframe_youtube_playback_engine.dart' in file_path or 'youtube_playback_engine.dart' in file_path:
                continue

            # Remove getter
            code = re.sub(r'\s*@override\n\s*(?:yt\.)?YoutubePlayerController\? get youtubeController => .*?;\n', '', code, flags=re.DOTALL)
            code = re.sub(r'\s*@override\n\s*(?:yt\.)?YoutubePlayerController\? get youtubeController \{.*?\n\s*\}\n', '', code, flags=re.DOTALL)
            code = re.sub(r'\s*@override\n\s*(?:yt\.)?YoutubePlayerController\? get youtubeController;\n', '', code, flags=re.DOTALL)

            # In tests
            code = re.sub(r'\s*@override\n\s*dynamic get youtubeController => null;\n', '', code, flags=re.DOTALL)

            code = re.sub(r'this\.youtubeControllerFactory,', '', code)

            # Some files might have `youtubeController` without override
            code = re.sub(r'\s*(?:yt\.)?YoutubePlayerController\? get youtubeController => .*?;\n', '', code, flags=re.DOTALL)
            code = re.sub(r'\s*(?:yt\.)?YoutubePlayerController\? get youtubeController \{.*?\n\s*\}\n', '', code, flags=re.DOTALL)

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(code)
    except Exception as e:
        pass
print("Done")
