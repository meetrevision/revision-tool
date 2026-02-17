import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';

import 'core/routing/app_router.dart';
import 'core/services/win_registry_service.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/settings/locale_config.dart';
import 'core/trusted_installer/trusted_installer_service.dart';
import 'i18n/generated/strings.g.dart';
import 'utils.dart';

String? initialRoute;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  const tag = 'gui_main:';

  if (kDebugMode) {
    logger.i('$tag Running in debug mode');
    // debugRepaintRainbowEnabled = true;
    // debugInvertOversizedImages = true;
  }

  FlutterError.onError = (details) {
    logger.e(
      '$tag flutter_framework_error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('$tag platform_dispatcher_error', error: error, stackTrace: stack);
    return true;
  };

  logger.i('$tag Revision Tool GUI is starting');

  try {
    logger.i('$tag Initializing TrustedInstaller service');
    await TrustedInstallerServiceImpl.initialize();
  } catch (e) {
    logger.w('$tag Failed to initialize TrustedInstaller: $e');
  }

  if (WinRegistryService.isSupported) {
    _isSupported = true;
    logger.i('$tag supported=$_isSupported');
  }

  if (args.isNotEmpty && args[0].startsWith('--route=')) {
    initialRoute = args[0].replaceFirst('--route=', '');
  }

  if (WinRegistryService.readString(
        RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool',
        'ThemeMode',
      ) ==
      null) {
    logger.i('$tag Initializing Revision registry keys');
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'ThemeMode',
      ThemeMode.system.name,
    );
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Experimental',
      0,
    );
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Language',
      AppLocale.en.name,
    );
  }

  logger.i('$tag Initializing locale');
  try {
    final AppLocale savedLocale = LocaleConfig.parse(appLanguage);
    await LocaleSettings.setLocale(savedLocale);
  } catch (e) {
    logger.w('$tag Failed to set locale: $e');
    await LocaleSettings.setLocale(AppLocale.en);
  }

  logger.i('$tag Initializing settings controller');
  await SystemTheme.accentColor.load();
  await Window.initialize();
  await Window.hideWindowControls();

  logger.i('$tag Initializing WindowPlus');
  await WindowPlus.ensureInitialized(
    application: 'revision-tool',
    enableCustomFrame: true,
    enableEventStreams: false,
  );
  await WindowPlus.instance.setMinimumSize(const Size(515, 330));

  runApp(ProviderScope(child: TranslationProvider(child: const MyApp())));
}

bool _isSupported = false;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings appSettings = ref.watch(appSettingsProvider);
    final AppSettingsNotifier settingsNotifier = ref.read(
      appSettingsProvider.notifier,
    );

    return SystemThemeBuilder(
      builder: (context, accent) {
        final bool isLargeScreen = is10footScreen(context);
        final AccentColor accentColor = getSystemAccentColor(accent);

        return FluentApp.router(
          routerConfig: ref.read(appRouterProvider),
          title: 'Revision Tool',
          debugShowCheckedModeBanner: false,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: const [FluentLocalizations.delegate],
          themeMode: appSettings.themeMode,
          color: accentColor,
          darkTheme: settingsNotifier.buildDarkTheme(
            accentColor,
            isLargeScreen,
          ),
          theme: settingsNotifier.buildLightTheme(accentColor, isLargeScreen),
          builder: (context, child) {
            settingsNotifier.setEffect(
              FluentTheme.of(context).micaBackgroundColor,
              FluentTheme.of(context).brightness == .dark,
            );
            return Directionality(
              textDirection: appSettings.textDirection,
              child: child!,
            );
          },
        );
      },
    );
  }
}
