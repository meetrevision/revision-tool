import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/motion/navigation_transitions.dart';
import 'package:revitool/core/motion/winui_navigation_indicator.dart';

final class const _At(
  @override final double value, [
  @override final AnimationStatus status = .forward,
]) extends Animation<double> {
  @override
  void addListener(void Function() listener) {}

  @override
  void removeListener(void Function() listener) {}

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}
}

const _eps = 1e-6;

Matcher _isIdentity() => isA<NavigationTransitionFrame>()
    .having((f) => f.opacity, 'opacity', closeTo(1.0, _eps))
    .having((f) => f.dx, 'dx', closeTo(0.0, _eps))
    .having((f) => f.dy, 'dy', closeTo(0.0, _eps))
    .having((f) => f.scale, 'scale', closeTo(1.0, _eps));

void main() {
  group('FluentNavigationTransition', () {
    for (final FluentNavigationTransition transition in FluentNavigationTransition.values) {
      test('${transition.name} rests on the identity frame', () {
        expect(transition.primaryFrame(const _At(1.0, .completed), rtl: false), _isIdentity());
        expect(transition.secondaryFrame(const _At(0.0, .dismissed), rtl: false), _isIdentity());
        expect(transition.secondaryFrame(const _At(0.0, .reverse), rtl: false), _isIdentity());
      });
    }

    test('entrance hides the new page while the old one fades out', () {
      const FluentNavigationTransition t = .entrance;
      expect(t.primaryFrame(const _At(0.2), rtl: false).opacity, 0.0);
      final NavigationTransitionFrame covered = t.secondaryFrame(const _At(0.15), rtl: false);
      expect(covered.opacity, inExclusiveRange(0.0, 1.0));
      expect(t.secondaryFrame(const _At(0.5), rtl: false).opacity, 0.0);
    });

    test('entrance slides the new page up from below', () {
      final NavigationTransitionFrame f = FluentNavigationTransition.entrance.primaryFrame(
        const _At(0.5),
        rtl: false,
      );
      expect(f.opacity, 1.0);
      expect(f.dy, inExclusiveRange(0.0, 140.0));
    });

    test('slide brings the new page in from the trailing side', () {
      const FluentNavigationTransition t = .slide;
      expect(t.primaryFrame(const _At(0.5), rtl: false).dx, greaterThan(0.0));
      expect(t.primaryFrame(const _At(0.5), rtl: true).dx, lessThan(0.0));
      expect(t.secondaryFrame(const _At(0.2), rtl: false).dx, lessThan(0.0));
    });

    test('slide back moves the pages the other way', () {
      const FluentNavigationTransition t = .slide;
      final NavigationTransitionFrame popped = t.primaryFrame(const _At(0.9, .reverse), rtl: false);
      expect(popped.opacity, 1.0);
      expect(popped.dx, greaterThan(0.0));
      expect(t.primaryFrame(const _At(0.5, .reverse), rtl: false).opacity, 0.0);
      final NavigationTransitionFrame revealed = t.secondaryFrame(
        const _At(0.2, .reverse),
        rtl: false,
      );
      expect(revealed.opacity, 1.0);
      expect(revealed.dx, inExclusiveRange(-150.0, 0.0));
    });

    test('slide from leading mirrors slide', () {
      const FluentNavigationTransition t = .slideFromLeading;
      expect(t.primaryFrame(const _At(0.5), rtl: false).dx, lessThan(0.0));
      expect(t.primaryFrame(const _At(0.5), rtl: true).dx, greaterThan(0.0));
      expect(t.secondaryFrame(const _At(0.2), rtl: false).dx, greaterThan(0.0));
    });

    test('drill in zooms the new page in from 94%', () {
      const FluentNavigationTransition t = .drillIn;
      final NavigationTransitionFrame start = t.primaryFrame(const _At(0.0), rtl: false);
      expect(start.scale, closeTo(0.94, _eps));
      expect(start.opacity, closeTo(0.0, _eps));
      final NavigationTransitionFrame revealed = t.secondaryFrame(
        const _At(1.0, .reverse),
        rtl: false,
      );
      expect(revealed.scale, closeTo(1.06, _eps));
      expect(revealed.opacity, closeTo(0.0, _eps));
    });
  });

  group('winUIIndicatorSegment', () {
    const length = 15.0;

    test('stays put when the pill does not move', () {
      expect(winUIIndicatorSegment(0.5, 10.0, 10.0, length), (10.0, 25.0));
    });

    test('stretches down, then settles on the new item', () {
      final (double s0, double e0) = winUIIndicatorSegment(0.0, 0.0, 40.0, length);
      expect(s0, closeTo(0.0, _eps));
      expect(e0, closeTo(15.0, _eps));

      final (double s1, double e1) = winUIIndicatorSegment(1.0 / 3.0, 0.0, 40.0, length);
      expect(s1, closeTo(0.0, _eps));
      expect(e1, closeTo(55.0, _eps));

      final (double s2, double e2) = winUIIndicatorSegment(1.0, 0.0, 40.0, length);
      expect(s2, closeTo(40.0, _eps));
      expect(e2, closeTo(55.0, _eps));
    });

    test('stretches up, then settles on the new item', () {
      final (double s1, double e1) = winUIIndicatorSegment(1.0 / 3.0, 40.0, 0.0, length);
      expect(s1, closeTo(0.0, _eps));
      expect(e1, closeTo(55.0, _eps));

      final (double s2, double e2) = winUIIndicatorSegment(1.0, 40.0, 0.0, length);
      expect(s2, closeTo(0.0, _eps));
      expect(e2, closeTo(15.0, _eps));
    });
  });
}
