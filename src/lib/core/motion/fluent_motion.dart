import 'dart:ffi' show AllocatorAlloc, Int32, Int32Pointer, Pointer;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:win32/win32.dart'
    show
        SPI_GETCLIENTAREAANIMATION,
        SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS,
        SystemParametersInfo,
        Win32Result;

/// Motion tokens for Windows 11 style navigation.
///
/// The page transition values are taken from WinUI 3's own implementation of
/// `EntranceNavigationTransitionInfo`, `SlideNavigationTransitionInfo` and
/// `DrillInNavigationTransitionInfo` (microsoft/microsoft-ui-xaml,
/// `dxaml/phone/lib/ThemeTransitions.cpp`). The selection indicator values come
/// from `NavigationView::PlayIndicatorAnimations`
/// (`controls/dev/NavigationView/NavigationView.cpp`).
///
/// See also:
///  * https://learn.microsoft.com/windows/apps/design/motion/page-transitions
///  * https://learn.microsoft.com/windows/apps/design/motion/timing-and-easing
abstract final class FluentMotion() {
  /// The spline WinUI uses for content coming to rest, e.g. the incoming page
  /// in Entrance and Slide transitions: `KeySpline 0.1,0.9 0.2,1.0`.
  static const Curve decelerate = Cubic(0.1, 0.9, 0.2, 1.0);

  /// The spline WinUI uses for content leaving, e.g. the outgoing page in
  /// Entrance and Slide transitions: `KeySpline 0.7,0.0 1.0,0.5`.
  static const Curve accelerate = Cubic(0.7, 0.0, 1.0, 0.5);

  /// Opacity spline of the drill transitions: `KeySpline 0.17,0.17 0.0,1.0`.
  static const Curve drillOpacity = Cubic(0.17, 0.17, 0.0, 1.0);

  /// Scale spline of the page revealed by a drill back navigation:
  /// `KeySpline 0.12,0.0 0.0,1.0`.
  static const Curve drillBackScale = Cubic(0.12, 0.0, 0.0, 1.0);

  /// First phase of the NavigationView selection indicator, where the pill
  /// stretches towards the newly selected item.
  static const Curve indicatorStretch = Cubic(0.9, 0.1, 1.0, 0.2);

  /// Fluent "Fast Out, Slow In" curve for elements entering the scene.
  static const Curve fastOutSlowIn = Cubic(0.0, 0.0, 0.0, 1.0);

  /// Fluent "Point to Point" curve for elements that are already on screen.
  static const Curve pointToPoint = Cubic(0.55, 0.55, 0.0, 1.0);

  /// Fluent "Slow Out, Fast In" curve for elements exiting the scene.
  static const Curve softOut = Cubic(1.0, 0.0, 1.0, 1.0);

  /// How long the outgoing page animates in Entrance and Slide transitions.
  static const Duration pageExit = Duration(milliseconds: 150);

  /// How long the incoming page animates in Entrance and Slide transitions.
  /// It starts after [pageExit] has finished.
  static const Duration pageEnter = Duration(milliseconds: 300);

  /// Total length of an Entrance or Slide transition ([pageExit] + [pageEnter]).
  static const Duration pageTransition = Duration(milliseconds: 450);

  /// Scale duration of the incoming page in a forward drill-in.
  static const Duration drillInScale = Duration(milliseconds: 783);

  /// Opacity duration of the incoming page in a forward drill-in, and the whole
  /// duration of a drill back navigation.
  static const Duration drillInFade = Duration(milliseconds: 333);

  /// How long the outgoing page animates in a drill transition.
  static const Duration drillExit = Duration(milliseconds: 100);

  /// Duration of the NavigationView selection indicator animation.
  static const Duration selectionIndicator = Duration(milliseconds: 600);

  /// Standard WinUI control durations (`ControlNormalAnimationDuration`,
  /// `ControlFastAnimationDuration`, `ControlFasterAnimationDuration`).
  static const Duration controlNormal = Duration(milliseconds: 250);
  static const Duration controlFast = Duration(milliseconds: 167);
  static const Duration controlFaster = Duration(milliseconds: 83);

  /// How far below its final position the incoming page starts in an Entrance
  /// transition, in logical pixels.
  static const double entranceOffset = 140;

  /// How far to the side the incoming page starts in a Slide transition.
  static const double slideEnterOffset = 200;

  /// How far to the side the outgoing page moves in a Slide transition.
  static const double slideExitOffset = 150;

  static const double drillInFromScale = 0.94;
  static const double drillOutToScale = 1.04;
  static const double drillBackFromScale = 1.06;
  static const double drillBackOutToScale = 0.96;

  /// Whether the user turned off "Animation effects" in Windows settings.
  ///
  /// Flutter's Windows embedder doesn't report this setting, so it is read
  /// from Windows directly.
  static bool get animationsDisabled =>
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations ||
      !_windowsAnimationsEnabled();

  static bool _windowsAnimationsEnabled() {
    if (!Platform.isWindows) return true;
    return using((arena) {
      final Pointer<Int32> enabled = arena<Int32>()..value = 1;
      final Win32Result<bool> result = SystemParametersInfo(
        SPI_GETCLIENTAREAANIMATION,
        0,
        enabled,
        const SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS(0),
      );
      return !result.value || enabled.value != 0;
    });
  }
}
