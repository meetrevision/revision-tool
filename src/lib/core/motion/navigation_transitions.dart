import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/rendering.dart';

import 'fluent_motion.dart';

enum FluentNavigationTransition({
  required final Duration forwardDuration,
  required final Duration reverseDuration,
}) {
  entrance(
    forwardDuration: FluentMotion.pageTransition,
    reverseDuration: FluentMotion.pageTransition,
  ),

  slide(forwardDuration: FluentMotion.pageTransition, reverseDuration: FluentMotion.pageTransition),

  /// [slide] mirrored, like WinUI's `SlideNavigationTransitionEffect.FromLeft`:
  /// used to navigate forward to a page that sits above the current one.
  slideFromLeading(
    forwardDuration: FluentMotion.pageTransition,
    reverseDuration: FluentMotion.pageTransition,
  ),

  drillIn(forwardDuration: FluentMotion.drillInScale, reverseDuration: FluentMotion.drillInFade),

  suppress(forwardDuration: Duration.zero, reverseDuration: Duration.zero);

  NavigationTransitionFrame primaryFrame(Animation<double> animation, {required bool rtl}) {
    if (animation.status == .reverse) {
      return _backNavigatingAway(1.0 - animation.value, rtl);
    }
    return _navigatingTo(animation.value, rtl);
  }

  NavigationTransitionFrame secondaryFrame(
    Animation<double> secondaryAnimation, {
    required bool rtl,
  }) {
    if (secondaryAnimation.status == .reverse) {
      return _backNavigatingTo(1.0 - secondaryAnimation.value, rtl);
    }
    return _navigatingAway(secondaryAnimation.value, rtl);
  }

  static const double _exitEnd = 1.0 / 3.0;

  static double _unit(double t) => t.clamp(0.0, 1.0);

  static double _exit(double t) => FluentMotion.accelerate.transform(_unit(t / _exitEnd));

  static double _enter(double t) =>
      FluentMotion.decelerate.transform(_unit((t - _exitEnd) / (1.0 - _exitEnd)));

  static double _part(double t, Duration total, Duration part) =>
      _unit(t * total.inMicroseconds / part.inMicroseconds);

  double _side(bool rtl) => rtl != (this == slideFromLeading) ? -1.0 : 1.0;

  NavigationTransitionFrame _navigatingTo(double t, bool rtl) {
    return switch (this) {
      entrance =>
        t < _exitEnd ? .hidden : .new(dy: FluentMotion.entranceOffset * (1.0 - _enter(t))),
      slide || slideFromLeading =>
        t < _exitEnd
            ? .hidden
            : .new(dx: _side(rtl) * FluentMotion.slideEnterOffset * (1.0 - _enter(t))),
      drillIn => .new(
        scale:
            FluentMotion.drillInFromScale +
            (1.0 - FluentMotion.drillInFromScale) * FluentMotion.decelerate.transform(_unit(t)),
        opacity: FluentMotion.drillOpacity.transform(
          _part(t, FluentMotion.drillInScale, FluentMotion.drillInFade),
        ),
      ),
      suppress => .identity,
    };
  }

  NavigationTransitionFrame _navigatingAway(double t, bool rtl) {
    return switch (this) {
      entrance => t >= _exitEnd ? .hidden : .new(opacity: 1.0 - _exit(t)),
      slide || slideFromLeading =>
        t >= _exitEnd ? .hidden : .new(dx: -_side(rtl) * FluentMotion.slideExitOffset * _exit(t)),
      drillIn => .new(
        scale:
            1.0 +
            (FluentMotion.drillOutToScale - 1.0) *
                FluentMotion.decelerate.transform(
                  _part(t, FluentMotion.drillInScale, FluentMotion.drillExit),
                ),
        opacity:
            1.0 -
            FluentMotion.drillOpacity.transform(
              _part(t, FluentMotion.drillInScale, FluentMotion.drillExit),
            ),
      ),
      suppress => .identity,
    };
  }

  NavigationTransitionFrame _backNavigatingAway(double t, bool rtl) {
    return switch (this) {
      entrance => t >= _exitEnd ? .hidden : .new(dy: FluentMotion.entranceOffset * _exit(t)),
      slide || slideFromLeading =>
        t >= _exitEnd ? .hidden : .new(dx: _side(rtl) * FluentMotion.slideEnterOffset * _exit(t)),
      drillIn => .new(
        scale:
            1.0 -
            (1.0 - FluentMotion.drillBackOutToScale) *
                FluentMotion.decelerate.transform(
                  _part(t, FluentMotion.drillInFade, FluentMotion.drillExit),
                ),
        opacity:
            1.0 -
            FluentMotion.drillOpacity.transform(
              _part(t, FluentMotion.drillInFade, FluentMotion.drillExit),
            ),
      ),
      suppress => .identity,
    };
  }

  NavigationTransitionFrame _backNavigatingTo(double t, bool rtl) {
    return switch (this) {
      entrance => t < _exitEnd ? .hidden : .new(opacity: _enter(t)),
      slide || slideFromLeading =>
        t < _exitEnd
            ? .hidden
            : .new(dx: -_side(rtl) * FluentMotion.slideExitOffset * (1.0 - _enter(t))),
      drillIn => .new(
        scale:
            FluentMotion.drillBackFromScale -
            (FluentMotion.drillBackFromScale - 1.0) *
                FluentMotion.drillBackScale.transform(_unit(t)),
        opacity: FluentMotion.drillOpacity.transform(_unit(t)),
      ),
      suppress => .identity,
    };
  }
}

