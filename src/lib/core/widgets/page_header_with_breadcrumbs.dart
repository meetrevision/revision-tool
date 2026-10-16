import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../motion/navigation_transitions.dart';
import '../routing/app_routes.dart';

/// A reusable PageHeader widget that automatically displays breadcrumbs
/// based on the current route location.
final class const PageHeaderBreadcrumbs({super.key, final Widget? trailing})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    // Breadcrumb bar for Microsoft Store product pages should be hidden
    if (currentLocation.startsWith('${RouteMeta.msStore.path}/product/')) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24),
      child: PageHeader(
        title: BreadcrumbBar(
          chevronIconBuilder: (context, index) => _chevronIconBuilder(context, index),
          items: AppRoutes.buildBreadcrumbs(currentLocation, context),
          onItemPressed: (item) => _navigateTo(context, item.value),
          chevronIconSize: 15,
        ),
        commandBar: trailing,
      ),
    );
  }

  /// Goes back to [location] when it is in the history, so it animates like the
  /// back button. Otherwise navigates to it as if it were.
  static void _navigateTo(BuildContext context, String location) {
    final List<RouteMatchBase> history = _shellHistory(
      GoRouter.of(context).routerDelegate.currentConfiguration.matches,
    );
    final int index = history.lastIndexWhere((match) => match.matchedLocation == location);
    if (index == history.length - 1) return;

    if (index >= 0) {
      final ValueKey<String> pageKey = history[index].pageKey;
      Navigator.of(context).popUntil(
        (route) => switch (route.settings) {
          Page<Object?>(:final key) => key == pageKey,
          _ => false,
        },
      );
      return;
    }

    unawaited(context.push(location, extra: FluentNavigationTransition.slideFromLeading));
  }

  static List<RouteMatchBase> _shellHistory(List<RouteMatchBase> matches) =>
      switch (matches.lastOrNull) {
        final ShellRouteMatch shell => _shellHistory(shell.matches),
        _ => matches,
      };

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
