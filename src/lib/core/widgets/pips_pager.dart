import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

import '../../extensions.dart';

/// Visibility state for collection control buttons.
enum PipsPagerButtonVisibility {
  /// Button is not visible and does not take layout space (default).
  collapsed,

  /// Button is always visible, hidden visually only at min/max page bounds
  /// but still takes up layout space.
  visible,

  /// Button is only visible when pointer hovers or focus is set.
  visibleOnPointerOver,
}

/// A paged view with a "pips" (dot) indicator and optional collection
/// controls that match Fluent/Windows guidelines.
///
/// Follows Microsoft's PipsPager design:
/// https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/pipspager
///
/// - `itemExtent` controls the height of the page area.
/// - `children` are the pages shown in the pager.
/// - Navigation buttons can be configured to auto-hide at boundaries.
/// - Pips scroll when exceeding [maxVisiblePips] (default: 5).
class PipsPager extends StatefulWidget {
  const PipsPager({
    super.key,
    required this.itemExtent,
    required this.children,
    this.controller,
    this.previousButtonVisibility = .collapsed,
    this.nextButtonVisibility = .collapsed,
    this.maxVisiblePips = 5,
    this.showIndicator = true,
    this.enabled = true,
    this.padEnds = true,
    this.onPageChanged,
  });

  /// Height of the page area.
  final double itemExtent;

  /// Pages to show.
  final List<Widget> children;

  /// Optional external [PageController]. If not provided an internal one is used.
  final PageController? controller;

  /// Visibility state of the previous button.
  final PipsPagerButtonVisibility previousButtonVisibility;

  /// Visibility state of the next button.
  final PipsPagerButtonVisibility nextButtonVisibility;

  /// Maximum number of visible pips. If [children.length] > this, pips scroll
  /// to center the current page. Default is 5.
  final int maxVisiblePips;

  /// Whether to show the pips indicator below the page area.
  final bool showIndicator;

  /// Whether the pager is enabled. When false, pips are visible but not
  /// interactive (page indicator only).
  final bool enabled;

  /// Whether the first and last pages are padded to center in the viewport.
  /// Set to false to avoid extra horizontal space with viewportFraction.
  final bool padEnds;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  @override
  State<PipsPager> createState() => _PipsPagerState();
}

class _PipsPagerState extends State<PipsPager> {
  late final PageController _controller;
  late final ScrollController _pipsScrollController;
  int _index = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageController();
    _pipsScrollController = ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _pipsScrollController.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    if (!widget.enabled) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    if (_index > 0) _animateTo(_index - 1);
  }

  void _next() {
    if (_index < widget.children.length - 1) _animateTo(_index + 1);
  }

  bool _shouldShowPipsScrollable() =>
      widget.children.length > widget.maxVisiblePips;

  void _scrollPipsToCenter() {
    if (!_shouldShowPipsScrollable()) return;

    const pipSize = 8; // width of a pip
    const pipSpacing = 6; // margin between pips

    final double pipWidth = (pipSize + pipSpacing).toDouble();
    final double targetOffset = (_index * pipWidth) - (75 - pipWidth);
    final double maxScroll = _pipsScrollController.position.maxScrollExtent;

    final double clampedOffset = targetOffset.clamp(0.0, maxScroll);
    _pipsScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 167),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final Color accent = theme.accentColor;
    final int count = widget.children.length;
    final atStart = _index == 0;
    final atEnd = _index == count - 1;

    return Column(
      mainAxisSize: .min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: SizedBox(
            height: widget.itemExtent,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  padEnds: widget.padEnds,
                  physics: widget.enabled
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _scrollPipsToCenter();
                    widget.onPageChanged?.call(i);
                  },
                  itemBuilder: (_, i) => Padding(
                    padding: const .symmetric(horizontal: 12),
                    child: RepaintBoundary.wrap(widget.children[i], i),
                  ),
                ),

                if (widget.previousButtonVisibility != .collapsed &&
                    count > 1 &&
                    !atStart)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: .centerLeft,
                      child: _NavButton(
                        icon: msicons.FluentIcons.caret_left_20_filled,
                        onPressed: widget.enabled ? _prev : null,
                        visibility: widget.previousButtonVisibility,
                        parentHovered: _isHovered,
                      ),
                    ),
                  ),
                if (widget.nextButtonVisibility != .collapsed &&
                    count > 1 &&
                    !atEnd)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: .centerRight,
                      child: _NavButton(
                        icon: msicons.FluentIcons.caret_right_20_filled,
                        onPressed: widget.enabled ? _next : null,
                        visibility: widget.nextButtonVisibility,
                        parentHovered: _isHovered,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.showIndicator) _buildPipsIndicator(accent, count),
      ],
    );
  }

  Widget _buildPipsIndicator(Color accent, int count) {
    final bool shouldScroll = _shouldShowPipsScrollable();

    return Padding(
      padding: const .only(top: 12),
      child: SingleChildScrollView(
        controller: _pipsScrollController,
        scrollDirection: .horizontal,
        physics: shouldScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: .min,
          children: List.generate(count, (i) {
            final isActive = i == _index;
            return GestureDetector(
              onTap: widget.enabled ? () => _animateTo(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 6 : 4,
                height: isActive ? 6 : 4,
                margin: const .symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: context.theme.resources.textFillColorSecondary
                      .withOpacity(widget.enabled ? .3 : .2),
                  borderRadius: .circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Isolated navigation button widget to prevent parent rebuilds on hover.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onPressed,
    required this.visibility,
    required this.parentHovered,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final PipsPagerButtonVisibility visibility;
  final bool parentHovered;

  @override
  Widget build(BuildContext context) {
    final bool shouldShow =
        visibility == .visible ||
        (visibility == .visibleOnPointerOver && parentHovered);
    final opacity = shouldShow ? 1.0 : 0.0;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !shouldShow,
        child: Container(
          width: 16,
          height: 48,
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            border: .all(color: context.theme.resources.cardStrokeColorDefault),
          ),
          child: HoverButton(
            onPressed: onPressed,
            builder: (context, states) {
              return Center(
                child: Icon(
                  icon,
                  size: 16,
                  color: states.isHovered
                      ? context.theme.resources.textFillColorPrimary
                      : context.theme.resources.textFillColorTertiary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
