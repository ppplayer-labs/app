import re

file_path = r'C:\Users\User\Projects\ppplayermusic\app\lib\core\playback\packages\pp_playback_engine\lib\src\engine\media_kit_playback_engine.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Remove youtubeControllerFactory
code = re.sub(r'\s*/// Factory for YouTube player controllers.*?\n\s*final yt\.YoutubePlayerController Function.*?youtubeControllerFactory;', '', code, flags=re.DOTALL)
code = re.sub(r'this\.youtubeControllerFactory,', '', code)
code = re.sub(r'import \'package:youtube_player_iframe/youtube_player_iframe\.dart\' as yt;\n', '', code)

# 2. Remove YouTube state variables
code = re.sub(r'\s*// ── YouTube/IFrame state ──────────────────────────────────────────────────\n\s*yt\.YoutubePlayerController\? _youtubeController;\n\s*/// Long-lived IFrame subscriptions.*?\n\s*final List<StreamSubscription<dynamic>> _iframeSubscriptions = \[\];', '', code, flags=re.DOTALL)
code = re.sub(r'\s*// YouTube can repeat a paused value.*?\n\s*\(int, int\)\? _iosPauseRecoveryEpisode;\n\s*Object\? _iosPauseRecoveryToken;\n\s*Timer\? _iosPauseRecoveryCooldown;\n', '', code, flags=re.DOTALL)
code = re.sub(r'\s*bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform\.iOS;\n', '', code)
code = re.sub(r'\s*void _cancelIOSPauseRecovery\(\) \{.*?\n\s*\}\n', '', code, flags=re.DOTALL)
code = re.sub(r'\s*Timer\? _iframePositionTimer;\n', '', code)

# 3. Simplify play/prepare fallthrough
code = re.sub(r'\s*// ── YouTube prepare path ──────────────────────────────────────────────────.*?// ---------------------------------------------------------------------------', '\n    throw UnsupportedError(\'MediaKitPlaybackEngine does not support YouTube playback.\');\n  }\n\n  // ---------------------------------------------------------------------------', code, flags=re.DOTALL)
code = re.sub(r'\s*// ── YouTube play path ─────────────────────────────────────────────────────.*?// ---------------------------------------------------------------------------', '\n    throw UnsupportedError(\'MediaKitPlaybackEngine does not support YouTube playback.\');\n  }\n\n  // ---------------------------------------------------------------------------', code, flags=re.DOTALL)
code = re.sub(r'\s*// YouTube helpers \(unchanged logic, adapted variable names\)\n\s*// ---------------------------------------------------------------------------\n\s*void _failAttempt\(int generation, String error\) \{.*?\}', '', code, flags=re.DOTALL)
code = re.sub(r'\s*void _armWatchdog\(int generation, \{required bool loading\}\) \{.*?\}\n', '', code, flags=re.DOTALL)
code = re.sub(r'\s*Future<void> _enterIFrameMode\(.*?\}\n', '', code, flags=re.DOTALL)
code = re.sub(r'\s*Future<void> _load\(.*?\}\n', '', code, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
