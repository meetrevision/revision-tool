import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

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
          onItemPressed: (item) => context.push(item.value),
          chevronIconSize: 15,
        ),
        commandBar: trailing,
      ),
    );
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
