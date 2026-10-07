import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\engine\media_kit_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Remove helper methods
code = re.sub(r'\s*Future<void> _recoverIOSIFramePause\(int generation\) async \{.*?(?=\s*Future<void> _dispatchIFramePlay)', '', code, flags=re.DOTALL)
code = re.sub(r'\s*Future<void> _dispatchIFramePlay\(.*?\}\n\s*\}\n', '', code, flags=re.DOTALL)

code = re.sub(r'\s*// Tracks consecutive ticks where getCurrentTime returned the same frozen.*?(?=\s*// ---------------------------------------------------------------------------)', '', code, flags=re.DOTALL)

# 2. Fix pause
code = re.sub(r'    if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n\s*(await _activeSession\?\.adapter\.pause\(\);)\n\s*\}', r'    \1', code, flags=re.DOTALL)
code = re.sub(r'\s*_cancelIOSPauseRecovery\(\);', '', code)

# 3. Fix resume
code = re.sub(r'\s*// Activity-stopped guard \(baseline only\)\..*?\}\n\n', '\n', code, flags=re.DOTALL)
code = re.sub(r'    if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n\s*(await _activeSession\?\.adapter\.play\(\);)\n\s*\}', r'    \1', code, flags=re.DOTALL)
code = re.sub(r'\s*_diag\(\s*\'ENGINE resume\(\) iframeMode=\$\{_currentStatus\.isIFrameMode\} \'\s*\'activityStopped=\$isActivityStopped gen=\$_playGeneration\',\s*\);', '', code, flags=re.DOTALL)


# 4. Fix stop
code = re.sub(r'\s*_stopIFramePolling\(\);', '', code)
code = re.sub(r'\s*_latePauseGeneration = null;', '', code)
code = re.sub(r'    if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n\s*(await _invalidateActiveSession\(\);)\n\s*\}', r'    \1', code, flags=re.DOTALL)

# 5. Fix seekTo
code = re.sub(r'    if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n', '    ', code, flags=re.DOTALL)
code = re.sub(r'    \}\n\n  @override\n  Future<void> setVolume', '\n\n  @override\n  Future<void> setVolume', code, flags=re.DOTALL)

# 6. Fix setVolume, setSpeed, etc.
code = re.sub(r'    if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n\s*(await _activeSession\?\.adapter\.setVolume\(volume \* 100\);)\n\s*\}', r'    \1', code, flags=re.DOTALL)
code = re.sub(r'    if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n\s*(await _activeSession\?\.adapter\.setRate\(speed\);)\n\s*\}', r'    \1', code, flags=re.DOTALL)
code = re.sub(r'\s*if \(_currentStatus\.isIFrameMode\) return;', '', code)
code = re.sub(r'\s*if \(_currentStatus\.isIFrameMode\) \{.*?\} else \{\n', '\n', code, flags=re.DOTALL)

# 7. fix dispose
code = re.sub(r'\s*_iframePositionTimer\?\.cancel\(\);', '', code)
code = re.sub(r'\s*for \(final sub in _iframeSubscriptions\).*?_iframeSubscriptions\.clear\(\);', '', code, flags=re.DOTALL)
code = re.sub(r'\s*_youtubeController\?\.close\(\);', '', code)
code = re.sub(r'\s*_iframeSubscriptions\.clear\(\);', '', code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
