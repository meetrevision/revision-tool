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
  search,
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

  static bool hasNestedRoute(GoRouter router) {
    for (final RouteMatchBase match in router.routerDelegate.currentConfiguration.matches) {
      if (match case final ShellRouteMatch shellMatch) {
        return shellMatch.matches.length > 1;
      }
    }
    return false;
  }

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

  /// Creates a page-refresh transition for top-level destinations.
  /// https://learn.microsoft.com/en-us/windows/apps/design/motion/page-refresh
  static Page<T> buildPageWithEntranceTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return _NavigationPage<T>(
      key: state.pageKey,
      name: state.matchedLocation,
      drill: false,
      disableAnimations: MediaQuery.disableAnimationsOf(context),
      child: child,
    );
  }

  /// Creates a directional drill transition for nested routes.
  /// https://learn.microsoft.com/en-us/windows/apps/design/motion/drill
  static Page<T> buildPageWithDrillTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return _NavigationPage<T>(
      key: state.pageKey,
      name: state.matchedLocation,
      drill: true,
      disableAnimations: MediaQuery.disableAnimationsOf(context),
      child: child,
    );
  }
}

final class const _NavigationPage<T>({
  required super.key,
  required super.name,
  required final bool drill,
  required final bool disableAnimations,
  required final Widget child,
}) extends Page<T> {
  @override
  Route<T> createRoute(BuildContext context) => _NavigationRoute<T>(this);
}

final class _NavigationRoute<T>(_NavigationPage<T> page) extends PageRoute<T> {
  this : super(settings: page);

  _NavigationPage<T> get _page => settings as _NavigationPage<T>;

  bool _coveredByDrill = false;

  @override
  Duration get transitionDuration => _page.disableAnimations
      ? Duration.zero
      : _page.drill
      ? _drillTransitionDuration
      : _pageTransitionDuration;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is _NavigationRoute<dynamic>;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is _NavigationRoute<dynamic>;

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    if (nextRoute != null) {
      _coveredByDrill = nextRoute is _NavigationRoute<dynamic> && nextRoute._page.drill;
    }
    super.didChangeNext(nextRoute);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    _coveredByDrill = nextRoute is _NavigationRoute<dynamic> && nextRoute._page.drill;
    super.didPopNext(nextRoute);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(scopesRoute: true, explicitChildNodes: true, child: _page.child);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool disableAnimations =
        _page.disableAnimations || MediaQuery.disableAnimationsOf(context);
    final double entrance = disableAnimations ? 1 : animation.value;
    final double exit = disableAnimations ? 0 : secondaryAnimation.value;
    final bool replacingWithRefresh =
        secondaryAnimation.status != AnimationStatus.dismissed && !_coveredByDrill;
    final bool enteringDrill = _page.drill && !replacingWithRefresh;
    final double entranceProgress = enteringDrill
        ? _drillEntranceInterval.transform(entrance)
        : _pageCurve.transform(entrance);
    final double exitProgress = _coveredByDrill
        ? _drillExitInterval.transform(exit)
        : _pageCurve.transform(exit);

    // Complementary drill phases prevent transparent Mica pages from painting over each other.
    final double entranceOpacity = enteringDrill ? (entrance >= 0.5 ? 1 : 0) : entranceProgress;
    final double exitOpacity = _coveredByDrill ? (exit < 0.5 ? 1 : 0) : 1 - exitProgress;
    final double opacity = disableAnimations ? (isCurrent ? 1 : 0) : entranceOpacity * exitOpacity;
    final double offset = disableAnimations
        ? 0
        : (enteringDrill ? _drillOffset * (1 - entranceProgress) : 0) -
              (_coveredByDrill ? _drillOffset * exitProgress : 0);

    // Keep the same subtree through entrance, cover, and reverse to preserve page state.
    return ClipRect(
      child: FractionalTranslation(
        translation: Offset(offset, 0),
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: opacity == 0,
            child: ExcludeSemantics(excluding: opacity == 0, child: child),
          ),
        ),
      ),
    );
  }
}

const _pageTransitionDuration = Duration(milliseconds: 260);
const _drillTransitionDuration = Duration(milliseconds: 400);
const _drillOffset = 0.12;
const Curve _pageCurve = Curves.easeInOut;
const _drillExitInterval = Interval(0, 0.5, curve: Curves.easeIn);
const _drillEntranceInterval = Interval(0.5, 1, curve: Curves.easeOut);

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
