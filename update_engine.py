import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\chromium_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Update _load to properly distinguish playlists
load_start = code.find('  Future<void> _load(int generation, String videoId, {double? startSeconds}) async {')
load_end = code.find('      if (_intendedState == PlaybackState.playing) {', load_start)

if load_start != -1 and load_end != -1:
    new_load = '''  Future<void> _load(int generation, String videoId, {double? startSeconds}) async {
    try {
      if (videoId.isEmpty) {
        _failAttempt(generation, 'Video ID is empty');
        return;
      }
      
      // Look at the current track in PPPlayer metadata to determine if it's a playlist or a single video
      // Since `videoId` is passed in, if it's longer than 11 chars, it's typically a playlist ID.
      // Wait, PPPlayer `videoId` might just be a playlist ID (e.g. PL...), but let's use the explicit check.
      // Actually, PPPlayer passes `Track.id` which is the video/playlist ID. We'll use the ID string length since standard youtube video IDs are exactly 11 chars.
      final isPlaylist = videoId.length > 11 || videoId.startsWith('PL') || videoId.startsWith('RD') || videoId.startsWith('LL');

      if (_intendedState == PlaybackState.paused) {
        if (isPlaylist) {
          await _playerController!.cuePlaylist(
            playlistId: videoId,
            startSeconds: startSeconds ?? 0,
          );
        } else {
          await _playerController!.cueVideoById(
            videoId: videoId,
            startSeconds: startSeconds ?? 0,
          );
        }
      } else {
'''
    code = code[:load_start] + new_load + code[load_end:]
    
    # fix the playing block
    play_start = code.find('      if (_intendedState == PlaybackState.playing) {')
    play_end = code.find('      }\n    } catch (e) {', play_start)
    if play_start != -1 and play_end != -1:
        new_play = '''      if (_intendedState == PlaybackState.playing) {
        if (isPlaylist) {
          await _playerController!.loadPlaylist(
            playlistId: videoId,
            startSeconds: startSeconds ?? 0,
          );
        } else {
          await _playerController!.loadVideoById(
            videoId: videoId,
            startSeconds: startSeconds ?? 0,
          );
        }
'''
        code = code[:play_start] + new_play + code[play_end:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
