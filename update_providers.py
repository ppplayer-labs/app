import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\playback_providers.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Modify the logic inside toPlaybackTrack
start_idx = code.find('    if (sourceType == TrackSourceType.online) {')
end_idx = code.find('      if (youtubeVideoId!.length != 11 || youtubeVideoId!.contains(\'http\')) {', start_idx)

if start_idx != -1 and end_idx != -1:
    new_validation = '''    if (sourceType == TrackSourceType.online) {
      if (youtubeVideoId == null) {
        throw StateError(
          'Cannot create PlaybackTrack: youtubeVideoId is null for online track',
        );
      }
      if (youtubeVideoId!.contains('http')) {
        throw StateError(
          'Cannot create PlaybackTrack: Invalid online source ID "$youtubeVideoId"',
        );
      }
    }'''
    end_validation = code.find('    }', end_idx) + 5
    code = code[:start_idx] + new_validation + code[end_validation:]

# Now modify the switch to set isPlaylist
switch_start = code.find('    PlaybackSourceType playbackSource;')
switch_end = code.find('    return PlaybackTrack(', switch_start)

if switch_start != -1 and switch_end != -1:
    new_switch = '''    PlaybackSourceType playbackSource;
    String finalId = spotifyId;
    bool isPlaylist = false;

    switch (sourceType) {
      case TrackSourceType.local:
        playbackSource = PlaybackSourceType.local;
        break;
      case TrackSourceType.networkStream:
        playbackSource = PlaybackSourceType.networkStream;
        if (networkStreamUrl != null) {
          for (var exp in [
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?(?:.*&)?v=([_\-a-zA-Z0-9]{10,11})(?:&.*)?$",
            ),
            RegExp(
              r"^https:\/\/(?:music\.)?youtube\.com\/watch\?(?:.*&)?v=([_\-a-zA-Z0-9]{10,11})(?:&.*)?$",
            ),
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/([_\-a-zA-Z0-9]{10,11})(?:\?.*)?$",
            ),
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{10,11})(?:\?.*)?$",
            ),
            RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{10,11})(?:\?.*)?$"),
            RegExp(
              r"^https:\/\/(?:www\.|m\.)?youtube\.com\/playlist\?(?:.*&)?list=([_\-a-zA-Z0-9]+)(?:&.*)?$",
            ),
          ]) {
            final match = exp.firstMatch(networkStreamUrl!.trim());
            if (match != null && match.groupCount >= 1) {
              playbackSource = PlaybackSourceType.online;
              finalId = match.group(1)!;
              if (exp.pattern.contains('playlist')) {
                isPlaylist = true;
              }
              break;
            }
          }
        }
        break;
      case TrackSourceType.online:
        playbackSource = PlaybackSourceType.online;
        finalId = youtubeVideoId!;
        if (finalId.length > 11 && (finalId.startsWith('PL') || finalId.startsWith('RD') || finalId.startsWith('LL'))) {
          isPlaylist = true;
        }
        break;
    }

'''
    code = code[:switch_start] + new_switch + code[switch_end:]

# Add isPlaylist to PlaybackTrack constructor
construct_start = code.find('    return PlaybackTrack(')
construct_end = code.find('      liveStatus: mapLiveStatus(liveStatus),', construct_start)

if construct_start != -1 and construct_end != -1:
    new_construct = '''      isVideo: isVideoFile,
      isPlaylist: isPlaylist,
'''
    old_video = code.find('      isVideo: isVideoFile,', construct_start)
    if old_video != -1:
        code = code[:old_video] + new_construct + code[old_video + 26:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