@immutable
final class const NavigationTransitionFrame({
  final double opacity = 1.0,
  final double dx = 0.0,
  final double dy = 0.0,
  final double scale = 1.0,
}) {
  static const identity = NavigationTransitionFrame();
  static const hidden = NavigationTransitionFrame(opacity: 0.0);

  NavigationTransitionFrame combine(NavigationTransitionFrame other) => .new(
    opacity: opacity * other.opacity,
    dx: dx + other.dx,
    dy: dy + other.dy,
    scale: scale * other.scale,
  );

  @override
  String toString() =>
      'NavigationTransitionFrame(opacity: $opacity, dx: $dx, dy: $dy, scale: $scale)';
}

final class const FluentTransitionPage<T>({
  required final Widget child,
  final FluentNavigationTransition transition = .entrance,
  super.key,
  super.name,
  super.arguments,
  super.restorationId,
}) extends Page<T> {
  @override
  Route<T> createRoute(BuildContext context) => _FluentTransitionRoute<T>(this);
}

final class _FluentTransitionRoute<T>(FluentTransitionPage<T> page) extends PageRoute<T> {
  this : super(settings: page);

  FluentTransitionPage<T> get _page => settings as FluentTransitionPage<T>;

  FluentNavigationTransition get transition => _page.transition;

  FluentNavigationTransition _coveringTransition = .entrance;

  void _trackCoveringRoute(Route<dynamic>? route) {
    if (route is _FluentTransitionRoute<dynamic>) {
      _coveringTransition = route.transition;
    } else if (route != null) {
      _coveringTransition = .entrance;
    }
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    _trackCoveringRoute(nextRoute);
    super.didChangeNext(nextRoute);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    _trackCoveringRoute(nextRoute);
    super.didPopNext(nextRoute);
  }

  @override
  Duration get transitionDuration =>
      FluentMotion.animationsDisabled ? .zero : transition.forwardDuration;

