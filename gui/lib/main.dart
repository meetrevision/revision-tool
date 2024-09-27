import 'dart:async';

import 'package:common/common.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:revitool/l10n/generated/localizations.dart';

import 'package:revitool/providers/l10n_provider.dart';
import 'package:revitool/screens/home_page.dart';
import 'package:provider/provider.dart';

import 'package:revitool/theme.dart';
import 'package:revitool/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  logger.i('Revision Tool is starting');

  if (WinRegistryService.isSupported) {
    logger.i('isSupported is true');
    _isSupported = true;
  }

  if (WinRegistryService.readString(RegistryHive.localMachine,
          r'SOFTWARE\Revision\Revision Tool', 'ThemeMode') ==
      null) {
    logger.i('Creating Revision registry keys');
    WinRegistryService.writeString(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'ThemeMode', ThemeMode.system.name);
    WinRegistryService.writeDword(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Experimental', 0);
    WinRegistryService.writeString(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Language', 'en_US');
  }

  logger.i('Initializing settings controller');
  final settingsController = AppTheme(SettingsService());
  await settingsController.loadSettings();
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

  runApp(const MyApp());
}

bool _isSupported = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppTheme(SettingsService())),
        ChangeNotifierProvider(create: (_) => L10nProvider(appLanguage)),
      ],
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        final appLocale = context.watch<L10nProvider>().locale;
        return FluentApp(
          title: 'Revision Tool',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            FluentLocalizations.delegate,
            ReviLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          locale: appLocale,
          supportedLocales: ReviLocalizations.supportedLocales,
          themeMode: appTheme.themeMode,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            navigationPaneTheme: NavigationPaneThemeData(
              backgroundColor: appTheme.effectColor(null),
            ),
            scaffoldBackgroundColor:
                appTheme.effectColor(const Color.fromARGB(255, 32, 32, 32)),
            // cardColor: Color(0xFF2B2B2B),
            cardColor: appTheme.effectColor(
                const Color.fromARGB(255, 255, 255, 255).withOpacity(0.05),
                modifyColors: true),
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
            resources: ResourceDictionary.dark(
              cardStrokeColorDefault: appTheme.effectColor(
                  const Color.fromARGB(255, 29, 29, 29),
                  modifyColors: true)!,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            navigationPaneTheme: NavigationPaneThemeData(
              backgroundColor: appTheme.effectColor(null),
            ),
            scaffoldBackgroundColor: appTheme.effectColor(
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
            appTheme.setEffect(appTheme.windowEffect, context);

            return Directionality(
              textDirection: appTheme.textDirection,
              child: child!,
            );
          },
        );
      },
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
