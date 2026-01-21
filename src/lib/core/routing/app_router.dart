import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/features/home/home_page.dart';
import 'package:revitool/core/routing/app_routes.dart';
import 'package:revitool/core/routing/app_shell.dart';
import 'package:revitool/core/settings/settings_page.dart';
import 'package:revitool/core/widgets/unsupported_widget.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/features/ms_store/ms_store_page.dart';
import 'package:revitool/features/tweaks/updates/updates_page.dart';
import 'package:revitool/features/tweaks/utilities/utilities_page.dart';
import 'package:revitool/features/tweaks/performance/performance_page.dart';
import 'package:revitool/features/tweaks/personalization/personalization_page.dart';
import 'package:revitool/features/tweaks/security/security_page.dart';
import 'package:revitool/features/tweaks/tweaks_page.dart';
import 'package:revitool/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

@riverpod
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialRoute ?? RouteMeta.home.path,
    redirect: (context, state) {
      if (!WinRegistryService.isSupported) {
        return AppRoutes.unsupported;
      }
      return null; // Allow navigation
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(shellContext: context, child: child);
        },
        routes: [
          GoRoute(
            path: RouteMeta.home.path,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RouteMeta.tweaks.path,
            name: 'tweaks',
            builder: (context, state) => const TweaksPage(),
            routes: [
              GoRoute(
                path: 'security',
                name: 'security',
                pageBuilder: (context, state) =>
                    AppRoutes.buildPageWithHorizontalTransition(
                      barrierColor: context.theme.scaffoldBackgroundColor,
                      state: state,
                      child: const SecurityPage(),
                    ),
              ),
              GoRoute(
                path: 'performance',
                name: 'performance',
                pageBuilder: (context, state) =>
                    AppRoutes.buildPageWithHorizontalTransition(
                      barrierColor: context.theme.scaffoldBackgroundColor,
                      state: state,
                      child: const PerformancePage(),
                    ),
              ),
              GoRoute(
                path: 'personalization',
                name: 'personalization',
                pageBuilder: (context, state) =>
                    AppRoutes.buildPageWithHorizontalTransition(
                      barrierColor: context.theme.scaffoldBackgroundColor,
                      state: state,
                      child: const PersonalizationPage(),
                    ),
              ),
              GoRoute(
                path: 'utilities',
                name: 'utilities',
                pageBuilder: (context, state) =>
                    AppRoutes.buildPageWithHorizontalTransition(
                      barrierColor: context.theme.scaffoldBackgroundColor,
                      state: state,
                      child: const UtilitiesPage(),
                    ),
              ),
              GoRoute(
                path: 'updates',
                name: 'updates',
                pageBuilder: (context, state) =>
                    AppRoutes.buildPageWithHorizontalTransition(
                      barrierColor: context.theme.scaffoldBackgroundColor,
                      state: state,
                      child: const UpdatesPage(),
                    ),
              ),
            ],
          ),
          GoRoute(
            path: RouteMeta.msStore.path,
            name: 'msstore',
            builder: (context, state) => const MSStorePage(),
          ),
          GoRoute(
            path: RouteMeta.settings.path,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.unsupported,
        builder: (context, state) => const UnsupportedWidget(),
      ),
    ],
  );

  return router;
}
