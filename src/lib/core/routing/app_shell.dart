import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:go_router/go_router.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/core/widgets/page_header_with_breadcrumbs.dart';

import 'package:revitool/extensions.dart';
import 'package:revitool/core/routing/app_routes.dart';
import 'package:revitool/core/routing/app_router.dart';
import 'package:revitool/i18n/generated/strings.g.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_plus/window_plus.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.shellContext});
  final Widget child;
  final BuildContext? shellContext;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final _searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  static const imgXY = 60.0;
  AutoSuggestBoxItem? selectedPage;

  final String? _username = WinRegistryService.readString(
    RegistryHive.currentUser,
    r'Volatile Environment',
    'USERNAME',
  );

  static final File _userImageFile = File(
    'C:\\ProgramData\\Microsoft\\User Account Pictures\\user-192.png',
  );

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

  /// Calculate the selected index based on current location
  int _calculateSelectedIndex(
    BuildContext context,
    List<NavigationPaneItem> items,
    List<NavigationPaneItem> footerItems,
  ) {
    final location = GoRouterState.of(context).uri.toString();
    final itemsWithKeys = items.where((item) => item.key != null).toList();
    final footerWithKeys = footerItems
        .where((item) => item.key != null)
        .toList();

    int exactMatch = itemsWithKeys.indexWhere(
      (item) => item.key == Key(location),
    );
    if (exactMatch != -1) return exactMatch;

    for (int i = 0; i < itemsWithKeys.length; i++) {
      final itemPath = (itemsWithKeys[i].key as ValueKey).value as String;
      if (itemPath != '/' && location.startsWith(itemPath)) {
        return i;
      }
    }

    int footerMatch = footerWithKeys.indexWhere(
      (item) => item.key == Key(location),
    );
    if (footerMatch != -1) {
      return itemsWithKeys.length + footerMatch;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final imgCacheSize = (imgXY * MediaQuery.devicePixelRatioOf(context))
        .toInt();

    final items =
        <NavigationPaneItem>[
          PaneItem(
            key: const ValueKey(AppRoutes.home),
            icon: const Icon(msicons.FluentIcons.home_24_regular, size: 20),
            title: Text(t.pageHome),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            key: const ValueKey(AppRoutes.tweaks),
            icon: const Icon(msicons.FluentIcons.wrench_24_regular, size: 20),
            title: Text(t.pageTweaks),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            key: const ValueKey(AppRoutes.msStore),
            icon: const Icon(
              msicons.FluentIcons.store_microsoft_24_regular,
              size: 20,
            ),
            title: Text(t.pageMSStore),
            body: const SizedBox.shrink(),
          ),
        ].map<NavigationPaneItem>((e) {
          PaneItem buildPaneItem(PaneItem item) {
            return PaneItem(
              key: item.key,
              icon: item.icon,
              title: item.title,
              body: item.body,
              onTap: () {
                final path = (item.key as ValueKey).value;
                if (GoRouterState.of(context).uri.toString() != path) {
                  context.push(path);
                }
                item.onTap?.call();
              },
            );
          }

          if (e is PaneItemExpander) {
            return PaneItemExpander(
              key: e.key,
              icon: e.icon,
              title: e.title,
              body: e.body,
              items: e.items.map((item) {
                if (item is PaneItem) return buildPaneItem(item);
                return item;
              }).toList(),
            );
          }
          if (e is PaneItem) return buildPaneItem(e);
          return e;
        }).toList();

    final footerItems = <NavigationPaneItem>[
      PaneItem(
        key: const ValueKey(AppRoutes.settings),
        icon: const Icon(msicons.FluentIcons.settings_24_regular, size: 20),
        title: Text(t.pageSettings),
        body: const SizedBox.shrink(),
        onTap: () {
          if (GoRouterState.of(context).uri.toString() != AppRoutes.settings) {
            context.push(AppRoutes.settings);
          }
        },
      ),
      PaneItemSeparator(color: Colors.transparent),
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
          leading: () {
            final enabled = widget.shellContext != null && appRouter.canPop();
            final onPressed = enabled
                ? () {
                    if (appRouter.canPop()) {
                      context.pop();
                      setState(() {});
                    }
                  }
                : null;

            return NavigationPaneTheme(
              data: NavigationPaneTheme.of(context).merge(
                NavigationPaneThemeData(
                  unselectedIconColor: WidgetStateProperty.resolveWith((
                    states,
                  ) {
                    if (states.isDisabled) {
                      return ButtonThemeData.buttonColor(context, states);
                    }
                    return ButtonThemeData.uncheckedInputColor(
                      FluentTheme.of(context),
                      states,
                    ).basedOnLuminance();
                  }),
                ),
              ),
              child: Builder(
                builder: (context) => PaneItem(
                  icon: const Center(child: Icon(FluentIcons.back, size: 12.0)),
                  title: const Text("Back"),
                  body: const SizedBox.shrink(),
                  enabled: enabled,
                ).build(context, false, onPressed, displayMode: .compact),
              ),
            );
          }(),
          title: const Text('Revision Tool'),
          actions: RepaintBoundary(child: WindowCaption()),
        ),
        pane: NavigationPane(
          size: const NavigationPaneSize(openWidth: 300),
          selected: _calculateSelectedIndex(context, items, footerItems),
          displayMode: context.mqSize.width >= 800
              ? PaneDisplayMode.open
              : PaneDisplayMode.minimal,
          header: RepaintBoundary(
            child: SizedBox(
              height: 90,
              // height: kOneLineTileHeight,
              child: Row(
                children: [
                  const SizedBox(width: 5.0),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                    child: Image.file(
                      width: imgXY,
                      height: imgXY,
                      cacheWidth: imgCacheSize,
                      cacheHeight: imgCacheSize,
                      _userImageFile,
                    ),
                  ),
                  const SizedBox(width: 13.0),
                  Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        _username ?? 'User',
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
              placeholder: t.suggestionBoxPlaceholder,
              items: items.whereType<PaneItem>().map((page) {
                assert(page.title is Text);
                final text = (page.title as Text).data!;
                return AutoSuggestBoxItem(
                  value: text,
                  label: text,
                  onSelected: () async {
                    // Use the page's key to navigate
                    if (page.key is ValueKey) {
                      final path = (page.key as ValueKey).value as String;
                      context.push(path);
                    }
                    await Future.delayed(const Duration(milliseconds: 17));
                    _searchController.clear();
                  },
                );
              }).toList(),
            ),
          ),
          autoSuggestBoxReplacement: const Icon(FluentIcons.search),
          items: items,
          footerItems: footerItems,
        ),
        paneBodyBuilder: (item, child) {
          final name = item?.key is ValueKey
              ? (item!.key as ValueKey).value
              : null;
          return FocusTraversalGroup(
            key: ValueKey('body$name'),
            child: Builder(
              builder: (context) => Column(
                children: [
                  NavigationView.of(context).displayMode ==
                          PaneDisplayMode.minimal
                      ? const Padding(
                          padding: EdgeInsets.only(left: 13),
                          child: PageHeaderBreadcrumbs(),
                        )
                      : const PageHeaderBreadcrumbs(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          );
        },
        onOpenSearch: () => _searchFocusNode.requestFocus(),
      ),
    );
  }
}
