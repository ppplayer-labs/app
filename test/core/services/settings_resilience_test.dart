import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/core/theme/app_theme.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ppplayer_settings_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test(
    'SettingsNotifier recovers safely from corrupted Hive types and out-of-range themeIndex',
    () async {
      final box = await Hive.openBox('settings');
      await box.put('selected_country', 12345);
      await box.put('show_video', 'yes');
      await box.put('theme_index', 999);
      await box.put('subtitle_text_size', 'huge');
      await box.put('subtitle_bg_color', 'transparent');
      await box.put('player_view', 'invalid');
      await box.close();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      await container.read(settingsProvider.notifier).loadSettled;

      final state = container.read(settingsProvider);
      expect(state.isLoaded, isTrue);
      expect(state.selectedCountry, 'US');
      expect(state.showVideo, isTrue);
      expect(state.themeIndex, AppTheme.themeColors.length - 1);
      expect(state.subtitleTextSize, 24.0);
      expect(state.subtitleBackgroundColor, 0x80000000);
    },
  );

  test('SettingsNotifier clamps negative themeIndex to 0', () async {
    final box = await Hive.openBox('settings');
    await box.put('theme_index', -42);
    await box.close();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(settingsProvider);
    await container.read(settingsProvider.notifier).loadSettled;

    final state = container.read(settingsProvider);
    expect(state.isLoaded, isTrue);
    expect(state.themeIndex, 0);
  });

  test(
    'disposing ProviderContainer before _loadSettings completes does not throw',
    () async {
      final container = ProviderContainer();
      container.read(settingsProvider);
      final loadFuture = container.read(settingsProvider.notifier).loadSettled;
      container.dispose();
      await loadFuture;
    },
  );
}
