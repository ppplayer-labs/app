import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import '../theme/app_theme.dart';

enum PlayerView { video, artwork, queue }

enum PerformanceMode { high, balanced, powerSaver }

enum SpotifyProviderType { ppplayer, custom }

enum YoutubeSearchMethod { scraping, api }

enum YoutubeApiProviderType { ppplayer, custom }

enum VideoFitMode { fit, fill }

class SettingsState {
  final String selectedCountry;
  final bool showVideo;
  final PlayerView playerView;
  final int themeIndex;
  final PerformanceMode performanceMode;
  final bool lowDataMode;
  final String userName;
  final int userAvatarColorIndex;
  final String? userAvatarBase64;
  final bool isLoaded;

  // New Provider Settings
  final SpotifyProviderType spotifyProvider;
  final YoutubeSearchMethod youtubeSearchMethod;
  final YoutubeApiProviderType youtubeApiProvider;
  final bool autoplayEnabled;
  final bool continuePlaybackInPip;
  final String? languageCode;
  final VideoFitMode videoFitMode;

  final double subtitleTextSize;
  final int subtitleBackgroundColor;
  final String? subtitleLanguage;

  SettingsState({
    required this.selectedCountry,
    this.showVideo = true,
    this.playerView = PlayerView.video,
    this.themeIndex = 0,
    this.performanceMode = PerformanceMode.balanced,
    this.lowDataMode = false,
    this.userName = '',
    this.userAvatarColorIndex = 0,
    this.userAvatarBase64,
    this.isLoaded = false,
    this.spotifyProvider = SpotifyProviderType.ppplayer,
    this.youtubeSearchMethod = YoutubeSearchMethod.scraping,
    this.youtubeApiProvider = YoutubeApiProviderType.ppplayer,
    this.autoplayEnabled = true,
    this.continuePlaybackInPip = true,
    this.languageCode,
    this.videoFitMode = VideoFitMode.fit,
    this.subtitleTextSize = 24.0,
    this.subtitleBackgroundColor = 0x80000000,
    this.subtitleLanguage,
  });

  SettingsState copyWith({
    String? selectedCountry,
    bool? showVideo,
    PlayerView? playerView,
    int? themeIndex,
    PerformanceMode? performanceMode,
    bool? lowDataMode,
    String? userName,
    int? userAvatarColorIndex,
    String? userAvatarBase64,
    bool? isLoaded,
    SpotifyProviderType? spotifyProvider,
    YoutubeSearchMethod? youtubeSearchMethod,
    YoutubeApiProviderType? youtubeApiProvider,
    bool? autoplayEnabled,
    bool? continuePlaybackInPip,
    String? languageCode,
    VideoFitMode? videoFitMode,
    double? subtitleTextSize,
    int? subtitleBackgroundColor,
    String? subtitleLanguage,
    bool nullifyAvatar = false,
  }) {
    return SettingsState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      showVideo: showVideo ?? this.showVideo,
      playerView: playerView ?? this.playerView,
      themeIndex: themeIndex ?? this.themeIndex,
      performanceMode: performanceMode ?? this.performanceMode,
      lowDataMode: lowDataMode ?? this.lowDataMode,
      userName: userName ?? this.userName,
      userAvatarColorIndex: userAvatarColorIndex ?? this.userAvatarColorIndex,
      userAvatarBase64: nullifyAvatar
          ? null
          : (userAvatarBase64 ?? this.userAvatarBase64),
      isLoaded: isLoaded ?? this.isLoaded,
      spotifyProvider: spotifyProvider ?? this.spotifyProvider,
      youtubeSearchMethod: youtubeSearchMethod ?? this.youtubeSearchMethod,
      youtubeApiProvider: youtubeApiProvider ?? this.youtubeApiProvider,
      autoplayEnabled: autoplayEnabled ?? this.autoplayEnabled,
      continuePlaybackInPip:
          continuePlaybackInPip ?? this.continuePlaybackInPip,
      languageCode: languageCode ?? this.languageCode,
      videoFitMode: videoFitMode ?? this.videoFitMode,
      subtitleTextSize: subtitleTextSize ?? this.subtitleTextSize,
      subtitleBackgroundColor:
          subtitleBackgroundColor ?? this.subtitleBackgroundColor,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  bool _disposed = false;

  @override
  SettingsState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    _loadSettings();
    return SettingsState(
      selectedCountry: 'US',
      showVideo: true,
      themeIndex: 0,
      performanceMode: PerformanceMode.balanced,
      lowDataMode: false,
      autoplayEnabled: true,
    );
  }

  static String _readString(Box<dynamic> box, String key, String fallback) {
    final value = box.get(key);
    return value is String ? value : fallback;
  }

  static String? _readNullableString(Box<dynamic> box, String key) {
    final value = box.get(key);
    return value is String ? value : null;
  }

