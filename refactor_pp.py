import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\playback_providers.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace MediaKitPlaybackEngine on apple platforms
code = re.sub(r'final mediaKit = MediaKitPlaybackEngine\(\);\n    engine =\n        \{\n          TargetPlatform\.iOS,\n          TargetPlatform\.macOS,\n        \}\.contains\(defaultTargetPlatform\)\n        \? LocalFilePlaybackController\(\n            mediaKit,\n            acquireFileLease: acquireAppleOutputFileLease,\n          \)\n        : mediaKit;',
'''final mediaKit = MediaKitPlaybackEngine();
    engine =
        {
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)
        ? IframeYoutubePlaybackEngine(
            fallback: LocalFilePlaybackController(
              mediaKit,
              acquireFileLease: acquireAppleOutputFileLease,
            ),
          )
        : mediaKit;''', code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
