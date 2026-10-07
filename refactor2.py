import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\engine\iframe_youtube_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace _activeSession with fallback delegates in other methods
methods_to_replace = {
    'pause': '''  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {
    if (!_isYoutube) return fallback.pause(caller: caller, failOnTimeout: failOnTimeout);
''',
    'resume': '''  @override
  Future<void> resume() async {
    if (!_isYoutube) return fallback.resume();
''',
    'stop': '''  @override
  Future<void> stop() async {
    if (!_isYoutube) return fallback.stop();
''',
    'seekTo': '''  @override
  Future<void> seekTo(Duration position) async {
    if (!_isYoutube) return fallback.seekTo(position);
''',
    'setVolume': '''  @override
  Future<void> setVolume(double volume) async {
    if (!_isYoutube) return fallback.setVolume(volume);
''',
    'setSpeed': '''  @override
  Future<void> setSpeed(double speed) async {
    if (!_isYoutube) return fallback.setSpeed(speed);
''',
    'setSubtitleTrack': '''  @override
  Future<void> setSubtitleTrack(String? uri) async {
    if (!_isYoutube) return fallback.setSubtitleTrack(uri);
''',
    'setSubtitleDelay': '''  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    if (!_isYoutube) return fallback.setSubtitleDelay(delay);
''',
    'setSubtitleAppearance': '''  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {
    if (!_isYoutube) return fallback.setSubtitleAppearance(textSize: textSize, backgroundColor: backgroundColor);
''',
}

for method, replacement in methods_to_replace.items():
    if method == 'pause':
        start = code.find('  @override\n  Future<void> pause({')
        end = code.find('    if ((_currentStatus.state == PlaybackState.paused', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'resume':
        start = code.find('  @override\n  Future<void> resume() async {')
        end = code.find('    _intentRevision++;', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'stop':
        start = code.find('  @override\n  Future<void> stop() async {')
        end = code.find('    _playGeneration++;', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'seekTo':
        start = code.find('  @override\n  Future<void> seekTo(Duration position) async {')
        end = code.find('    if (!_currentStatus.isSeekable) {', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'setVolume':
        start = code.find('  @override\n  Future<void> setVolume(double volume) async {')
        end = code.find('    if (_currentStatus.isIFrameMode) {', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'setSpeed':
        start = code.find('  @override\n  Future<void> setSpeed(double speed) async {')
        end = code.find('    if (_currentStatus.isIFrameMode) {', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'setSubtitleTrack':
        start = code.find('  @override\n  Future<void> setSubtitleTrack(String? uri) async {')
        end = code.find('    if (_currentStatus.isIFrameMode) return;', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'setSubtitleDelay':
        start = code.find('  @override\n  Future<void> setSubtitleDelay(Duration delay) async {')
        end = code.find('    if (_currentStatus.isIFrameMode) return;', start)
        code = code[:start] + replacement + code[end:]
    elif method == 'setSubtitleAppearance':
        start = code.find('  @override\n  Future<void> setSubtitleAppearance({')
        end = code.find('    if (_currentStatus.isIFrameMode) return;', start)
        code = code[:start] + replacement + code[end:]

# Fix else branches in pause, resume, stop, seekTo, setVolume, setSpeed, etc.
# Actually it's easier to just strip them out manually via regex
code = re.sub(r'\} else \{\s+await _activeSession\?.adapter\.pause\(\);\s+\}', r'}', code)
code = re.sub(r'\} else \{\s+await _activeSession\?.adapter\.play\(\);\s+\}', r'}', code)
code = re.sub(r'\} else \{\s+await _invalidateActiveSession\(\);\s+\}', r'}', code)
code = re.sub(r'\} else \{\s+final session = _activeSession;.*?await session\.adapter\.play\(\);\s+\}\s+\}', r'}', code, flags=re.DOTALL)
code = re.sub(r'\} else \{\s+await _activeSession\?.adapter\.setVolume\(volume \* 100\);\s+\}', r'}', code)
code = re.sub(r'\} else \{\s+await _activeSession\?.adapter\.setRate\(speed\);\s+\}', r'}', code)
code = re.sub(r'\} else \{\s+await _activeSession\?.adapter\.setSubtitleTrack.*?\}', r'}', code, flags=re.DOTALL)
code = re.sub(r'await _activeSession\?.adapter\.setSubtitleDelay\(delay\);', r'', code)
code = re.sub(r'await _activeSession\?.adapter\.setSubtitleAppearance\(.*?\);', r'', code, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
