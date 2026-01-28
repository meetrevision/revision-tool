import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:go_router/go_router.dart';
import '../../i18n/generated/strings.g.dart';

enum RouteSection { main, footer, search }

enum RouteMeta {
  home(
    path: '/',
    section: RouteSection.main,
    icon: msicons.FluentIcons.home_24_regular,
  ),
  tweaks(
    path: '/tweaks',
    section: RouteSection.main,
    icon: msicons.FluentIcons.wrench_24_regular,
  ),
  msStore(
    path: '/msstore',
    section: RouteSection.main,
    icon: msicons.FluentIcons.store_microsoft_24_regular,
  ),
  settings(
    path: '/settings',
    section: RouteSection.footer,
    icon: msicons.FluentIcons.settings_24_regular,
  ),
  tweaksSecurity(
    path: '/tweaks/security',
    section: RouteSection.search,
    icon: msicons.FluentIcons.shield_lock_20_regular,
  ),
  tweaksPerformance(
    path: '/tweaks/performance',
    section: RouteSection.search,
    icon: msicons.FluentIcons.top_speed_24_regular,
  ),
  tweaksPersonalization(
    path: '/tweaks/personalization',
    section: RouteSection.search,
    icon: msicons.FluentIcons.color_24_regular,
  ),
  tweaksUtilities(
    path: '/tweaks/utilities',
    section: RouteSection.search,
    icon: msicons.FluentIcons.toolbox_24_regular,
  ),
  tweaksUpdates(
    path: '/tweaks/updates',
    section: RouteSection.search,
    icon: msicons.FluentIcons.arrow_download_24_regular,
  );

  const RouteMeta({
    required this.path,
    required this.section,
    required this.icon,
  });

  final String path;
  final RouteSection section;
  final IconData icon;

  String get label {
    switch (this) {
      case RouteMeta.home:
        return t.pageHome;
      case RouteMeta.tweaks:
        return t.pageTweaks;
      case RouteMeta.msStore:
        return t.pageMSStore;
      case RouteMeta.settings:
        return t.pageSettings;
      case RouteMeta.tweaksSecurity:
        return t.pageTweaksSecurity;
      case RouteMeta.tweaksPerformance:
        return t.pageTweaksPerformance;
      case RouteMeta.tweaksPersonalization:
        return t.pageTweaksPersonalization;
      case RouteMeta.tweaksUtilities:
        return t.pageTweaksUtilities;
      case RouteMeta.tweaksUpdates:
        return t.pageTweaksUpdates;
    }
  }

  static final Map<String, RouteMeta> _pathLookup = {for (final r in values) r.path: r};

  static RouteMeta? fromPath(String path, {bool allowPrefix = false}) {
    if (!allowPrefix) return _pathLookup[path];
    for (final RouteMeta route in _navigationRoutes) {
      if (path == route.path ||
          (route.path != '/' && path.startsWith('${route.path}/'))) {
        return route;
      }
    }
    return null;
  }
}

class AppRoutes {
  static const String unsupported = '/unsupported';

  static const List<RouteMeta> navigationRoutes = _navigationRoutes;

  static final List<NavigationPaneItem> mainPaneItems = _buildPaneItems(_mainNavigationRoutes);
  static final List<NavigationPaneItem> footerPaneItems = _buildPaneItems(_footerNavigationRoutes);
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
      route != null && route.section != RouteSection.search
      ? route.index
      : null;

  static List<BreadcrumbItem<String>> buildBreadcrumbs(
    String location,
    BuildContext context,
  ) {
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

const List<RouteMeta> _mainNavigationRoutes = [
  RouteMeta.home,
  RouteMeta.tweaks,
  RouteMeta.msStore,
];

const List<RouteMeta> _footerNavigationRoutes = [RouteMeta.settings];

const List<RouteMeta> _searchableRoutes = [
  RouteMeta.tweaksSecurity,
  RouteMeta.tweaksPerformance,
  RouteMeta.tweaksPersonalization,
  RouteMeta.tweaksUtilities,
  RouteMeta.tweaksUpdates,
];

const List<RouteMeta> _navigationRoutes = [
  ..._mainNavigationRoutes,
  ..._footerNavigationRoutes,
];

List<NavigationPaneItem> _buildPaneItems(List<RouteMeta> routes) {
  return routes
      .map(
        (route) => PaneItem(
          key: ValueKey(route.path),
          icon: Icon(route.icon, size: 20),
          title: Text(route.label),
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
