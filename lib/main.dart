import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:revitool/commands/ms_store_command.dart';
import 'package:revitool/commands/recommendation_command.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/screens/home_page.dart';
import 'package:provider/provider.dart';
import 'package:revitool/theme.dart';
import 'package:revitool/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final path = p.join(Directory.systemTemp.path, 'Revision-Tool', 'Logs');

  initLogger(path);
  i('Revision Tool is starting');

  if (registryUtilsService.readString(
              RegistryHive.localMachine,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubVersion') ==
          'ReviOS' &&
      buildNumber > 19043) {
    i('isSupported is true');
    _isSupported = true;
  }

  if (args.isNotEmpty) {
    if (!_isSupported) {
      // TODO: unify messages
      e('Unsupported build detected. Please apply ReviOS on your system');
      stderr.writeln(
        'Unsupported build detected. Please apply ReviOS on your system',
      );
      exit(55);
    }
    final packageInfo = await PackageInfo.fromPlatform();
    stdout.writeln("Running Revision Tool ${packageInfo.version}");
    final runner = CommandRunner<String>("revitool", "Revision Tool CLI")
      ..addCommand(MSStoreCommand());
    // ..addCommand(RecommendationCommand());
    await runner.run(args);
    exit(0);
  }

  WidgetsFlutterBinding.ensureInitialized();

  if (registryUtilsService.readString(RegistryHive.localMachine,
          r'SOFTWARE\Revision\Revision Tool', 'ThemeMode') ==
      null) {
    i('Creating Revision registry keys');
    registryUtilsService.writeString(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'ThemeMode', ThemeMode.system.name);
    registryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Experimental', 0);
    registryUtilsService.writeString(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Language', 'en_US');
  }

  i('Initializing settings controller');
  final settingsController = AppTheme(SettingsService());
  await settingsController.loadSettings();
  await SystemTheme.accentColor.load();

  i('Initializing WindowPlus');
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
    return ChangeNotifierProvider(
      create: (_) => AppTheme(SettingsService()),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp(
          title: 'Revision Tool',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            FluentLocalizations.delegate,
            ReviLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          locale: Locale(appLanguage.split('_')[0], appLanguage.split('_')[1]),
          supportedLocales: ReviLocalizations.supportedLocales,
          themeMode: appTheme.themeMode,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            scaffoldBackgroundColor: const Color.fromARGB(255, 32, 32, 32),
            cardColor: const Color.fromARGB(255, 43, 43, 43),
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
            resources: const ResourceDictionary.dark(
              cardStrokeColorDefault: Color.fromARGB(255, 29, 29, 29),
            ),
          ),
          theme: FluentThemeData(
              accentColor: appTheme.color,
              visualDensity: VisualDensity.standard,
              scaffoldBackgroundColor: const Color.fromRGBO(243, 243, 243, 100),
              cardColor: const Color.fromARGB(255, 251, 251, 251),
              focusTheme: FocusThemeData(
                glowFactor: is10footScreen(context) ? 2.0 : 0.0,
              ),
              resources: const ResourceDictionary.light(
                  cardStrokeColorDefault: Color.fromARGB(255, 229, 229, 229))),
          home: _isSupported ? const HomePage() : const _UnsupportedError(),
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