  static bool _readBool(Box<dynamic> box, String key, bool fallback) {
    final value = box.get(key);
    return value is bool ? value : fallback;
  }

  static int _readInt(Box<dynamic> box, String key, int fallback) {
    final value = box.get(key);
    if (value is int) return value;
    if (value is num && value.isFinite) return value.round();
    return fallback;
  }

  static double _readDouble(Box<dynamic> box, String key, double fallback) {
    final value = box.get(key);
    if (value is num && value.isFinite) return value.toDouble();
    return fallback;
  }

  static const _boxName = 'settings';
  static const _countryKey = 'selected_country';
  static const _showVideoKey = 'show_video';
  static const _playerViewKey = 'player_view';
  static const _themeIndexKey = 'theme_index';
  static const _performanceModeKey = 'performance_mode';
  static const _lowDataModeKey = 'low_data_mode';
  static const _userNameKey = 'user_name';
  static const _userAvatarColorIndexKey = 'user_avatar_color_index';
  static const _userAvatarPathKey = 'user_avatar_path';
  static const _spotifyProviderKey = 'spotify_provider';
  static const _youtubeSearchMethodKey = 'youtube_search_method';
  static const _youtubeApiProviderKey = 'youtube_api_provider';
  static const _autoplayEnabledKey = 'autoplay_enabled';
  static const _continuePlaybackInPipKey = 'continue_playback_in_pip';
  static const _languageCodeKey = 'language_code';
  static const _videoFitModeKey = 'video_fit_mode';

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox(_boxName);
      if (_disposed) return;
      final country = _readString(box, _countryKey, 'US');
      final showVideo = _readBool(box, _showVideoKey, true);
      final playerViewIndex = _readInt(box, _playerViewKey, 0);
      final rawThemeIndex = _readInt(box, _themeIndexKey, 0);
      final themeIndex = rawThemeIndex.clamp(
        0,
        AppTheme.themeColors.length - 1,
      );

      // Auto-detect default performance mode based on platform if not set
      final performanceModeIndex = _readInt(box, _performanceModeKey, -1);
      final PerformanceMode defaultMode =
          (defaultTargetPlatform == TargetPlatform.android)
          ? PerformanceMode.balanced
          : PerformanceMode.high;
      final lowDataMode = _readBool(box, _lowDataModeKey, false);
      final userName = _readString(box, _userNameKey, '');
      final userAvatarColorIndex = _readInt(box, _userAvatarColorIndexKey, 0);
      final userAvatarBase64 = _readNullableString(box, _userAvatarPathKey);

      // Provider settings
      final spotifyProviderIndex = _readInt(
        box,
        _spotifyProviderKey,
        SpotifyProviderType.ppplayer.index,
      );
      final youtubeSearchMethodIndex = _readInt(
        box,
        _youtubeSearchMethodKey,
        YoutubeSearchMethod.scraping.index,
      );
      final youtubeApiProviderIndex = _readInt(
        box,
        _youtubeApiProviderKey,
        YoutubeApiProviderType.ppplayer.index,
      );
      final autoplayEnabled = _readBool(box, _autoplayEnabledKey, true);
      final continuePlaybackInPip = _readBool(
        box,
        _continuePlaybackInPipKey,
        false,
      );
      final languageCode = _readNullableString(box, _languageCodeKey);
      final videoFitModeIndex = _readInt(
        box,
        _videoFitModeKey,
        VideoFitMode.fit.index,
      );

