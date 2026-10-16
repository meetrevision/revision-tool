import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:win32/win32.dart';
// ignore: implementation_imports
import 'package:window_plus/src/platform/platform_window.dart';
import 'package:window_plus/window_plus.dart';

final class const CaptionTitleBar({
  super.key,
  super.isBackButtonEnabled,
  super.isBackButtonVisible,
  super.backButton,
  super.onBackRequested,
  super.leftHeader,
  super.icon,
  super.title,
  super.subtitle,
  super.content,
  super.endHeader,
  super.height,
  super.captionControls,
  super.onDragStarted,
  super.onDragEnded,
  super.onDragCancelled,
  super.onDragUpdated,
}) extends TitleBar {
  @override
  Widget build(BuildContext context) => _CaptionDoubleClick(child: super.build(context));
}

final class const _CaptionDoubleClick({required final Widget child}) extends StatefulWidget {
  @override
  State<_CaptionDoubleClick> createState() => _CaptionDoubleClickState();
}

final class _CaptionDoubleClickState() extends State<_CaptionDoubleClick> {
  static const double _mouseSlop = 4.0;

  Duration? _lastDownTime;
  Offset? _lastDownPosition;

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton || _isOverInteractiveChild(event)) {
      _reset();
      return;
    }

    final Duration? lastTime = _lastDownTime;
    final Offset? lastPosition = _lastDownPosition;
    final double slop = event.kind == .mouse ? _mouseSlop : kDoubleTapSlop;
    final doubleClickTime = Duration(milliseconds: GetDoubleClickTime());

    final bool isDoubleClick =
        lastTime != null &&
        lastPosition != null &&
        event.timeStamp - lastTime <= doubleClickTime &&
        (event.position - lastPosition).distance <= slop;

    if (isDoubleClick) {
      _reset();
      unawaited(_toggleMaximized());
    } else {
      _lastDownTime = event.timeStamp;
      _lastDownPosition = event.position;
    }
  }

  void _reset() {
    _lastDownTime = null;
    _lastDownPosition = null;
  }

  bool _isOverInteractiveChild(PointerDownEvent event) {
    final RenderObject? self = context.findRenderObject();
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);

    var pointerListeners = 0;
    for (final HitTestEntry<HitTestTarget> entry in result.path) {
      if (identical(entry.target, self)) break;
      if (entry.target is RenderPointerListener) pointerListeners++;
    }
    return pointerListeners > 1;
  }

  Future<void> _toggleMaximized() async {
    final PlatformWindow window = WindowPlus.instance;
    if (!window.enableCustomFrame || await window.fullscreen) return;
    if (await window.maximized) {
      await window.restore();
    } else {
      await window.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(behavior: .translucent, onPointerDown: _handlePointerDown, child: widget.child);
  }
}
