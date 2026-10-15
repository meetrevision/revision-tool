import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/core/routing/app_routes.dart';
import 'package:revitool/core/widgets/page_header_with_breadcrumbs.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);
const _blue = Color(0xFF0000FF);
final GlobalKey<State<StatefulWidget>> _captureKey = GlobalKey();

void main() {
  test('maps nested paths to their top-level navigation route', () {
    expect(RouteMeta.fromPath('/tweaks/security'), RouteMeta.tweaksSecurity);
    expect(RouteMeta.fromPath('/tweaks/security', allowPrefix: true), RouteMeta.tweaks);
    expect(RouteMeta.fromPath('/msstore/product/123', allowPrefix: true), RouteMeta.msStore);
    expect(AppRoutes.getPaneIndexFromRoute(RouteMeta.fromPath('/settings', allowPrefix: true)), 3);
  });

  testWidgets('logical nested route depth controls back availability', (tester) async {
    final GoRouter router = await _mountRouter(tester);
    expect(AppRoutes.hasNestedRoute(router), isFalse);

    router.go('/tweaks');
    await tester.pumpAndSettle();
    expect(AppRoutes.hasNestedRoute(router), isFalse);

    unawaited(router.push<void>('/tweaks/security'));
    await tester.pumpAndSettle();
    expect(AppRoutes.hasNestedRoute(router), isTrue);
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(AppRoutes.hasNestedRoute(router), isFalse);
    expect(router.canPop(), isFalse);

    router.go('/tweaks/security');
    await tester.pumpAndSettle();
    expect(AppRoutes.hasNestedRoute(router), isTrue);
    expect(router.canPop(), isTrue);

    router.go('/settings');
    await tester.pumpAndSettle();
    expect(AppRoutes.hasNestedRoute(router), isFalse);
    expect(router.canPop(), isFalse);
  });

  testWidgets('section replacement keeps final geometry and never blanks the body', (tester) async {
    final GoRouter router = await _mountRouter(tester);
    final Offset origin = tester.getTopLeft(find.byKey(const ValueKey('/')));

    router.go('/settings');
    await tester.pump();
    for (var frame = 0; frame < 18; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(find.byKey(const ValueKey('/settings'))), origin);
      expect((await _pixels(tester)).hasContent, isTrue, reason: 'Blank frame $frame');
      if (frame == 3) {
        expect(_routeOpacity(tester, '/'), inExclusiveRange(0, 1));
        expect(_routeOpacity(tester, '/settings'), inExclusiveRange(0, 1));
      }
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/')), findsNothing);
    expect(_routeOffset(tester, '/settings'), Offset.zero);
  });

  testWidgets('Home and product pages retain header space while headings fade', (tester) async {
    final GoRouter router = await _mountRouter(tester, initialLocation: '/tweaks');
    final Size headerSize = tester.getSize(find.byType(PageHeaderBreadcrumbs));
    final Offset origin = tester.getTopLeft(find.byKey(const ValueKey('/tweaks')));

    router.go('/');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.getSize(find.byType(PageHeaderBreadcrumbs)), headerSize);
    expect(tester.getTopLeft(find.byKey(const ValueKey('/'))), origin);
    final FadeTransition headerFade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(PageHeaderBreadcrumbs),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(headerFade.opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(headerFade.opacity.value, 0);
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .descendant(
                  of: find.byType(PageHeaderBreadcrumbs),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );

    for (final path in ['/msstore', '/msstore/product/123', '/settings', '/']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PageHeaderBreadcrumbs)), headerSize);
      expect(tester.getTopLeft(find.byKey(ValueKey(path))), origin);
    }
  });

  for (final transparent in [false, true]) {
    testWidgets('drill push/pop isolates painted pages, transparent=$transparent', (tester) async {
      final GoRouter router = await _mountRouter(
        tester,
        initialLocation: '/tweaks',
        transparent: transparent,
      );
      final Size headerSize = tester.getSize(find.byType(PageHeaderBreadcrumbs));
      final Offset headerOrigin = tester.getTopLeft(find.byType(PageHeaderBreadcrumbs));
      unawaited(router.push<void>('/tweaks/security'));
      await tester.pump();

      for (var frame = 0; frame < 28; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final _Pixels pixels = await _pixels(tester);
        expect(pixels.hasContent, isTrue, reason: 'Blank drill frame $frame');
        expect(
          pixels.hasColor(_red) && pixels.hasColor(_green),
          isFalse,
          reason: 'Overlapping drill frame $frame',
        );
        expect(tester.getSize(find.byType(PageHeaderBreadcrumbs)), headerSize);
        expect(tester.getTopLeft(find.byType(PageHeaderBreadcrumbs)), headerOrigin);
        if (frame == 5) {
          expect(_routeOffset(tester, '/tweaks').dx, lessThan(0));
          expect(_routeOpacity(tester, '/tweaks'), 1);
          expect(_routeOpacity(tester, '/tweaks/security'), 0);
        }
        if (frame == 18) {
          expect(_routeOffset(tester, '/tweaks/security').dx, greaterThan(0));
          expect(_routeOpacity(tester, '/tweaks/security'), 1);
        }
      }
      await tester.pumpAndSettle();
      expect((await _pixels(tester)).hasColor(_red), isFalse);
      expect((await _pixels(tester)).hasColor(_green), isTrue);
      expect(_routeOffset(tester, '/tweaks/security'), Offset.zero);

      router.pop();
      await tester.pump();
      for (var frame = 0; frame < 28; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final _Pixels pixels = await _pixels(tester);
        expect(pixels.hasContent, isTrue, reason: 'Blank reverse frame $frame');
        expect(
          pixels.hasColor(_red) && pixels.hasColor(_green),
          isFalse,
          reason: 'Overlapping reverse frame $frame',
        );
        if (frame == 5) {
          expect(_routeOffset(tester, '/tweaks/security').dx, greaterThan(0));
          expect(_routeOffset(tester, '/tweaks').dx, lessThan(0));
        }
      }
      await tester.pumpAndSettle();
      expect((await _pixels(tester)).hasColor(_green), isFalse);
      expect((await _pixels(tester)).hasColor(_red), isTrue);
      expect(_routeOffset(tester, '/tweaks'), Offset.zero);
    });
  }

  testWidgets('direct nested go and sibling replacement leave no parent pixels', (tester) async {
    final GoRouter router = await _mountRouter(tester, initialLocation: '/tweaks');
    router.go('/tweaks/security');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_routeOffset(tester, '/tweaks').dx, lessThan(0));
    await tester.pumpAndSettle();
    expect((await _pixels(tester)).hasColor(_red), isFalse);

    unawaited(router.push<void>('/tweaks/updates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_routeOffset(tester, '/tweaks/security').dx, lessThan(0));
    await tester.pumpAndSettle();
    expect((await _pixels(tester)).hasColor(_green), isFalse);
    expect((await _pixels(tester)).hasColor(_blue), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect((await _pixels(tester)).hasColor(_green), isTrue);
    expect((await _pixels(tester)).hasColor(_blue), isFalse);
    router.go('/tweaks/updates');
    await tester.pumpAndSettle();
    expect((await _pixels(tester)).hasColor(_red), isFalse);
    expect((await _pixels(tester)).hasColor(_green), isFalse);
    expect((await _pixels(tester)).hasColor(_blue), isTrue);
  });

  testWidgets('drill reversal before handoff restores parent without remounting', (tester) async {
    final scrollKey = GlobalKey<_ScrollBodyState>();
    final GoRouter router = await _mountRouter(
      tester,
      initialLocation: '/tweaks',
      parent: _ScrollBody(key: scrollKey),
    );
    final _ScrollBodyState state = scrollKey.currentState!;
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final double offset = state.controller.offset;
    expect(offset, greaterThan(0));

    for (final milliseconds in [80, 300, 500]) {
      unawaited(router.push<void>('/tweaks/security'));
      await tester.pump();
      await tester.pump(Duration(milliseconds: milliseconds));
      router.pop();
      await tester.pumpAndSettle();
      expect(scrollKey.currentState, same(state));
      expect(state.controller.offset, offset);
      expect(_routeOffset(tester, '/tweaks'), Offset.zero);
    }
  });

  testWidgets('leaving a child for a section uses refresh without horizontal motion', (
    tester,
  ) async {
    final GoRouter router = await _mountRouter(tester, initialLocation: '/tweaks/security');
    router.go('/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(_routeOffset(tester, '/settings'), Offset.zero);
    expect(_routeOffset(tester, '/tweaks/security'), Offset.zero);
    expect((await _pixels(tester)).hasContent, isTrue);
    await tester.pumpAndSettle();
    expect((await _pixels(tester)).hasColor(_green), isFalse);
  });

  testWidgets('rapid nested push/pop and section change settle on latest route', (tester) async {
    final GoRouter router = await _mountRouter(tester, initialLocation: '/tweaks');
    for (final path in ['/tweaks/security', '/tweaks/security', '/tweaks/updates']) {
      unawaited(router.push<void>(path));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    router.go('/settings');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('/settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('/tweaks/security'), skipOffstage: false), findsNothing);
    expect(find.byKey(const ValueKey('/tweaks/updates'), skipOffstage: false), findsNothing);
    expect((await _pixels(tester)).hasColor(_red), isFalse);
    expect((await _pixels(tester)).hasColor(_green), isFalse);
    expect(_routeOffset(tester, '/settings'), Offset.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('breadcrumb reaches missing parent after cross-section search push', (tester) async {
    final GoRouter router = await _mountRouter(tester);
    unawaited(router.push<void>('/tweaks/security'));
    await tester.pumpAndSettle();
    _pressParentBreadcrumb(tester);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/tweaks');
    expect(find.byKey(const ValueKey('/tweaks')), findsOneWidget);
    expect((await _pixels(tester)).hasColor(_green), isFalse);
  });

  testWidgets('breadcrumb pops every sibling above the actual parent', (tester) async {
    final GoRouter router = await _mountRouter(tester, initialLocation: '/tweaks');
    unawaited(router.push<void>('/tweaks/performance'));
    await tester.pumpAndSettle();
    unawaited(router.push<void>('/tweaks/security'));
    await tester.pumpAndSettle();
    _pressParentBreadcrumb(tester);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/tweaks');
    expect(router.canPop(), isFalse);
    expect((await _pixels(tester)).hasColor(_red), isTrue);
    expect((await _pixels(tester)).hasColor(_green), isFalse);
  });

  testWidgets('breadcrumb uses reverse drill when parent is next in history', (tester) async {
    final GoRouter router = await _mountRouter(tester, initialLocation: '/tweaks');
    unawaited(router.push<void>('/tweaks/security'));
    await tester.pumpAndSettle();
    _pressParentBreadcrumb(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_routeOffset(tester, '/tweaks/security').dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/tweaks');
  });

  testWidgets('reduced motion updates body and header without ghost pixels', (tester) async {
    final GoRouter router = await _mountRouter(tester, disableAnimations: true);
    for (final path in ['/tweaks', '/tweaks/security', '/settings', '/']) {
      router.go(path);
      await tester.pump();
      await tester.pump();
      expect(_routeOffset(tester, path), Offset.zero);
      expect(_routeOpacity(tester, path), 1);
      expect((await _pixels(tester)).hasContent, isTrue);
      if (path == '/tweaks/security') {
        expect((await _pixels(tester)).hasColor(_red), isFalse);
      }
    }
    final AnimatedOpacity header = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity).first,
    );
    expect(header.opacity, 0);
    expect(header.duration, Duration.zero);
  });
}

Future<GoRouter> _mountRouter(
  WidgetTester tester, {
  String initialLocation = '/',
  bool transparent = true,
  bool disableAnimations = false,
  Widget? parent,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => Column(
          children: [
            const PageHeaderBreadcrumbs(),
            Expanded(
              child: RepaintBoundary(
                key: _captureKey,
                child: ColoredBox(color: const Color(0xFF101010), child: child),
              ),
            ),
          ],
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => AppRoutes.buildPageWithEntranceTransition<void>(
              context: context,
              state: state,
              child: const _RouteBody(path: '/', color: _red),
            ),
          ),
          GoRoute(
            path: '/tweaks',
            pageBuilder: (context, state) => AppRoutes.buildPageWithEntranceTransition<void>(
              context: context,
              state: state,
              child: parent ?? const _RouteBody(path: '/tweaks', color: _red),
            ),
            routes: [
              for (final String section in ['security', 'performance', 'updates'])
                GoRoute(
                  path: section,
                  pageBuilder: (context, state) => AppRoutes.buildPageWithDrillTransition<void>(
                    context: context,
                    state: state,
                    child: _RouteBody(
                      path: '/tweaks/$section',
                      color: section == 'updates' ? _blue : _green,
                    ),
                  ),
                ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => AppRoutes.buildPageWithEntranceTransition<void>(
              context: context,
              state: state,
              child: const _RouteBody(path: '/settings', color: _blue),
            ),
          ),
          GoRoute(
            path: '/msstore',
            pageBuilder: (context, state) => AppRoutes.buildPageWithEntranceTransition<void>(
              context: context,
              state: state,
              child: const _RouteBody(path: '/msstore', color: _blue),
            ),
            routes: [
              GoRoute(
                path: 'product/:id',
                pageBuilder: (context, state) => AppRoutes.buildPageWithDrillTransition<void>(
                  context: context,
                  state: state,
                  child: const _RouteBody(path: '/msstore/product/123', color: _green),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    FluentApp.router(
      routerConfig: router,
      theme: FluentThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: transparent ? Colors.transparent : const Color(0xFF202020),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void _pressParentBreadcrumb(WidgetTester tester) {
  final BreadcrumbBar<String> bar = tester.widget(find.byType(BreadcrumbBar<String>));
  bar.onItemPressed!(bar.items.first);
}

double _routeOpacity(WidgetTester tester, String path) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(ValueKey(path), skipOffstage: false),
            matching: find.byType(Opacity, skipOffstage: false),
          )
          .first,
    )
    .opacity;

Offset _routeOffset(WidgetTester tester, String path) => tester
    .widget<FractionalTranslation>(
      find
          .ancestor(
            of: find.byKey(ValueKey(path), skipOffstage: false),
            matching: find.byType(FractionalTranslation, skipOffstage: false),
          )
          .first,
    )
    .translation;

Future<_Pixels> _pixels(WidgetTester tester) async {
  final _Pixels? pixels = await tester.runAsync(() async {
    final RenderRepaintBoundary boundary = tester.renderObject(find.byKey(_captureKey));
    final ui.Image image = await boundary.toImage();
    try {
      final ByteData data = (await image.toByteData())!;
      return _Pixels(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } finally {
      image.dispose();
    }
  });
  return pixels!;
}

final class _Pixels(final Uint8List bytes) {
  bool get hasContent {
    for (var i = 0; i < bytes.length; i += 4) {
      final int red = bytes[i];
      final int green = bytes[i + 1];
      final int blue = bytes[i + 2];
      if ((red - green).abs() > 40 || (green - blue).abs() > 40) return true;
    }
    return false;
  }

  bool hasColor(Color color) {
    final int argb = color.toARGB32();
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i] == (argb >> 16 & 255) &&
          bytes[i + 1] == (argb >> 8 & 255) &&
          bytes[i + 2] == (argb & 255) &&
          bytes[i + 3] == 255) {
        return true;
      }
    }
    return false;
  }
}

final class const _RouteBody({required final String path, required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluentTheme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(
        key: ValueKey(path),
        child: Stack(
          children: [
            Positioned(
              left: 200,
              top: color == _red ? 40 : 180,
              child: ColoredBox(color: color, child: const SizedBox(width: 100, height: 60)),
            ),
          ],
        ),
      ),
    );
  }
}

final class const _ScrollBody({super.key}) extends StatefulWidget {
  @override
  State<_ScrollBody> createState() => _ScrollBodyState();
}

final class _ScrollBodyState() extends State<_ScrollBody> {
  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: const ValueKey('/tweaks'),
      child: ListView.builder(
        controller: controller,
        itemExtent: 48,
        itemCount: 100,
        itemBuilder: (context, index) => Text('Row $index'),
      ),
    );
  }
}
