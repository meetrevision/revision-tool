import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:system_theme/system_theme.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../i18n/generated/strings.g.dart';
import '../../utils.dart';
import '../services/win_registry_service.dart';
import 'locale_config.dart';

part 'app_settings_provider.freezed.dart';
part 'app_settings_provider.g.dart';

enum NavigationIndicators() {
  sticky,
  end
}

@Riverpod(keepAlive: true)
class AppSettingsNotifier() extends _$AppSettingsNotifier {
  @override
  AppSettings build() {
    final AppLocale appLocale = LocaleConfig.parse(appLanguage);
    return .new(
      accentColor: getSystemAccentColor(SystemTheme.accentColor),
      themeMode: SettingsService.themeMode(),
      displayMode: .auto,
      indicator: .sticky,
      windowEffect: WinRegistryService.themeTransparencyEffect
          ? (WinRegistryService.isW11 ? .mica : .disabled)
          : .disabled,
      textDirection: .ltr,
      locale: appLocale.flutterLocale,
    );
  }

  void setAccentColor(SystemAccentColor accentColor) {
    state = state.copyWith(accentColor: getSystemAccentColor(accentColor));
  }

  void updateThemeMode(ThemeMode? newThemeMode) {
    if (newThemeMode == null) return;
    if (newThemeMode == state.themeMode) return;
    state = state.copyWith(themeMode: newThemeMode);
    SettingsService.updateThemeMode(newThemeMode);
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

  Future<void> setEffect(Color micaBackgroundColor, bool isDark) async {
    await Window.setEffect(
      effect: state.windowEffect,
      color: state.windowEffect == .mica
          ? micaBackgroundColor.withValues(alpha: 0.05)
          : Colors.transparent,
      dark: isDark,
    );
  }

  Color? effectColor(
    Color? color, {
    Color? micaBackgroundColor,
    double alpha = 0.05,
    bool modifyColors = false,
  }) {
    if (state.windowEffect != .disabled) {
      if (micaBackgroundColor != null) {
        return micaBackgroundColor;
      }
      if (modifyColors) {
        return color?.withValues(alpha: alpha);
      }
      return Colors.transparent;
    }
    return color;
  }

  void updateTextDirection(TextDirection direction) {
    state = state.copyWith(textDirection: direction);
  }

  void updateLocale(String localeName) {
    try {
      final AppLocale appLocale = LocaleConfig.parse(localeName);
      LocaleSettings.setLocale(appLocale);

      state = state.copyWith(locale: appLocale.flutterLocale);
    } catch (e) {
      logger.w('Failed to update locale: $e');
      LocaleSettings.setLocale(.en);
      state = state.copyWith(locale: AppLocale.en.flutterLocale);
    }
  }

  Color? cardLightHoverBottomBorderColor() {
    final Color color = const .fromARGB(255, 0, 0, 0).withValues(alpha: 0.11);
    if (state.windowEffect != .disabled) {
      return effectColor(color, modifyColors: true);
    }
    return color;
  }

  FluentThemeData buildDarkTheme(AccentColor accentColor, bool isLargeScreen) {
    return .new(
      brightness: .dark,
      accentColor: accentColor,
      navigationPaneTheme: .new(
        iconPadding: const EdgeInsetsDirectional.only(start: 10.5, end: 10),
        backgroundColor: effectColor(const .fromARGB(255, 32, 32, 32)),
        overlayBackgroundColor: const .fromARGB(255, 32, 32, 32),
      ),
      scaffoldBackgroundColor: effectColor(const .fromARGB(255, 32, 32, 32)),
      visualDensity: .standard,
      focusTheme: .new(glowFactor: isLargeScreen ? 2.0 : 0.0),
      resources: .dark(
        cardStrokeColorDefault: effectColor(
          const .fromARGB(255, 0, 0, 0).withValues(alpha: 0.32),
          // const Color(0xFF1D1D1D),
          modifyColors: true,
        )!,
        cardBackgroundFillColorDefault: effectColor(
          const Color(0xFF2B2B2B),
          micaBackgroundColor: const .fromARGB(255, 255, 255, 255).withValues(alpha: 0.05),
        )!,
        cardBackgroundFillColorSecondary: effectColor(
          const .fromARGB(255, 255, 255, 255).withValues(alpha: 0.03),
          // const Color(0xFF323232),
          modifyColors: true,
        )!,
      ),
    );
  }

  FluentThemeData buildLightTheme(AccentColor accentColor, bool isLargeScreen) {
    return .new(
      accentColor: accentColor,
      visualDensity: .standard,
      navigationPaneTheme: .new(
        iconPadding: const EdgeInsetsDirectional.only(start: 10.5, end: 10),
        backgroundColor: effectColor(null),
        overlayBackgroundColor: const .fromRGBO(243, 243, 243, 100),
      ),
      scaffoldBackgroundColor: effectColor(const .fromRGBO(243, 243, 243, 100)),
      focusTheme: .new(glowFactor: isLargeScreen ? 2.0 : 0.0),
      resources: .light(
        cardStrokeColorDefault: effectColor(
          const .fromARGB(22, 0, 0, 0), // border color
          modifyColors: true,
        )!,
        cardBackgroundFillColorDefault: effectColor(
          // card color
          const Color(0xFFFBFBFB),
          micaBackgroundColor: const .fromARGB(255, 251, 251, 251),
        )!,
        cardBackgroundFillColorSecondary: effectColor(
          const .fromARGB(255, 0, 0, 0).withValues(alpha: 0.02), // hover color
          modifyColors: true,
        )!,
      ),
    );
  }
}

@freezed
sealed class AppSettings with _$AppSettings {
  const factory({
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
  if ((defaultTargetPlatform == .windows || defaultTargetPlatform == .android) && !kIsWeb) {
    return .swatch({
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

class SettingsService._() {
  factory() => _instance;
  static final _instance = SettingsService._();

  static ThemeMode themeMode() {
    return switch (WinRegistryService.themeModeReg) {
      'light' => .light,
      'dark' => .dark,
      _ => .system,
    };
  }

  static void updateThemeMode(ThemeMode theme) {
    WinRegistryService.writeRegistryValue(
      LOCAL_MACHINE,
      r'SOFTWARE\Revision\Revision Tool',
      'ThemeMode',
      theme.name,
    );
  }
}
