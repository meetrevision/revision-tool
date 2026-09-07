import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_graphics/vector_graphics.dart';

import '../../i18n/generated/strings.g.dart';

enum RouteSection() {
  main,
  footer,
  search
}

enum RouteMeta({
  required final String path,
  required final RouteSection section,
  required final Object? icon,
}) {
  home(
    path: '/',
    section: .main,
    icon: SvgPicture(
      AssetBytesLoader('assets/icon/pane/ic_revi_fluent_home_color.svg.vec'),
      width: 20,
      height: 20,
    ),
  ),
  tweaks(
    path: '/tweaks',
    section: .main,
    icon: SvgPicture(
      AssetBytesLoader('assets/icon/pane/ic_revi_fluent_wrench_24_color.svg.vec'),
      width: 20,
      height: 20,
    ),
  ),
  msStore(
    path: '/msstore',
    section: .main,
    icon: SvgPicture(
      AssetBytesLoader('assets/icon/pane/ic_revi_fluent_ms_store_48_color.svg.vec'),
      width: 24,
      height: 24,
    ),
  ),
  settings(
    path: '/settings',
    section: .footer,
    icon: SvgPicture(
      AssetBytesLoader('assets/icon/pane/ic_fluent_settings_48_color.svg.vec'),
      width: 20,
      height: 20,
    ),
  ),
  tweaksSecurity(
    path: '/tweaks/security',
    section: .search,
    icon: msicons.FluentIcons.shield_lock_20_regular,
  ),
  tweaksPerformance(
    path: '/tweaks/performance',
    section: .search,
    icon: msicons.FluentIcons.top_speed_24_regular,
  ),
  tweaksPersonalization(
    path: '/tweaks/personalization',
    section: .search,
    icon: msicons.FluentIcons.color_24_regular,
  ),
  tweaksUtilities(
    path: '/tweaks/utilities',
    section: .search,
    icon: msicons.FluentIcons.toolbox_24_regular,
  ),
  tweaksUpdates(
    path: '/tweaks/updates',
    section: .search,
    icon: msicons.FluentIcons.arrow_download_24_regular,
  );

  String get label {
    return switch (this) {
      .home => t.pageHome,
      .tweaks => t.pageTweaks,
      .msStore => t.pageMSStore,
      .settings => t.pageSettings,
      .tweaksSecurity => t.pageTweaksSecurity,
      .tweaksPerformance => t.pageTweaksPerformance,
      .tweaksPersonalization => t.pageTweaksPersonalization,
      .tweaksUtilities => t.pageTweaksUtilities,
      .tweaksUpdates => t.pageTweaksUpdates,
    };
  }

  static final Map<String, RouteMeta> _pathLookup = {for (final r in values) r.path: r};

  static RouteMeta? fromPath(String path, {bool allowPrefix = false}) {
    if (!allowPrefix) return _pathLookup[path];
    for (final RouteMeta route in _navigationRoutes) {
      if (path == route.path || (route.path != '/' && path.startsWith('${route.path}/'))) {
        return route;
      }
    }
    return null;
  }
}

class AppRoutes() {
  static const String unsupported = '/unsupported';

  static const List<RouteMeta> navigationRoutes = _navigationRoutes;

  static final List<NavigationPaneItem> mainPaneItems = _buildPaneItems(
    _mainNavigationRoutes,
    exposeButtonSemantics: true,
  );
  static final List<NavigationPaneItem> footerPaneItems = _buildPaneItems(
    _footerNavigationRoutes,
    exposeButtonSemantics: true,
  );
  static final List<NavigationPaneItem> searchableItems = _buildPaneItems(_searchableRoutes);

  static String getRouteName(String path, BuildContext context) {
    final RouteMeta? meta = RouteMeta.fromPath(path);
    if (meta != null) {
      return meta.label;
    }
    final String segment = path.split('/').last;
    return segment.isEmpty ? t.pageHome : segment.capitalize();
  }

  static int? getPaneIndexFromRoute(RouteMeta? route) =>
      route != null && route.section != RouteSection.search ? route.index : null;

  static List<BreadcrumbItem<String>> buildBreadcrumbs(String location, BuildContext context) {
    final List<String> segments = location.split('/').where((s) => s.isNotEmpty).toList();
    final FluentThemeData theme = FluentTheme.of(context);

    var currentPath = '';
    return [
      for (int i = 0; i < segments.length; i++)
        (() {
          currentPath += '/${segments[i]}';
          final isLast = segments.last == segments[i];
          return BreadcrumbItem(
            label: Text(
              getRouteName(currentPath, context),
              style: TextStyle(
                color: isLast
                    ? theme.typography.body?.color
                    : theme.resources.textFillColorSecondary,
              ),
            ),
            value: currentPath,
          );
        })(),
    ];
  }

  /// Creates a page with [HorizontalSlidePageTransition] for nested routes.
  /// https://learn.microsoft.com/en-us/windows/apps/design/motion/timing-and-easing
  static Page<T> buildPageWithHorizontalTransition<T>({
    required GoRouterState state,
    required Color barrierColor,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      barrierColor: barrierColor,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.decelerate,
          reverseCurve: Curves.easeIn,
        );
        return HorizontalSlidePageTransition(
          fromLeft: false,
          animation: curvedAnimation,
          child: child,
        );
      },
    );
  }
}

const _mainNavigationRoutes = <RouteMeta>[.home, .tweaks, .msStore];

const _footerNavigationRoutes = <RouteMeta>[.settings];

const _searchableRoutes = <RouteMeta>[
  .tweaksSecurity,
  .tweaksPerformance,
  .tweaksPersonalization,
  .tweaksUtilities,
  .tweaksUpdates,
];

const _navigationRoutes = <RouteMeta>[..._mainNavigationRoutes, ..._footerNavigationRoutes];

List<NavigationPaneItem> _buildPaneItems(
  List<RouteMeta> routes, {
  bool exposeButtonSemantics = false,
}) {
  return routes
      .map(
        (route) => PaneItem(
          key: ValueKey(route.path),
          icon: switch (route.icon) {
            final IconData iconData => Icon(iconData),
            final SvgPicture svg => svg,
            _ => const SizedBox.shrink(),
          },
          // Navigation pane items get an explicit accessible label and button
          // role so screen readers announce e.g. "Home, button, selected"
          // instead of a bare label. ExcludeSemantics prevents the label from
          // being merged twice (PaneItem extracts the title text for its own
          // Semantics node). Search results must keep a plain Text title, since
          // the search box reads the title as a Text.
          title: exposeButtonSemantics
              ? Semantics(
                  label: route.label,
                  button: true,
                  child: ExcludeSemantics(child: Text(route.label)),
                )
              : Text(route.label),
          body: const SizedBox.shrink(),
        ),
      )
      .toList(growable: false)
      .cast<NavigationPaneItem>();
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