  @override
  Duration get reverseTransitionDuration =>
      FluentMotion.animationsDisabled ? .zero : transition.reverseDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

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
    return _FluentRouteTransition(
      route: this,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

final class const _FluentRouteTransition({
  required final _FluentTransitionRoute<dynamic> route,
  required final Animation<double> animation,
  required final Animation<double> secondaryAnimation,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_FluentRouteTransition> createState() => _FluentRouteTransitionState();
}

final class _FluentRouteTransitionState() extends State<_FluentRouteTransition> {
  static const _scaleSnapThreshold = 0.001;

  final _snapshotController = SnapshotController();
  final _painter = _TransitionFramePainter();
  bool _rtl = false;
  bool _ignorePointer = false;

  @override
  void initState() {
    super.initState();
    _listenTo(widget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rtl = Directionality.of(context) == .rtl;
    _updateFrame();
  }

  @override
  void didUpdateWidget(_FluentRouteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _stopListeningTo(oldWidget);
      _listenTo(widget);
    }
    _updateFrame();
  }

  @override
  void dispose() {
    _stopListeningTo(widget);
    _snapshotController.dispose();
    _painter.dispose();
    super.dispose();
  }

  void _listenTo(_FluentRouteTransition transition) {
    transition.animation
      ..addListener(_onTick)
      ..addStatusListener(_onStatusChanged);
    transition.secondaryAnimation
      ..addListener(_onTick)
      ..addStatusListener(_onStatusChanged);
  }

  void _stopListeningTo(_FluentRouteTransition transition) {
    transition.animation
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatusChanged);
    transition.secondaryAnimation
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatusChanged);
  }

  void _onTick() => _updateFrame(rebuild: true);

  void _onStatusChanged(AnimationStatus _) => _updateFrame(rebuild: true);

  void _updateFrame({bool rebuild = false}) {
    final _FluentTransitionRoute<dynamic> route = widget.route;
    final NavigationTransitionFrame raw = route.transition
        .primaryFrame(widget.animation, rtl: _rtl)
        .combine(route._coveringTransition.secondaryFrame(widget.secondaryAnimation, rtl: _rtl));
    final frame = (raw.scale - 1.0).abs() < _scaleSnapThreshold
        ? NavigationTransitionFrame(opacity: raw.opacity, dx: raw.dx, dy: raw.dy)
        : raw;
    _painter.frame = frame;

    _snapshotController.allowSnapshotting =
        widget.animation.status == .forward &&
        (frame.scale != 1.0 || (frame.opacity > 0.0 && frame.opacity < 1.0));

    final bool ignorePointer =
        frame.opacity <= 0.0 ||
        widget.animation.isAnimating ||
        widget.secondaryAnimation.isAnimating;
    if (ignorePointer == _ignorePointer) return;
    if (rebuild) {
      setState(() => _ignorePointer = ignorePointer);
    } else {
      _ignorePointer = ignorePointer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _ignorePointer,
      child: SnapshotWidget(
        controller: _snapshotController,
        painter: _painter,
        mode: .permissive,
        autoresize: true,
        child: widget.child,
      ),
    );
  }
}

final class _TransitionFramePainter() extends SnapshotPainter {
  NavigationTransitionFrame _frame = .identity;

  final _transform = Matrix4.identity();
  final _transformLayer = LayerHandle<TransformLayer>();
  final _opacityLayer = LayerHandle<OpacityLayer>();

  NavigationTransitionFrame get frame => _frame;
  set frame(NavigationTransitionFrame value) {
    if (value.opacity == _frame.opacity &&
        value.dx == _frame.dx &&
        value.dy == _frame.dy &&
        value.scale == _frame.scale) {
      return;
    }
    _frame = value;
    notifyListeners();
  }

  int get _alpha => (_frame.opacity * 255).round().clamp(0, 255);

  @override
  void paint(PaintingContext context, Offset offset, Size size, PaintingContextCallback painter) {
    final int alpha = _alpha;
    final Offset shifted = offset.translate(_frame.dx, _frame.dy);

    void paintFaded(PaintingContext context, Offset offset) {
      if (alpha == 255) {
        _opacityLayer.layer = null;
        painter(context, offset);
      } else {
        _opacityLayer.layer = context.pushOpacity(
          offset,
          alpha,
          painter,
          oldLayer: _opacityLayer.layer,
        );
      }
    }

    if (alpha == 0) {
      _transformLayer.layer = null;
      _opacityLayer.layer = null;
      return;
    }
    if (_frame.scale == 1.0) {
      _transformLayer.layer = null;
      paintFaded(context, shifted);
      return;
    }

    final double scale = _frame.scale;
    _transform
      ..setIdentity()
      ..translateByDouble(size.width / 2, size.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
    _transformLayer.layer = context.pushTransform(
      true,
      shifted,
      _transform,
      paintFaded,
      oldLayer: _transformLayer.layer,
    );
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    final int alpha = _alpha;
    if (alpha == 0) return;

    final destination = Rect.fromCenter(
      center: (offset & size).center.translate(_frame.dx, _frame.dy),
      width: size.width * _frame.scale,
      height: size.height * _frame.scale,
    );
    context.canvas.drawImageRect(
      image,
      Offset.zero & sourceSize,
      destination,
      Paint()
        ..filterQuality = .medium
        ..color = .fromARGB(alpha, 0, 0, 0),
    );
  }

  @override
  bool shouldRepaint(covariant SnapshotPainter oldPainter) => oldPainter != this;

  @override
  void dispose() {
    _transformLayer.layer = null;
    _opacityLayer.layer = null;
    super.dispose();
  }
}
