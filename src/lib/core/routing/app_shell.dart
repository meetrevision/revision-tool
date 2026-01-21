import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:go_router/go_router.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/core/widgets/page_header_with_breadcrumbs.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/core/routing/app_routes.dart';
import 'package:revitool/core/routing/navigation_provider.dart';
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

  late final List<AutoSuggestBoxItem> _searchItems = AppRoutes.searchableItems
      .map((e) {
        final item = e as PaneItem;
        return AutoSuggestBoxItem(
          child: Row(spacing: 8, children: [e.icon, e.title!]),
          value: (e.title as Text).data!,
          label: (e.title as Text).data!,
          onSelected: () async {
            final path = (item.key as ValueKey).value.toString();
            context.push(path);
            await Future.delayed(const Duration(milliseconds: 17));
            _searchController.clear();
          },
        );
      })
      .toList(growable: false);

  final String? _username = WinRegistryService.readString(
    RegistryHive.currentUser,
    r'Volatile Environment',
    'USERNAME',
  );

  static final File _userImageFile = File(
    'C:\\ProgramData\\Microsoft\\User Account Pictures\\user-192.png',
  );

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final imgCacheSize = (imgXY * MediaQuery.devicePixelRatioOf(context))
        .toInt();

    final localizations = FluentLocalizations.of(context);

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
            final enabled =
                widget.shellContext != null &&
                ref.read(appRouterProvider).canPop();
            final onPressed = enabled
                ? () {
                    context.pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final location = GoRouterState.of(context).uri.toString();
                      final route = RouteMeta.fromPath(
                        location,
                        allowPrefix: true,
                      );
                      final index = AppRoutes.getPaneIndexFromRoute(route);
                      if (index != null) {
                        ref
                            .read(navigationIndexProvider.notifier)
                            .setIndex(index);
                      }
                    });
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
                  title: Text(localizations.backButtonTooltip),
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
          selected: ref.watch(navigationIndexProvider),
          onItemPressed: (index) {
            final route = AppRoutes.navigationRoutes[index];
            ref.read(navigationIndexProvider.notifier).setIndex(index);
            context.push(route.path);
          },
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
              items: _searchItems,
            ),
          ),
          autoSuggestBoxReplacement: const Icon(FluentIcons.search),
          items: AppRoutes.mainPaneItems,
          footerItems: [
            ...AppRoutes.footerPaneItems,
            PaneItemSeparator(color: Colors.transparent),
          ],
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
