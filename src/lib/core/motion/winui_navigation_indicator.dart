import 'package:fluent_ui/fluent_ui.dart';

import 'fluent_motion.dart';

final class const WinUINavigationIndicator({
  super.key,
  super.color,
  final double indicatorSize = 3.0,
  final double inset = 10.0,
}) extends NavigationIndicator {
  @override
  NavigationIndicatorState<WinUINavigationIndicator> createState() =>
      _WinUINavigationIndicatorState();
}

final class _WinUINavigationIndicatorState()
    extends NavigationIndicatorState<WinUINavigationIndicator>
    with SingleTickerProviderStateMixin {
  static final _byIndex = <int, _WinUINavigationIndicatorState>{};

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FluentMotion.selectionIndicator,
    value: 1.0,
  );

  int? _registeredIndex;
  int? _lastSelected;

  bool _outgoing = false;

  bool _measuring = false;

  double _from = 0.0;
  double _to = 0.0;

  bool get _isMinimal => NavigationView.dataOf(context).displayMode == .minimal;

  bool get _movesVertically => axis == .horizontal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final int index = itemIndex;
    if (_registeredIndex != index) {
      _unregister();
      _byIndex[index] = this;
      _registeredIndex = index;
    }

    final int selected = selectedIndex;
    final int? previous = _lastSelected;
    _lastSelected = selected;
    if (previous == null || previous == selected) return;

    final bool animate =
        previous >= 0 && selected >= 0 && !_isMinimal && !FluentMotion.animationsDisabled;

    if (index == selected) {
      _outgoing = false;
      if (animate) {
        _measureAndAnimate(other: previous);
      } else {
        _settle();
      }
    } else if (index == previous) {
      _outgoing = true;
      if (animate) {
        _measureAndAnimate(other: selected);
      } else {
        _settle();
      }
    } else {
      _outgoing = false;
    }
  }

  void _settle() {
    _controller.value = 1.0;
    _from = 0.0;
    _to = 0.0;
  }

  void _measureAndAnimate({required int other}) {
    _controller.value = 0.0;
    _from = 0.0;
    _to = 0.0;
    _measuring = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final double? distance = _distanceTo(other);
      setState(() {
        _measuring = false;
        if (distance != null) {
          _from = _outgoing ? 0.0 : distance;
          _to = _outgoing ? distance : 0.0;
        }
      });
      _controller.forward(from: 0.0);
    });
  }

  double? _distanceTo(int otherIndex) {
    final _WinUINavigationIndicatorState? other = _byIndex[otherIndex];
    if (other == null || !other.mounted) return null;

    final RenderObject? mine = context.findRenderObject();
    final RenderObject? theirs = other.context.findRenderObject();
    if (mine is! RenderBox || theirs is! RenderBox) return null;
    if (!mine.attached || !theirs.attached || !mine.hasSize || !theirs.hasSize) return null;

    final Offset delta = theirs.localToGlobal(.zero) - mine.localToGlobal(.zero);
    return _movesVertically ? delta.dy : delta.dx;
  }

  void _unregister() {
    final int? index = _registeredIndex;
    if (index != null && identical(_byIndex[index], this)) {
      _byIndex.remove(index);
    }
  }

  @override
  void dispose() {
    _unregister();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSelected && !_outgoing) return const SizedBox.shrink();

    final FluentThemeData theme = FluentTheme.of(context);
    final Color color =
        widget.color ?? NavigationPaneTheme.of(context).highlightColor ?? theme.accentColor;
    final double itemExtent = kPaneItemMinHeight + theme.visualDensity.baseSizeAdjustment.dy;

    return IgnorePointer(
      child: CustomPaint(
        painter: _IndicatorPainter(
          progress: _controller,
          color: color,
          from: _from,
          to: _to,
          outgoing: _outgoing,
          hidden: _measuring && !_outgoing,
          vertical: _movesVertically,
          textDirection: Directionality.of(context),
          thickness: widget.indicatorSize,
          inset: widget.inset,
          itemExtent: itemExtent < 0.0 ? 0.0 : itemExtent,
        ),
      ),
    );
  }
}

const double _stretchEnd = 1.0 / 3.0;

double _settleProgress(double t) => ((t - _stretchEnd) / (1.0 - _stretchEnd)).clamp(0.0, 1.0);

(double, double) winUIIndicatorSegment(double t, double from, double to, double length) {
  final double distance = to - from;
  if (distance == 0.0) return (from, from + length);

  final double stretch = FluentMotion.indicatorStretch.transform((t / _stretchEnd).clamp(0.0, 1.0));
  final double settle = FluentMotion.decelerate.transform(_settleProgress(t));

  if (distance > 0.0) {
    return (from + distance * settle, from + length + distance * stretch);
  }
  return (from + distance * stretch, from + length + distance * settle);
}

class _IndicatorPainter({
  required final Animation<double> progress,
  required final Color color,
  required final double from,
  required final double to,
  required final bool outgoing,
  required final bool hidden,
  required final bool vertical,
  required final TextDirection textDirection,
  required final double thickness,
  required final double inset,
  required final double itemExtent,
}) extends CustomPainter {
  this : super(repaint: progress);

  static const double _startPadding = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (hidden) return;

    final double t = progress.value;
    var opacity = 1.0;
    if (outgoing) {
      if (t >= 1.0) return;
      if (t > _stretchEnd) {
        opacity = 1.0 - FluentMotion.decelerate.transform(_settleProgress(t));
      }
    }
    if (opacity <= 0.0) return;

    final double extent = vertical ? size.height : size.width;
    final double box = extent < itemExtent ? extent : itemExtent;
    final double length = box - inset * 2.0;
    if (length <= 0.0) return;
    final double rest = (extent - length) / 2.0;

    final (double start, double end) = winUIIndicatorSegment(t, from, to, length);

    final Rect rect;
    if (vertical) {
      final double x = textDirection == .rtl
          ? size.width - _startPadding - thickness
          : _startPadding;
      rect = .fromLTRB(x, rest + start, x + thickness, rest + end);
    } else {
      final double y = size.height - thickness;
      rect = .fromLTRB(rest + start, y, rest + end, y + thickness);
    }

    canvas.drawRRect(
      .fromRectAndRadius(rect, .circular(thickness / 2.0)),
      .new()..color = color.withValues(alpha: color.a * opacity),
    );
  }

  @override
  bool shouldRepaint(_IndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.outgoing != outgoing ||
        oldDelegate.hidden != hidden ||
        oldDelegate.vertical != vertical ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.thickness != thickness ||
        oldDelegate.inset != inset ||
        oldDelegate.itemExtent != itemExtent;
  }
}
