import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/screens/pages/miscellaneous_page.dart';
import 'package:revitool/screens/pages/ms_store_page.dart';
import 'package:revitool/screens/pages/performance_page.dart';
import 'package:revitool/screens/pages/security_page.dart';
import 'package:revitool/screens/pages/updates_page.dart';
import 'package:revitool/screens/pages/usability_page.dart';
import 'package:revitool/screens/pages/usability_page_two.dart';
import 'package:revitool/screens/settings.dart';
import 'package:revitool/utils.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:window_plus/window_plus.dart';

import '../widgets/card_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _topIndex;
  final _viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final _searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();

  AutoSuggestBoxItem? selectedPage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    // final theme = FluentTheme.of(context);

    final List<NavigationPaneItem> items = [
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.home_24_regular,
          size: 20,
        ),
        title: Text(ReviLocalizations.of(context).pageHome),
        body: const Home(),
      ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.window_shield_24_regular,
          size: 20,
        ),
        title: Text(ReviLocalizations.of(context).pageSecurity),
        body: const SecurityPage(),
      ),
      w11
          ? PaneItemExpander(
              icon: const Icon(
                msicons.FluentIcons.search_square_24_regular,
                size: 20,
              ),
              title: Text(ReviLocalizations.of(context).pageUsability),
              body: const UsabilityPage(),
              items: [
                PaneItem(
                  icon: const Icon(
                    msicons.FluentIcons.window_apps_24_regular,
                    size: 20,
                  ),
                  title: const Text('Windows 11'),
                  body: const UsabilityPageTwo(),
                ),
              ],
            )
          : PaneItem(
              icon: const Icon(
                msicons.FluentIcons.search_square_24_regular,
                size: 20,
              ),
              title: Text(ReviLocalizations.of(context).pageUsability),
              body: const UsabilityPage(),
            ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.top_speed_24_regular,
          size: 20,
        ),
        title: Text(ReviLocalizations.of(context).pagePerformance),
        body: const PerformancePage(),
      ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.dual_screen_update_24_regular,
          size: 20,
        ),
        title: Text(ReviLocalizations.of(context).pageUpdates),
        body: const UpdatesPage(),
      ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.toolbox_24_regular,
          size: 20,
        ),
        title: Text(ReviLocalizations.of(context).pageMiscellaneous),
        body: const MiscellaneousPage(),
      ),
    ];

    return SafeArea(
      child: NavigationView(
        key: _viewKey,
        contentShape: const RoundedRectangleBorder(
          side: BorderSide(width: 0, color: Colors.transparent),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.0),
          ),
        ),
        appBar: NavigationAppBar(
          automaticallyImplyLeading: false,
          title: const Text('Revision Tool'),
          actions: WindowCaption(),
        ),
        pane: NavigationPane(
          selected: _topIndex ?? 0,
          onChanged: (index) => setState(() => _topIndex = index),
          displayMode: MediaQuery.of(context).size.width >= 800
              ? PaneDisplayMode.open
              : PaneDisplayMode.minimal,
          header: SizedBox(
            height: 90,
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
                    File(
                        'C:\\ProgramData\\Microsoft\\User Account Pictures\\user-192.png'),
                  ),
                ),
                const SizedBox(width: 13.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Registry.openPath(RegistryHive.currentUser,
                              path: r'Volatile Environment')
                          .getValueAsString("USERNAME")!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const Text(
                      "Proud ReviOS user",
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.normal),
                    ),
                  ],
                )
              ],
            ),
          ),
          autoSuggestBox: AutoSuggestBox(
            key: _searchKey,
            trailingIcon: const Padding(
              padding: EdgeInsets.only(right: 7.0, bottom: 2),
              child: Icon(
                msicons.FluentIcons.search_20_regular,
              ),
            ),
            focusNode: _searchFocusNode,
            controller: _searchController,
            placeholder: ReviLocalizations.of(context).suggestionBoxPlaceholder,
            items: items.whereType<PaneItem>().map((page) {
              assert(page.title is Text);
              final text = (page.title as Text).data!;
              return AutoSuggestBoxItem(
                value: text,
                label: text,
                onSelected: () async {
                  final itemIndex = NavigationPane(
                    items: items,
                  ).effectiveIndexOf(page);

                  setState(() => _topIndex = itemIndex);
                  await Future.delayed(const Duration(milliseconds: 17));
                  _searchController.clear();
                },
              );
            }).toList(),
            onSelected: (item) {
              setState(() => selectedPage = item);
            },
          ),

          autoSuggestBoxReplacement: const Icon(FluentIcons.search),
          // footerItems: searchValue.isNotEmpty ? [] : footerItems,
          items: items,
          footerItems: [
            PaneItem(
              icon: const Icon(
                msicons.FluentIcons.store_microsoft_24_regular,
                size: 20,
              ),
              title: const Text("MS Store"),
              body: const MSStorePage(),
            ),
            PaneItem(
              icon: const Icon(
                msicons.FluentIcons.settings_24_regular,
                size: 20,
              ),
              title: Text(ReviLocalizations.of(context).pageSettings),
              body: const SettingsPage(),
            ),
            PaneItemSeparator(color: Colors.transparent),
          ],
        ),
        onOpenSearch: () {
          _searchFocusNode.requestFocus();
        },
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  static final _homeCardButtons = [
    CardButtonWidget(
      icon: FluentIcons.git_graph,
      title: "GitHub",
      subtitle: "Source Code",
      onPressed: () async => await run(
          "rundll32 url.dll,FileProtocolHandler https://github.com/meetrevision"),
    ),
    CardButtonWidget(
      icon: msicons.FluentIcons.drink_coffee_20_regular,
      title: "Donation",
      subtitle: "Support the project",
      onPressed: () async => await run(
          "rundll32 url.dll,FileProtocolHandler https://www.buymeacoffee.com/meetrevision"),
    ),
    CardButtonWidget(
      icon: msicons.FluentIcons.chat_help_20_regular,
      title: "Discord",
      subtitle: "Join our server",
      onPressed: () async => await run(
          "rundll32 url.dll,FileProtocolHandler https://www.revi.cc/docs/faq"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      resizeToAvoidBottomInset: false,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 16,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: FluentTheme.of(context).brightness.isDark
                    ? const LinearGradient(
                        colors: [
                          Color.fromRGBO(0, 0, 0, 0.85),
                          Color.fromRGBO(0, 0, 0, 0.43),
                          Color.fromRGBO(0, 0, 0, 0)
                        ],
                        stops: [0.0, 0.4, 1.0],
                      )
                    : const LinearGradient(
                        colors: [
                          Color.fromRGBO(16, 16, 16, 0.8),
                          Color.fromRGBO(155, 155, 155, 0.5),
                          Color.fromRGBO(255, 255, 255, 0)
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
              ),
              padding: const EdgeInsets.only(left: 50, top: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ReviLocalizations.of(context).homeWelcome,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xB7FFFFFF))),
                  const Text(
                    "Revision Tool",
                    style: TextStyle(
                      fontSize: 28,
                      color: Color(0xFFffffff),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(ReviLocalizations.of(context).homeDescription,
                        style: const TextStyle(
                            fontSize: 16, color: Color(0xB7FFFFFF))
                        //     : const TextStyle(
                        //         fontSize: 16,
                        //         color: Color.fromARGB(255, 117, 117, 117)),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: SizedBox(
                      width: 175,
                      child: Button(
                        child: Text(ReviLocalizations.of(context).homeReviLink),
                        onPressed: () async => await run(
                            "rundll32 url.dll,FileProtocolHandler https://www.revi.cc"),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: SizedBox(
                      width: 175,
                      child: FilledButton(
                        child:
                            Text(ReviLocalizations.of(context).homeReviFAQLink),
                        onPressed: () async => await run(
                            "rundll32 url.dll,FileProtocolHandler https://www.revi.cc/docs/faq"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 0, left: 3),
          child: MediaQuery.of(context).size.width >= 800
              // spacing: 5, runSpacing: 5
              ? Flex(
                  direction: Axis.horizontal,
                  children: _homeCardButtons
                      .map((e) => Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: e,
                            ),
                          ))
                      .toList())
              : Column(
                  children: _homeCardButtons
                      .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 3), child: e))
                      .toList()),
        ),
      ],
    );
  }
}
