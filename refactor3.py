import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\engine\iframe_youtube_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace renderer and youtubeController
start = code.find('  dynamic get renderer => _activeSession?.videoController;')
end = code.find('  // ---------------------------------------------------------------------------', start)
if start != -1 and end != -1:
    new_props = '''  dynamic get renderer {
    if (!_isYoutube) return fallback.renderer;
    if (_youtubeController == null) return null;
    return yt.YoutubePlayer(
      key: const flutter.ValueKey('pp_youtube_iframe'),
      controller: _youtubeController!,
      backgroundColor: flutter.Colors.transparent,
    );
  }

  @override
  yt.YoutubePlayerController? get youtubeController => _isYoutube ? null : fallback.youtubeController;

'''
    code = code[:start] + new_props + code[end:]

# Add flutter imports at the top if needed
if 'import \'package:flutter/material.dart\'' not in code:
    code = code.replace('import \'package:flutter/foundation.dart\';', 'import \'package:flutter/foundation.dart\';\nimport \'package:flutter/material.dart\' as flutter;')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
