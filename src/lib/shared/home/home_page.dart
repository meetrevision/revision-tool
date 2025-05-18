import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:process_run/shell_run.dart';
import 'package:revitool/core/performance/performance_page.dart';
import 'package:revitool/core/usability/usability_page.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/core/miscellaneous/miscellaneous_page.dart';
import 'package:revitool/core/ms_store/ms_store_page.dart';
import 'package:revitool/core/security/security_page.dart';
import 'package:revitool/core/win_updates/updates_page.dart';
import 'package:revitool/shared/settings/settings_page.dart';
import 'package:revitool/utils_gui.dart';
import 'package:win32_registry/win32_registry.dart';
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
    // final theme = context.theme;

    final items = <NavigationPaneItem>[
      PaneItem(
        icon: const Icon(msicons.FluentIcons.home_24_regular, size: 20),
        title: Text(context.l10n.pageHome),
        body: const _Home(),
      ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.window_shield_24_regular,
          size: 20,
        ),
        title: Text(context.l10n.pageSecurity),
        body: const SecurityPage(),
      ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.search_square_24_regular,
          size: 20,
        ),
        title: Text(context.l10n.pageUsability),
        body: const UsabilityPage(),
      ),
      PaneItem(
        icon: const Icon(msicons.FluentIcons.top_speed_24_regular, size: 20),
        title: Text(context.l10n.pagePerformance),
        body: const PerformancePage(),
      ),
      PaneItem(
        icon: const Icon(
          msicons.FluentIcons.dual_screen_update_24_regular,
          size: 20,
        ),
        title: Text(context.l10n.pageUpdates),
        body: const WinUpdatesPage(),
      ),
      PaneItem(
        icon: const Icon(msicons.FluentIcons.toolbox_24_regular, size: 20),
        title: Text(context.l10n.pageMiscellaneous),
        body: const MiscellaneousPage(),
      ),
    ];

    return SafeArea(
      child: NavigationView(
        key: _viewKey,
        contentShape: const RoundedRectangleBorder(
          side: BorderSide(width: 0, color: Colors.transparent),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0)),
        ),
        appBar: NavigationAppBar(
          automaticallyImplyLeading: false,
          title: const Text('Revision Tool'),
          actions: WindowCaption(),
        ),
        pane: NavigationPane(
          size: NavigationPaneSize(openWidth: 300),
          selected: _topIndex ?? 0,
          onChanged: (index) => setState(() => _topIndex = index),
          displayMode:
              context.mqSize.width >= 800
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
                      'C:\\ProgramData\\Microsoft\\User Account Pictures\\user-192.png',
                    ),
                  ),
                ),
                const SizedBox(width: 13.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Registry.openPath(
                        RegistryHive.currentUser,
                        path: r'Volatile Environment',
                      ).getStringValue("USERNAME")!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      "Proud ReviOS user",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          autoSuggestBox: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AutoSuggestBox(
              key: _searchKey,

              trailingIcon: const Padding(
                padding: EdgeInsets.only(right: 7.0, bottom: 2),
                child: Icon(msicons.FluentIcons.search_20_regular),
              ),
              focusNode: _searchFocusNode,
              controller: _searchController,
              placeholder: context.l10n.suggestionBoxPlaceholder,
              items:
                  items.whereType<PaneItem>().map((page) {
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
              title: Text(context.l10n.pageSettings),
              body: const SettingsPage(),
            ),
            PaneItemSeparator(color: Colors.transparent),
          ],
        ),
        onOpenSearch: () => _searchFocusNode.requestFocus(),
      ),
    );
  }
}

final _homeCardButtons = [
  CardButtonWidget(
    icon: FluentIcons.git_graph,
    title: "GitHub",
    subtitle: "Source Code",
    onPressed:
        () async => await run(
          "rundll32 url.dll,FileProtocolHandler https://github.com/meetrevision",
        ),
  ),
  CardButtonWidget(
    icon: msicons.FluentIcons.drink_coffee_20_regular,
    title: "Donation",
    subtitle: "Support the project",
    onPressed:
        () async => await run(
          "rundll32 url.dll,FileProtocolHandler https://revi.cc/donate",
        ),
  ),
  CardButtonWidget(
    icon: msicons.FluentIcons.chat_help_20_regular,
    title: "Discord",
    subtitle: "Join our server",
    onPressed:
        () async => await run(
          "rundll32 url.dll,FileProtocolHandler https://discord.gg/962y4pU",
        ),
  ),
];

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return context.mqSize.width >= 800 && context.mqSize.height >= 400
        ? Padding(
          padding: kScaffoldPagePadding,
          child: ScaffoldPage(
            content: _HomePageContent(),
            bottomBar: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Flex(
                direction: Axis.horizontal,
                spacing: 5,
                children:
                    _homeCardButtons
                        .map(
                          (e) => Expanded(
                            child: LimitedBox(maxHeight: 90, child: e),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        )
        : ScaffoldPage.scrollable(
          padding: kScaffoldPagePadding,
          children: [
            const _HomePageContent(),
            const SizedBox(height: 5),
            Wrap(
              runSpacing: 5,
              children: _homeCardButtons.map((e) => e).toList(),
            ),
          ],
        );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient:
            context.theme.brightness.isDark
                ? const LinearGradient(
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.85),
                    Color.fromRGBO(0, 0, 0, 0.43),
                    Color.fromRGBO(0, 0, 0, 0),
                  ],
                  stops: [0.0, 0.4, 1.0],
                )
                : const LinearGradient(
                  colors: [
                    Color.fromRGBO(16, 16, 16, 0.8),
                    Color.fromRGBO(155, 155, 155, 0.5),
                    Color.fromRGBO(255, 255, 255, 0),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.homeWelcome,
              style: const TextStyle(fontSize: 16, color: Color(0xB7FFFFFF)),
            ),
            const Text(
              "Revision Tool",
              style: TextStyle(fontSize: 28, color: Color(0xFFffffff)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                context.l10n.homeDescription,
                style: const TextStyle(fontSize: 16, color: Color(0xB7FFFFFF)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: SizedBox(
                width: 175,
                child: Button(
                  child: Text(context.l10n.homeReviLink),
                  onPressed:
                      () async => await run(
                        "rundll32 url.dll,FileProtocolHandler https://www.revi.cc",
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SizedBox(
                width: 175,
                child: FilledButton(
                  child: Text(context.l10n.homeReviFAQLink),
                  onPressed:
                      () async => await run(
                        "rundll32 url.dll,FileProtocolHandler https://www.revi.cc/docs/category/faq",
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
