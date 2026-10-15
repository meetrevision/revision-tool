import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_routes.dart';

/// A reusable PageHeader widget that automatically displays breadcrumbs
/// based on the current route location.
final class const PageHeaderBreadcrumbs({super.key, final Widget? trailing})
    extends StatefulWidget {
  @override
  State<PageHeaderBreadcrumbs> createState() => _PageHeaderBreadcrumbsState();
}

final class _PageHeaderBreadcrumbsState() extends State<PageHeaderBreadcrumbs> {
  late String _currentLocation;
  String _headerLocation = RouteMeta.tweaks.path;

  bool get _hasHeader =>
      _currentLocation != RouteMeta.home.path &&
      !_currentLocation.startsWith('${RouteMeta.msStore.path}/product/');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLocation = GoRouterState.of(context).uri.path;
    if (_hasHeader) _headerLocation = _currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    // Breadcrumb bar for Microsoft Store product pages should be hidden
    return IgnorePointer(
      ignoring: !_hasHeader,
      child: ExcludeSemantics(
        excluding: !_hasHeader,
        child: AnimatedOpacity(
          opacity: _hasHeader ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 120),
          // Keep the last heading's geometry while its content fades away.
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 24),
            child: PageHeader(
              title: BreadcrumbBar(
                chevronIconBuilder: (context, index) => _chevronIconBuilder(context, index),
                items: AppRoutes.buildBreadcrumbs(_headerLocation, context),
                onItemPressed: (item) => _navigateToBreadcrumb(context, item.value),
                chevronIconSize: 15,
              ),
              commandBar: widget.trailing,
            ),
          ),
        ),
      ),
    );
  }

  static void _navigateToBreadcrumb(BuildContext context, String location) {
    final GoRouter router = GoRouter.of(context);
    final stack = <String>[];
    void collectLocations(List<RouteMatchBase> matches) {
      for (final match in matches) {
        if (match is ShellRouteMatch) {
          collectLocations(match.matches);
        } else {
          stack.add(match.matchedLocation);
        }
      }
    }

    collectLocations(router.routerDelegate.currentConfiguration.matches);
    final int targetIndex = stack.lastIndexOf(location);
    if (targetIndex < 0) {
      router.go(location);
      return;
    }
    for (int i = stack.length - 1; i > targetIndex; i--) {
      router.pop();
    }
  }

  static Widget _chevronIconBuilder(BuildContext context, int index) {
    final FluentThemeData theme = FluentTheme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
      child: Icon(
        textDirection == .ltr ? WindowsIcons.chevron_right : WindowsIcons.chevron_left,
        color: theme.resources.textFillColorSecondary,
      ),
    );
  }
}