      state = state.copyWith(
        selectedCountry: country,
        showVideo: showVideo,
        playerView: PlayerView
            .values[playerViewIndex.clamp(0, PlayerView.values.length - 1)],
        themeIndex: themeIndex,
        performanceMode: performanceModeIndex == -1
            ? defaultMode
            : PerformanceMode.values[performanceModeIndex.clamp(
                0,
                PerformanceMode.values.length - 1,
              )],
        lowDataMode: lowDataMode,
        userName: userName,
        userAvatarColorIndex: userAvatarColorIndex,
        userAvatarBase64: userAvatarBase64,
        spotifyProvider:
            SpotifyProviderType.values[spotifyProviderIndex.clamp(
              0,
              SpotifyProviderType.values.length - 1,
            )],
        youtubeSearchMethod:
            YoutubeSearchMethod.values[youtubeSearchMethodIndex.clamp(
              0,
              YoutubeSearchMethod.values.length - 1,
            )],
        youtubeApiProvider:
            YoutubeApiProviderType.values[youtubeApiProviderIndex.clamp(
              0,
              YoutubeApiProviderType.values.length - 1,
            )],
        autoplayEnabled: autoplayEnabled,
        continuePlaybackInPip: continuePlaybackInPip,
        languageCode: languageCode,
        videoFitMode: VideoFitMode
            .values[videoFitModeIndex.clamp(0, VideoFitMode.values.length - 1)],
        subtitleTextSize: _readDouble(box, 'subtitle_text_size', 24.0),
        subtitleBackgroundColor: _readInt(box, 'subtitle_bg_color', 0x80000000),
        subtitleLanguage: _readNullableString(box, 'subtitle_language'),
        isLoaded: true,
      );
    } catch (e) {
      debugPrint('SettingsNotifier: failed to load settings: $e');
      if (!_disposed) {
        state = state.copyWith(isLoaded: true);
      }
    }
  }

  Future<void> setPerformanceMode(PerformanceMode mode) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_performanceModeKey, mode.index);
    state = state.copyWith(performanceMode: mode);
  }

  Future<void> setLanguageCode(String? code) async {
    final box = await Hive.openBox(_boxName);
    if (code == null) {
      await box.delete(_languageCodeKey);
    } else {
      await box.put(_languageCodeKey, code);
    }
    state = state.copyWith(languageCode: code);
  }

  Future<void> setSubtitleTextSize(double size) async {
    final box = await Hive.openBox(_boxName);
    await box.put('subtitle_text_size', size);
    state = state.copyWith(subtitleTextSize: size);
  }

  Future<void> setSubtitleBackgroundColor(int colorValue) async {
    final box = await Hive.openBox(_boxName);
    await box.put('subtitle_bg_color', colorValue);
    state = state.copyWith(subtitleBackgroundColor: colorValue);
  }

  Future<void> setSubtitleLanguage(String? lang) async {
    final box = await Hive.openBox(_boxName);
    if (lang == null) {
      await box.delete('subtitle_language');
    } else {
      await box.put('subtitle_language', lang);
    }
    state = state.copyWith(subtitleLanguage: lang);
  }

  Future<void> setCountry(String country) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_countryKey, country);
    state = state.copyWith(selectedCountry: country);
  }

  Future<void> setTheme(int index) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_themeIndexKey, index);
    state = state.copyWith(themeIndex: index);
  }

  Future<void> setUserName(String name) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_userNameKey, name);
    state = state.copyWith(userName: name);
  }

  Future<void> setUserAvatarColorIndex(int index) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_userAvatarColorIndexKey, index);
    state = state.copyWith(userAvatarColorIndex: index);
  }

  Future<void> setUserAvatarBase64(String? base64String) async {
    final box = await Hive.openBox(_boxName);
    if (base64String == null) {
      await box.delete(_userAvatarPathKey);
    } else {
      await box.put(_userAvatarPathKey, base64String);
    }
    state = state.copyWith(userAvatarBase64: base64String);
  }

  Future<void> setSpotifyProvider(SpotifyProviderType provider) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_spotifyProviderKey, provider.index);
    state = state.copyWith(spotifyProvider: provider);
  }

  Future<void> setYoutubeSearchMethod(YoutubeSearchMethod method) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_youtubeSearchMethodKey, method.index);
    state = state.copyWith(youtubeSearchMethod: method);
  }

  Future<void> setYoutubeApiProvider(YoutubeApiProviderType type) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_youtubeApiProviderKey, type.index);
    state = state.copyWith(youtubeApiProvider: type);
  }

  Future<void> toggleAutoplay(bool enabled) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_autoplayEnabledKey, enabled);
    state = state.copyWith(autoplayEnabled: enabled);
  }

  Future<void> toggleContinuePlaybackInPip(bool enabled) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_continuePlaybackInPipKey, enabled);
    state = state.copyWith(continuePlaybackInPip: enabled);
  }

  Future<void> toggleVideo() async {
    final box = await Hive.openBox(_boxName);
    final newValue = !state.showVideo;
    await box.put(_showVideoKey, newValue);
    state = state.copyWith(showVideo: newValue);

    if (newValue) {
      setPlayerView(PlayerView.video);
    } else if (state.playerView == PlayerView.video) {
      setPlayerView(PlayerView.artwork);
    }
  }

  Future<void> toggleLowDataMode() async {
    final box = await Hive.openBox(_boxName);
    final newValue = !state.lowDataMode;
    await box.put(_lowDataModeKey, newValue);
    state = state.copyWith(lowDataMode: newValue);
  }

  Future<void> setPlayerView(PlayerView view) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_playerViewKey, view.index);
    state = state.copyWith(playerView: view);

    if (view == PlayerView.video && !state.showVideo) {
      await box.put(_showVideoKey, true);
      state = state.copyWith(showVideo: true);
    } else if (view == PlayerView.artwork && state.showVideo) {
      await box.put(_showVideoKey, false);
      state = state.copyWith(showVideo: false);
    }
  }

  Future<void> setVideoFitMode(VideoFitMode mode) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_videoFitModeKey, mode.index);
    state = state.copyWith(videoFitMode: mode);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

final selectedCountryProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).selectedCountry;
});
