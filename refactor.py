import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\engine\iframe_youtube_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Remove _makeAdapter, _invalidateActiveSession, _bindSession
start = code.find('  INativePlayerAdapter _makeAdapter() =>')
end = code.find('  // ---------------------------------------------------------------------------', start)
if start != -1 and end != -1:
    code = code[:start] + code[end:]

# 2. Refactor prepare
prepare_start = code.find('  @override\n  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {')
prepare_end = code.find('    // ── YouTube prepare path', prepare_start)
if prepare_start != -1 and prepare_end != -1:
    new_prepare = '''  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {
    if (_disposed) return;
    final isOnline = track.sourceType == PlaybackSourceType.online && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(track.id);
    if (!isOnline) {
      _isYoutube = false;
      return fallback.prepare(track, position: position);
    }
    _isYoutube = true;

'''
    code = code[:prepare_start] + new_prepare + code[prepare_end + 75:] # skip '    // ── YouTube prepare path ──────────────────────────────────────────────────\n'

# 3. Refactor play
play_start = code.find('  @override\n  Future<void> play(')
play_end = code.find('    // ── YouTube play path', play_start)
if play_start != -1 and play_end != -1:
    new_play = '''  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {
    if (_disposed) return;
    final isOnline = track.sourceType == PlaybackSourceType.online && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(track.id);
    if (!isOnline) {
      _isYoutube = false;
      return fallback.play(track, startAt: startAt, play: play);
    }
    _isYoutube = true;

'''
    code = code[:play_start] + new_play + code[play_end + 72:] # skip '    // ── YouTube play path ─────────────────────────────────────────────────────\n'

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
