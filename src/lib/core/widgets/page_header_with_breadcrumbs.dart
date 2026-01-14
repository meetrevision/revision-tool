import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/core/routing/app_routes.dart';

/// A reusable PageHeader widget that automatically displays breadcrumbs
/// based on the current route location.
class PageHeaderBreadcrumbs extends StatelessWidget {
  const PageHeaderBreadcrumbs({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return PageHeader(
      title: BreadcrumbBar(
        chevronIconBuilder: (context, index) =>
            _chevronIconBuilder(context, index),
        items: AppRoutes.buildBreadcrumbs(currentLocation, context),
        onItemPressed: (item) => context.push(item.value),
        chevronIconSize: 15,
      ),
      commandBar: trailing,
    );
  }

  static Widget _chevronIconBuilder(BuildContext context, int index) {
    final theme = FluentTheme.of(context);
    final textDirection = Directionality.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12.0),
      child: Icon(
        textDirection == TextDirection.ltr
            ? WindowsIcons.chevron_right
            : WindowsIcons.chevron_left,
        color: theme.resources.textFillColorSecondary,
      ),
    );
  }
}
