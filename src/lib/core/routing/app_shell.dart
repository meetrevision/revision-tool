import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';
// ignore: implementation_imports
import 'package:window_plus/src/common.dart' show WM_CAPTIONAREA;
import 'package:window_plus/window_plus.dart';

import '../../extensions.dart';
import '../../i18n/generated/strings.g.dart';
import '../services/win_registry_service.dart';
import '../widgets/page_header_with_breadcrumbs.dart';
import 'app_router.dart';
import 'app_routes.dart';
import 'navigation_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.shellContext});
  final Widget child;
  final BuildContext? shellContext;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<State<StatefulWidget>> _viewKey = GlobalKey(
    debugLabel: 'Navigation View Key',
  );
  final GlobalKey<AutoSuggestBoxState<dynamic>> _searchKey = GlobalKey(
    debugLabel: 'Search Bar Key',
  );
  final _overlayFocusNode = FocusNode();
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  final _overlayPortalController = OverlayPortalController();

  static const imgXY = 60.0;
  AutoSuggestBoxItem<dynamic>? selectedPage;

  late final List<AutoSuggestBoxItem<dynamic>> _searchItems = AppRoutes
      .searchableItems
      .map((e) {
        final item = e as PaneItem;
        return AutoSuggestBoxItem(
          child: Row(spacing: 8, children: [?e.icon, e.title!]),
          value: (e.title! as Text).data,
          label: (e.title! as Text).data!,
          onSelected: () async {
            final path = (item.key! as ValueKey).value.toString();
            await context.push(path);
            await Future<void>.delayed(const Duration(milliseconds: 17));
            _searchController.clear();
            _overlayPortalController.hide();
          },
        );
      })
      .toList(growable: false);

  static final String? _username = WinRegistryService.readString(
    RegistryHive.currentUser,
    r'Volatile Environment',
    'USERNAME',
  );

  static final File _userImageFile = (() {
    final String path =
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\' +
        WinRegistryService.currentUserSid;

    final String? imagePath = WinRegistryService.readString(
      .localMachine,
      path,
      'Image192',
    );
    if (imagePath != null && File(imagePath).existsSync()) {
      return File(imagePath);
    }

    return File(r'C:\ProgramData\Microsoft\User Account Pictures\user-192.png');
  })();

  void _updateNavigationIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final location = GoRouterState.of(context).uri.toString();
      final RouteMeta? route = RouteMeta.fromPath(location, allowPrefix: true);
      final int? index = AppRoutes.getPaneIndexFromRoute(route);
      if (index != null) {
        ref.read(navigationIndexProvider.notifier).index = index;
      }
    });
  }

  @override
  void initState() {
    _updateNavigationIndex();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _overlayFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final int imgCacheSize = (imgXY * MediaQuery.devicePixelRatioOf(context))
        .toInt();

    final AutoSuggestBox<dynamic> autoSuggestBox = AutoSuggestBox(
      // Needed to override decoration when autoSuggestBox is an overlay
      decoration: .resolveWith((states) {
        final bool isOverlayVisible =
            _searchKey.currentState?.isOverlayVisible ?? false;

        final Color color = states.isFocused
            ? context.theme.resources.solidBackgroundFillColorSecondary
            : context.theme.resources.solidBackgroundFillColorQuarternary;

        final BorderRadius borderRadius = isOverlayVisible
            ? const .vertical(top: .circular(15))
            : const .all(.circular(30));

        return .new(color: color, borderRadius: borderRadius);
      }),
      leadingIcon: const Padding(
        padding: EdgeInsetsDirectional.only(start: 11.5),
        child: Icon(msicons.FluentIcons.search_20_regular),
      ),
      key: _searchKey,
      focusNode: _searchFocusNode,
      controller: _searchController,
      placeholder: t.suggestionBoxPlaceholder,
      items: _searchItems,
      trailingIcon: const Padding(
        padding: EdgeInsetsDirectional.only(start: 8),
        child: SizedBox.shrink(),
      ),
    );

    return Listener(
      onPointerDown: (PointerDownEvent event) async {
        if (event.buttons & kBackMouseButton != 0 && context.canPop()) {
          await Future<void>.delayed(
            Duration(
              milliseconds: context.theme.fastAnimationDuration.inMilliseconds,
            ),
          );
          if (context.mounted && context.canPop()) {
            context.pop();
            _updateNavigationIndex();
          }
        }
      },
      child: SafeArea(
        child: NavigationView(
          key: _viewKey,
          contentShape: const RoundedRectangleBorder(
            side: .new(width: 0, color: Colors.transparent),
            borderRadius: .only(topLeft: .circular(8.0)),
          ),
          titleBar: TitleBar(
            backButton: () {
              final GoRouter router = ref.read(appRouterProvider);
              final List<RouteMatchBase> matches =
                  router.routerDelegate.currentConfiguration.matches;
              final firstMatch = matches.first as ShellRouteMatch;

              final VoidCallback? onPressed = firstMatch.matches.length > 1
                  ? () {
                      context.pop();
                      _updateNavigationIndex();
                    }
                  : null;

              return PaneBackButton(
                enabled: onPressed != null,
                onPressed: onPressed,
                backIcon: const Center(
                  child: Icon(FluentIcons.back, size: 12.0),
                ),
              );
            }(),
            // To match W11's Settings app title bar style, `leftHeader` must be the title, when width > 800 `title` must be a search [IconButton] that spawns an overlay otherwise it must be null and the search [AutoSuggestBox] must be in `content`
            leftHeader: const Text(
              'Revision Tool',
              style: TextStyle(fontSize: 12),
            ),
            title: MediaQuery.widthOf(context) > 800
                ? null
                : OverlayPortal(
                    controller: _overlayPortalController,
                    overlayChildBuilder: (context) => Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: .opaque,
                            onTap: _overlayPortalController.hide,
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Positioned(
                          top: 50,
                          left: 25,
                          right: 25,
                          child: autoSuggestBox,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(msicons.FluentIcons.search_20_regular),
                      onPressed: () {
                        _overlayPortalController.show();
                        _searchFocusNode.requestFocus();
                        _overlayFocusNode.requestFocus();
                      },
                    ),
                  ),
            content: MediaQuery.widthOf(context) > 800
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: 8,
                      ),
                      child: autoSuggestBox,
                    ),
                  )
                : null,
            captionControls: WindowCaption(),
            onDragStarted: () {
              PostMessage(WindowPlus.instance.handle, WM_CAPTIONAREA, 0, 0);
            },
          ),
          pane: NavigationPane(
            acrylicDisabled: true,
            indicator: const StickyNavigationIndicator(
              indicatorSize: 3.5,
              leftPadding: 12.5,
            ),
            size: const .new(openWidth: 300, headerHeight: 90.5),
            selected: ref.watch(navigationIndexProvider),
            onItemPressed: (index) {
              if (index == ref.read(navigationIndexProvider)) return;

              final RouteMeta route = AppRoutes.navigationRoutes[index];
              ref.read(navigationIndexProvider.notifier).index = index;
              context.push(route.path);
            },
            displayMode: MediaQuery.widthOf(context) >= 800
                ? .expanded
                : .minimal,
            header: RepaintBoundary(
              child: Center(
                heightFactor: 5,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: const .all(.circular(30.0)),
                    child: Image.file(
                      width: imgXY,
                      height: imgXY,
                      cacheWidth: imgCacheSize,
                      cacheHeight: imgCacheSize,
                      _userImageFile,
                    ),
                  ),
                  margin: .zero,
                  contentPadding: .zero,
                  title: Text(
                    _username ?? 'User',
                    style: const .new(fontWeight: .w500, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Proud ReviOS user',
                    style: .new(fontSize: 11, fontWeight: .normal),
                  ),
                ),
              ),
            ),
            items: AppRoutes.mainPaneItems,
            footerItems: [
              ...AppRoutes.footerPaneItems,
              PaneItemSeparator(color: Colors.transparent),
            ],
          ),
          paneBodyBuilder: (item, child) {
            final String? name = item?.key is ValueKey
                ? (item!.key! as ValueKey).value.toString()
                : null;
            return FocusTraversalGroup(
              key: ValueKey('body$name'),
              child: Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsetsDirectional.only(top: 9),
                  child: Column(
                    children: [
                      if (NavigationView.of(context).displayMode == .minimal)
                        const Padding(
                          padding: EdgeInsetsDirectional.only(start: 13),
                          child: PageHeaderBreadcrumbs(),
                        )
                      else
                        const PageHeaderBreadcrumbs(),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
