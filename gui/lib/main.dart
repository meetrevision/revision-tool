import 'dart:async';

import 'package:common/common.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/l10n/generated/localizations.dart';

import 'package:revitool/screens/home_page.dart';

import 'package:revitool/providers/app_settings_notifier.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  logger.i('Revision Tool GUI is starting');

  if (WinRegistryService.isSupported) {
    logger.i('isSupported is true');
    _isSupported = true;
  }

  if (WinRegistryService.readString(RegistryHive.localMachine,
          r'SOFTWARE\Revision\Revision Tool', 'ThemeMode') ==
      null) {
    logger.i('Creating Revision registry keys');
    WinRegistryService.writeRegistryValue(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'ThemeMode', ThemeMode.system.name);
    WinRegistryService.writeRegistryValue(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Experimental', 0);
    WinRegistryService.writeRegistryValue(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Language', 'en_US');
  }

  logger.i('Initializing settings controller');
  await SystemTheme.accentColor.load();
  await Window.initialize();
  await Window.hideWindowControls();

  logger.i('Initializing WindowPlus');
  await WindowPlus.ensureInitialized(
    application: 'revision-tool',
    enableCustomFrame: true,
    enableEventStreams: false,
  );
  await WindowPlus.instance.setMinimumSize(const Size(515, 330));

  runApp(ProviderScope(child: const MyApp()));
}

bool _isSupported = false;

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsNotifierProvider);

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
                .watch(appSettingsNotifierProvider.notifier)
                .effectColor(null),
          ),
          scaffoldBackgroundColor: ref
              .watch(appSettingsNotifierProvider.notifier)
              .effectColor(const Color.fromARGB(255, 32, 32, 32)),
          // cardColor: Color(0xFF2B2B2B),
          cardColor: ref
              .watch(appSettingsNotifierProvider.notifier)
              .effectColor(
                  const Color.fromARGB(255, 255, 255, 255)
                      .withValues(alpha: 0.05),
                  modifyColors: true),
          visualDensity: VisualDensity.standard,
          focusTheme: FocusThemeData(
            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
          ),
          resources: ResourceDictionary.dark(
            cardStrokeColorDefault: ref
                .watch(appSettingsNotifierProvider.notifier)
                .effectColor(const Color.fromARGB(255, 29, 29, 29),
                    modifyColors: true)!,
          ),
        ),
        theme: FluentThemeData(
          accentColor: getSystemAccentColor(accent),
          visualDensity: VisualDensity.standard,
          navigationPaneTheme: NavigationPaneThemeData(
            backgroundColor: ref
                .watch(appSettingsNotifierProvider.notifier)
                .effectColor(null),
          ),
          scaffoldBackgroundColor:
              ref.watch(appSettingsNotifierProvider.notifier).effectColor(
                    const Color.fromRGBO(243, 243, 243, 100),
                  ),
          focusTheme: FocusThemeData(
            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
          ),
          resources: const ResourceDictionary.light(
            cardStrokeColorDefault: Color.fromARGB(255, 229, 229, 229),
          ),
        ), // TODO: make it compatible with windoweffect
        home: _isSupported ? const HomePage() : const _UnsupportedError(),
        builder: (context, child) {
          ref.watch(appSettingsNotifierProvider.notifier).setEffect(
              FluentTheme.of(context).micaBackgroundColor,
              FluentTheme.of(context).brightness.isDark);

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
