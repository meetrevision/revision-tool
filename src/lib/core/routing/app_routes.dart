import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/i18n/generated/strings.g.dart';

class AppRoutes {
  static const String home = '/';
  static const String tweaks = '/tweaks';
  static const String msStore = '/msstore';
  static const String settings = '/settings';

  static const String security = '/tweaks/security';
  static const String performance = '/tweaks/performance';
  static const String personalization = '/tweaks/personalization';
  static const String utilities = '/tweaks/utilities';
  static const String updates = '/tweaks/updates';

  static const String unsupported = '/unsupported';

  /// Get localized route name
  static String getRouteName(String path, BuildContext context) {
    switch (path) {
      case home:
        return t.pageHome;
      case tweaks:
        return t.pageTweaks;
      case msStore:
        return t.pageMSStore;
      case settings:
        return t.pageSettings;
      default:
        final segment = path.split('/').last;
        return segment.isEmpty ? 'Home' : segment.capitalize();
    }
  }

  /// Build breadcrumb items from current location
  static List<BreadcrumbItem<String>> buildBreadcrumbs(
    String location,
    BuildContext context,
  ) {
    final segments = location.split('/').where((s) => s.isNotEmpty).toList();
    final breadcrumbs = <BreadcrumbItem<String>>[];
    final theme = FluentTheme.of(context);

    String currentPath = '';
    for (int i = 0; i < segments.length; i++) {
      currentPath += '/${segments[i]}';
      final name = getRouteName(currentPath, context);
      final isLast = i == segments.length - 1;

      breadcrumbs.add(
        BreadcrumbItem(
          label: Text(
            name,
            style: TextStyle(
              color: isLast
                  ? theme.typography.body?.color
                  : theme.resources.textFillColorSecondary,
            ),
          ),
          value: currentPath,
        ),
      );
    }

    return breadcrumbs;
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
          animation: curvedAnimation,
          child: child,
        );
      },
    );
  }
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
