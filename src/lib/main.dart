import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/l10n/generated/localizations.dart';

import 'package:revitool/shared/home/home_page.dart';

import 'package:revitool/shared/settings/app_settings_provider.dart';
import 'package:revitool/shared/trusted_installer/trusted_installer_service.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';

Future<void> main() async {
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
      'en_US',
    );
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

  runApp(const ProviderScope(child: MyApp()));
}

bool _isSupported = false;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);

    return SystemThemeBuilder(
      builder: (context, accent) => FluentApp(
        title: 'Revision Tool',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          FluentLocalizations.delegate,
          ReviLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        locale: appSettings.locale,
        supportedLocales: ReviLocalizations.supportedLocales,
        themeMode: appSettings.themeMode,
        color: getSystemAccentColor(accent),
        darkTheme: FluentThemeData(
          brightness: Brightness.dark,
          accentColor: getSystemAccentColor(accent),

          navigationPaneTheme: NavigationPaneThemeData(
            backgroundColor: ref
                .watch(appSettingsProvider.notifier)
                .effectColor(null),
          ),
          scaffoldBackgroundColor: ref
              .watch(appSettingsProvider.notifier)
              .effectColor(const Color.fromARGB(255, 32, 32, 32)),
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
            cardStrokeColorDefault: ref
                .watch(appSettingsProvider.notifier)
                .effectColor(
                  const Color.fromARGB(255, 29, 29, 29),
                  modifyColors: true,
                )!,
          ),
        ),
        theme: FluentThemeData(
          accentColor: getSystemAccentColor(accent),
          visualDensity: VisualDensity.standard,
          navigationPaneTheme: NavigationPaneThemeData(
            backgroundColor: ref
                .watch(appSettingsProvider.notifier)
                .effectColor(null),
          ),
          scaffoldBackgroundColor: ref
              .watch(appSettingsProvider.notifier)
              .effectColor(const Color.fromRGBO(243, 243, 243, 100)),
          focusTheme: FocusThemeData(
            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
          ),
          resources: const ResourceDictionary.light(
            cardStrokeColorDefault: Color.fromARGB(255, 229, 229, 229),
          ),
        ), // TODO: make it compatible with windoweffect
        home: _isSupported ? const HomePage() : const _UnsupportedError(),
        builder: (context, child) {
          ref
              .watch(appSettingsProvider.notifier)
              .setEffect(
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

class _UnsupportedError extends StatelessWidget {
  const _UnsupportedError();

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: ContentDialog(
        title: const Text("Error"),
        content: const Text("Unsupported build detected"),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () {
              WindowPlus.instance.close();
            },
          ),
        ],
      ),
    );
  }
}
