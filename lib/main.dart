import 'dart:async';
import 'package:ppplayer/l10n/app_localization_delegates.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/db/app_database.dart';
import 'core/playback/media_handler.dart';
import 'core/services/settings_provider.dart';
import 'core/playback/media_sync_service.dart';
import 'core/services/dock_menu_service.dart';
import 'core/metrics/cache_metrics.dart';
import 'core/playback/pip_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:macos_file_open_handler/macos_file_open_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'core/player/player_provider.dart';
import 'core/playback/playback_providers.dart'
    show localPlaybackControllerProvider;
import 'core/local_library/local_library_service.dart';

/// Global access to the provider container for the [AudioHandler].
late ProviderContainer globalContainer;

/// Coordinates one-shot, ordered shutdown of playback engines, browser
/// controllers, and Riverpod providers before process exit.
class AppShutdownCoordinator {
  AppShutdownCoordinator(this._containerProvider);

  final ProviderContainer Function() _containerProvider;
  Future<void>? _shutdownFuture;

  Future<void> shutdown() => _shutdownFuture ??= _performShutdown();

  Future<void> _performShutdown() async {
    final container = _containerProvider();
    try {
      if (container.exists(localPlaybackControllerProvider)) {
        final controller = container.read(localPlaybackControllerProvider);
        await controller.dispose().timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      }
    } catch (error) {
      debugPrint('[shutdown] Playback disposal error: $error');
    }
    try {
      container.dispose();
    } catch (error) {
      debugPrint('[shutdown] Container disposal error: $error');
    }
  }
}

