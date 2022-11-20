import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/screens/pages/PerformancePage.dart';
import 'package:revitool/screens/pages/security_page.dart';
import 'package:revitool/screens/pages/updates_page.dart';
import 'package:revitool/screens/pages/usability_page.dart';
import 'package:revitool/screens/pages/usability_page_two.dart';
import 'package:revitool/screens/settings.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/windows_buttons.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? topIndex;
  bool maximize = true;

  final pages = <String>[
    'Security',
    'Usability',
    'Performance',
    'Windows Updates',
  ];

  AutoSuggestBoxItem<String?>? selectedPage;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    // final theme = FluentTheme.of(context);

    return SafeArea(
      child: NavigationView(
        appBar: NavigationAppBar(
          title: const Text('Revision Tool'),
          // automaticallyImplyLeading: false,
          actions: Stack(
            children: [
              MoveWindow(),
              WindowTitleBarBox(child: const WindowButtons()),
            ],
          ),
        ),
        pane: NavigationPane(
          selected: topIndex ?? 0,
          onChanged: (index) => setState(() => topIndex = index),
          displayMode: MediaQuery.of(context).size.width >= 800 ? PaneDisplayMode.open : PaneDisplayMode.minimal,
          // autoSuggestBox: const TextBox(),
          // autoSuggestBoxReplacement: const Icon(FluentIcons.search),
          header: SizedBox(
            height: 80,

            // height: kOneLineTileHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 5.0),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                  child: Image.file(
                    width: 60,
                    height: 60,
                    File('C:\\ProgramData\\Microsoft\\User Account Pictures\\user-192.png'),
                  ),
                ),
                const SizedBox(width: 15.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${Registry.openPath(RegistryHive.currentUser, path: r'Volatile Environment').getValueAsString("USERNAME")}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Text(
                      "Proud ReviOS user",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          autoSuggestBox: AutoSuggestBox<String?>(
            placeholder: "Find a setting",
            items: pages.map((page) {
              return AutoSuggestBoxItem<String?>(
                  value: page,
                  label: page,
                  onFocusChange: (focused) {
                    if (focused) {
                      debugPrint('Focused $page');
                    }
                  });
            }).toList(),
            onSelected: (item) {
              setState(() => selectedPage = item);
            },
          ),

          autoSuggestBoxReplacement: const Icon(FluentIcons.search),
          // footerItems: searchValue.isNotEmpty ? [] : footerItems,

          items: [
            PaneItem(
              icon: const Icon(FluentIcons.home),
              title: const Text('Home'),
              body: const Home(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.defender_app),
              title: const Text('Security'),
              body: const SecurityPage(),
            ),
            readRegistryString(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'CurrentBuildNumber') != "19045"
                ? PaneItemExpander(
                    icon: const Icon(FluentIcons.search_and_apps),
                    title: const Text('Usability'),
                    body: const UsabilityPage(),
                    items: [
                      PaneItem(
                        icon: const Icon(FluentIcons.user_window),
                        title: const Text('Windows 11'),
                        body: const UsabilityPageTwo(),
                      ),
                    ],
                  )
                : PaneItem(
                    icon: const Icon(FluentIcons.search_and_apps),
                    title: const Text('Usability'),
                    body: const UsabilityPage(),
                  ),
            PaneItem(
              icon: const Icon(FluentIcons.speed_high),
              title: const Text('Performance'),
              body: const PerformancePage(),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.update_restore),
              title: const Text('Windows Updates'),
              body: const UpdatesPage(),
            ),
          ],
          footerItems: [
            PaneItemSeparator(),
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('Settings'),
              body: const SettingsPage(),
            ),
            PaneItemSeparator(),
          ],
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      resizeToAvoidBottomInset: false,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (MediaQuery.of(context).size.height >= 400) ...[
                const SizedBox(
                  height: 100,
                )
              ] else ...[
                const SizedBox(
                  height: 25,
                )
              ],
              Text(
                "Welcome to Revision",
                style: FluentTheme.of(context).brightness.isDark ? const TextStyle(fontSize: 16, color: Color(0xB7FFFFFF)) : const TextStyle(fontSize: 16, color: Color.fromARGB(255, 117, 117, 117)),
              ),
              const Text(
                "Revision Tool",
                style: TextStyle(fontSize: 28),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "A tool to personalize ReviOS to your needs",
                  style: FluentTheme.of(context).brightness.isDark ? const TextStyle(fontSize: 16, color: Color(0xB7FFFFFF)) : const TextStyle(fontSize: 16, color: Color.fromARGB(255, 117, 117, 117)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: SizedBox(
                  width: 175,
                  child: Button(
                    child: const Text("Check out Revision"),
                    onPressed: () async {
                      await run("rundll32 url.dll,FileProtocolHandler https://www.revi.cc");
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: SizedBox(
                  width: 175,
                  child: FilledButton(
                    child: const Text("Check out FAQ"),
                    onPressed: () async {
                      await run("rundll32 url.dll,FileProtocolHandler https://revios.rignoa.com");
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
