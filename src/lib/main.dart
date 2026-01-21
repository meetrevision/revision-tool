import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/routing/app_router.dart';

import 'package:revitool/core/settings/app_settings_provider.dart';
import 'package:revitool/core/settings/locale_config.dart';
import 'package:revitool/core/trusted_installer/trusted_installer_service.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/i18n/generated/strings.g.dart';
import 'package:revitool/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';

String? initialRoute;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  const tag = 'gui_main:';

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
    final savedLocale = LocaleConfig.parse(appLanguage);
    LocaleSettings.setLocale(savedLocale);
  } catch (e) {
    logger.w('$tag Failed to set locale: $e');
    LocaleSettings.setLocale(AppLocale.en);
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
    final appSettings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return SystemThemeBuilder(
      builder: (context, accent) => FluentApp.router(
        routerConfig: ref.read(appRouterProvider),
        title: 'Revision Tool',
        debugShowCheckedModeBanner: false,
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: const [FluentLocalizations.delegate],
        themeMode: appSettings.themeMode,
        color: getSystemAccentColor(accent),
        darkTheme: FluentThemeData(
          brightness: Brightness.dark,
          accentColor: getSystemAccentColor(accent),

          navigationPaneTheme: NavigationPaneThemeData(
            backgroundColor: settingsNotifier.effectColor(null),
          ),
          scaffoldBackgroundColor: settingsNotifier.effectColor(
            const Color.fromARGB(255, 32, 32, 32),
          ),
          // cardColor: Color(0xFF2B2B2B),
          cardColor: ref
              .watch(appSettingsProvider.notifier)
              .effectColor(
                const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withValues(alpha: 0.05),
                modifyColors: true,
              ),
          visualDensity: VisualDensity.standard,
          focusTheme: FocusThemeData(
            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
          ),
          resources: ResourceDictionary.dark(
            cardStrokeColorDefault: settingsNotifier.effectColor(
              const Color(0xFF1D1D1D),
              modifyColors: true,
            )!,
            cardBackgroundFillColorSecondary: const Color(0xFF323232),
          ),
        ),
        theme: FluentThemeData(
          accentColor: getSystemAccentColor(accent),
          visualDensity: VisualDensity.standard,
          navigationPaneTheme: NavigationPaneThemeData(
            backgroundColor: settingsNotifier.effectColor(null),
          ),
          scaffoldBackgroundColor: settingsNotifier.effectColor(
            const Color.fromRGBO(243, 243, 243, 100),
          ),
          focusTheme: FocusThemeData(
            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
          ),
          resources: const ResourceDictionary.light(
            cardStrokeColorDefault: Color.fromARGB(255, 229, 229, 229),
            cardBackgroundFillColorSecondary: Color(0xFFF6F6F6),
          ),
        ), // TODO: make it compatible with windoweffect
        builder: (context, child) {
          settingsNotifier.setEffect(
            FluentTheme.of(context).micaBackgroundColor,
            FluentTheme.of(context).brightness.isDark,
          );

          return Directionality(
            textDirection: appSettings.textDirection,
            child: child!,
          );
        },
      ),
    );
  }
}