/// Returns whether [AppLifecycleState.detached] should dispose the global
/// Riverpod container and playback engines.
///
/// Desktop platforms detach only when the application is terminating, whereas
/// Android (`AudioServiceActivity`) and iOS can detach/recreate the UI view
/// while the cached Flutter engine and background audio service stay alive.
bool shouldShutdownOnAppDetach({
  required TargetPlatform platform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;
}

late AppShutdownCoordinator appShutdownCoordinator;

Future<void> _requestNotificationPermission() async {
  if (!kIsWeb && Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
}

void main() async {
  final startupWatch = Stopwatch()..start();
  void startupLog(String message) {
    debugPrint('[startup ${startupWatch.elapsedMilliseconds}ms] $message');
  }

  startupLog('main() entered');
  WidgetsFlutterBinding.ensureInitialized();
  // Cap desktop image cache so Impeller/ANGLE GPU-backed image allocations stay
  // bounded without hurting scrolling responsiveness (resized covers use ~150 KB).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    PaintingBinding.instance.imageCache.maximumSizeBytes = 48 * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = 200;
  }
  startupLog('Flutter binding initialized');
  MediaKit.ensureInitialized();
  startupLog('MediaKit initialized');

  // Load environment variables (wrap in try-catch in case it's missing)
  startupLog('dotenv load start');
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint(
      'Warning: .env file not found or could not be loaded. Relying on --dart-define or defaults.',
    );
  }
  startupLog('dotenv load complete');

  // Request notification permissions for background service stability on Android 13+
  startupLog('notification permission check start');
  await _requestNotificationPermission();
  startupLog('notification permission check complete');

  PipHandler.init();

  // Init Hive for prefs/queue
  startupLog('Hive init start');
  String? dbPath;
  if (!kIsWeb) {
    final appDir = await getApplicationSupportDirectory();
    dbPath = appDir.path;
    Hive.init(appDir.path);
  } else {
    await Hive.initFlutter();
  }
  startupLog('Hive init complete');

  startupLog('AppDatabase init start');
  final appDatabase = AppDatabase(dbPath);
  startupLog(
    'AppDatabase init complete (uses background isolate via NativeDatabase.createInBackground)',
  );

  // Initialize the container first (needed by builder)
  startupLog('ProviderContainer init');
  globalContainer = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(appDatabase)],
  );

  // Configure AudioSession for background playback & audio focus.
  // Skip on iOS — AppDelegate.swift owns AVAudioSession configuration and
  // calling configure() here would cause redundant XPC calls to the
  // audio daemon and potentially conflict with AppDelegate's setup.
  startupLog('AudioSession configure start');
  if (!kIsWeb && !Platform.isIOS) {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
  startupLog('AudioSession configure complete');

  // Initialize the audio handler bridge
  final PpPlayerAudioHandler handler;

  // On iOS: PPPlayer's native AppDelegate.swift owns MPRemoteCommandCenter and
  // MPNowPlayingInfoCenter. AudioService.init on iOS calls
  // _platform.configure() which invokes the audio_service Obj-C plugin's
  // "configure" handler — that is a fast no-op (just stores interval values).
  // However it also registers static global MPRemoteCommandCenter handlers
  // that would conflict with any future native-side control registration.
  // We bypass it on iOS for the same reason we do on macOS, routing all
  // control events through the com.ppplayer.app/ios_media_controls channel.
  startupLog('AudioHandler init start');
  if (!kIsWeb && (Platform.isMacOS || Platform.isIOS)) {
    // macOS/iOS: instantiate without registering an audio_service background isolate.
    handler = PpPlayerAudioHandler(() => globalContainer);
  } else {
    handler = await AudioService.init(
      builder: () => PpPlayerAudioHandler(() => globalContainer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ppplayer.app.playback',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidResumeOnClick: true,
      ),
    );
  }
  startupLog('AudioHandler init complete');

  // Re-initialize/Update container with the actual handler instance, disposing
  // the temporary bootstrap container so Riverpod resources are never leaked.
  startupLog('ProviderContainer re-init with handler');
  final bootstrapContainer = globalContainer;
  globalContainer = ProviderContainer(
    overrides: [
      // Provide the drift database instance app-wide
      appDatabaseProvider.overrideWithValue(appDatabase),
      // Register the static handler instance
      audioHandlerProvider.overrideWithValue(handler),
    ],
  );
  bootstrapContainer.dispose();
  appShutdownCoordinator = AppShutdownCoordinator(() => globalContainer);

  // Initialize background media sync service
  startupLog('MediaSyncService init');
  globalContainer.read(mediaSyncServiceProvider);
  startupLog('MediaSyncService ready');

  // Initialize native dock menu service for macOS
  if (!kIsWeb && Platform.isMacOS) {
    globalContainer.read(dockMenuServiceProvider);

    // Register file open handler
    MacosFileOpenHandler.instance.listen(
      (files) async {
        if (files.isEmpty) return;
        final libraryService = globalContainer.read(
          localLibraryServiceProvider,
        );
        final tracks = await libraryService.importFilesByPaths(
          files.map((e) => e.path).toList(),
        );

        if (tracks.isNotEmpty) {
          final player = globalContainer.read(playerProvider.notifier);
          // Play the first track and add the rest to queue
          player.playTrack(tracks.first);
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Could not open file: $error');
      },
    );
  }

  if (kDebugMode) {
    globalContainer.read(cacheMetricsProvider).startLogging();
  }

  startupLog('runApp called');
  runApp(
    UncontrolledProviderScope(
      container: globalContainer,
      child: _AppLifecycleLogger(
        shutdownCoordinator: appShutdownCoordinator,
        child: const PpPlayerApp(),
      ),
    ),
  );
}

class _AppLifecycleLogger extends StatefulWidget {
  final Widget child;
  final AppShutdownCoordinator shutdownCoordinator;
  const _AppLifecycleLogger({
    required this.child,
    required this.shutdownCoordinator,
  });
  @override
  State<_AppLifecycleLogger> createState() => _AppLifecycleLoggerState();
}

class _AppLifecycleLoggerState extends State<_AppLifecycleLogger>
    with WidgetsBindingObserver {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await widget.shutdownCoordinator.shutdown();
        return AppExitResponse.exit;
      },
      onDetach: shouldShutdownOnAppDetach(platform: defaultTargetPlatform)
          ? () {
              unawaited(widget.shutdownCoordinator.shutdown());
            }
          : null,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      final time = DateTime.now().toIso8601String().substring(11, 23);
      debugPrint(
        '$time [PipDebug][FLUTTER] state=${state.name} inPip=${PipHandler.isInPipMode} activityStopped=${PipHandler.isActivityStopped}',
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PpPlayerApp extends ConsumerWidget {
  const PpPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    final safeThemeIndex = settings.themeIndex.clamp(
      0,
      AppTheme.themeColors.length - 1,
    );
    final themeColor = AppTheme.themeColors[safeThemeIndex];

    return MaterialApp.router(
      title: 'PPPlayer',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: LocalLibraryService.messengerKey,
      theme: AppTheme.dark(primaryColor: themeColor),
      scrollBehavior: const AppScrollBehavior(),
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.languageCode != null
          ? Locale(settings.languageCode!)
          : null,
      routerConfig: router,
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
