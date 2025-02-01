import 'package:common/common.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:revitool/utils.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'app_settings_notifier.g.dart';

part 'app_settings_notifier.freezed.dart';

enum NavigationIndicators { sticky, end }

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppSettings build() => AppSettings(
        accentColor: getSystemAccentColor(SystemTheme.accentColor),
        themeMode: SettingsService.themeMode(),
        displayMode: PaneDisplayMode.auto,
        indicator: NavigationIndicators.sticky,
        windowEffect: WinRegistryService.themeTransparencyEffect
            ? (WinRegistryService.isW11
                ? WindowEffect.mica
                : WindowEffect.disabled)
            : WindowEffect.disabled,
        textDirection: TextDirection.ltr,
        locale: _localeFromString(appLanguage),
      );

  void setAccentColor(SystemAccentColor accentColor) {
    state = state.copyWith(accentColor: getSystemAccentColor(accentColor));
  }

  void updateThemeMode(ThemeMode? newThemeMode) {
    if (newThemeMode == null) return;
    if (newThemeMode == state.themeMode) return;
    state = state.copyWith(themeMode: newThemeMode);
    // SettingsService.updateThemeMode(newThemeMode);
  }

  void updateDisplayMode(PaneDisplayMode displayMode) {
    state = state.copyWith(displayMode: displayMode);
  }

  void updateIndicator(NavigationIndicators indicator) {
    state = state.copyWith(indicator: indicator);
  }

  void setWindowEffect(WindowEffect effect) {
    state = state.copyWith(windowEffect: effect);
  }

  void setEffect(Color micaBackgroundColor, bool isDark) async {
    Window.setEffect(
      effect: state.windowEffect,
      color: state.windowEffect == WindowEffect.mica
          ? micaBackgroundColor.withValues(alpha: 0.05)
          : Colors.transparent,
      dark: isDark,
    );
  }

  Color? effectColor(Color? color, {bool modifyColors = false}) {
    if (state.windowEffect != WindowEffect.disabled) {
      if (modifyColors) {
        return color?.withValues(alpha: 0.05);
      }
      return Colors.transparent;
    }
    return color;
  }

  void updateTextDirection(TextDirection direction) {
    state = state.copyWith(textDirection: direction);
  }

  Locale _localeFromString(String s) {
    return Locale(s.split("_")[0], s.split("_")[1]);
  }

  void updateLocale(String locale) {
    state = state.copyWith(locale: _localeFromString(locale));
  }
}

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required AccentColor accentColor,
    required ThemeMode themeMode,
    required PaneDisplayMode displayMode,
    required NavigationIndicators indicator,
    required WindowEffect windowEffect,
    required TextDirection textDirection,
    required Locale locale,
  }) = _AppSettings;
}

AccentColor getSystemAccentColor(SystemAccentColor accentColor) {
  if ((defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.android) &&
      !kIsWeb) {
    return AccentColor.swatch({
      'darkest': accentColor.darkest,
      'darker': accentColor.darker,
      'dark': accentColor.dark,
      'normal': accentColor.accent,
      'light': accentColor.light,
      'lighter': accentColor.lighter,
      'lightest': accentColor.lightest,
    });
  }
  return Colors.red;
}

class SettingsService {
  SettingsService._();
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;

  static ThemeMode themeMode() {
    switch (WinRegistryService.themeModeReg) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static void updateThemeMode(ThemeMode theme) {
    WinRegistryService.writeRegistryValue(Registry.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'ThemeMode', theme.name);
  }
}
