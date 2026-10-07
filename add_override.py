import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\pubspec.yaml'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

override = """
dependency_overrides:
  flutter_chromium_webview:
    path: ../../flutter_chromium_webview/packages/flutter_chromium_webview
"""

if "dependency_overrides:" in code:
    if "flutter_chromium_webview:" not in code.split("dependency_overrides:")[1]:
        code = code.replace("dependency_overrides:", "dependency_overrides:\n  flutter_chromium_webview:\n    path: ../../flutter_chromium_webview/packages/flutter_chromium_webview")
else:
    code += override

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
