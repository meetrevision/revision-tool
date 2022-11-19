import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/screens/homePage.dart';
import 'package:provider/provider.dart';
import 'package:revitool/theme.dart';
import 'package:revitool/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await windowManager.ensureInitialized();
  // WindowOptions windowOptions = const WindowOptions(
  //   fullScreen: true,
  //   minimumSize: Size(515, 330),
  //   center: true,
  //   backgroundColor: Colors.transparent,
  //   skipTaskbar: false,
  //   titleBarStyle: TitleBarStyle.hidden,
  //   title: "Revision Tool",
  // );
  // windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });
  await SystemTheme.accentColor.load();
  doWhenWindowReady(() async {
    appWindow.minSize = const Size(515, 330);
    appWindow.alignment = Alignment.center;
    Size mySize = appWindow.size;
    final size = Size(mySize.width, mySize.height);
    appWindow.size = size;
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      appWindow.size = size + const Offset(0, 1);
    });

    appWindow.show();
  });

  final buildNumber = int.parse(readRegistryString(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\', 'CurrentBuildNumber') as String);

  if (readRegistryString(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'EditionSubVersion') == "ReviOS") {
    if (buildNumber > 19044) {
      runApp(const MyApp(isSupported: true));
    } else {
      runApp(const MyApp(isSupported: false));
    }
  } else {
    runApp(const MyApp(isSupported: false));
  }
}

class MyApp extends StatelessWidget {
  final bool isSupported;

  const MyApp({super.key, required this.isSupported});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp(
          title: 'Revision Tool',
          debugShowCheckedModeBanner: false,
          themeMode: appTheme.mode,
          color: appTheme.color,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            // scaffoldBackgroundColor: const Color.fromRGBO(32, 32, 32, 100),
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          theme: ThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            // scaffoldBackgroundColor: const Color.fromRGBO(243, 243, 243, 100),
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          home: isSupported ? const HomePage() : const UnsupportedError(),
        );
      },
    );
  }
}

class UnsupportedError extends StatelessWidget {
  const UnsupportedError({super.key});

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
              appWindow.close();
            },
          ),
        ],
      ),
    );
  }
}
