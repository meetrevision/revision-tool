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

enum NavigationIndicators { sticky, end }

@Riverpod(keepAlive: true)
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppSettings build() {
    final AppLocale appLocale = LocaleConfig.parse(appLanguage);
    return AppSettings(
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
      color: state.windowEffect == WindowEffect.mica
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
    if (state.windowEffect != WindowEffect.disabled) {
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
      LocaleSettings.setLocale(AppLocale.en);
      state = state.copyWith(locale: AppLocale.en.flutterLocale);
    }
  }

  Color? cardLightHoverBottomBorderColor() {
    final Color color = const Color.fromARGB(
      255,
      0,
      0,
      0,
    ).withValues(alpha: 0.11);
    if (state.windowEffect != WindowEffect.disabled) {
      return effectColor(color, modifyColors: true);
    }
    return color;
  }

  FluentThemeData buildDarkTheme(AccentColor accentColor, bool isLargeScreen) {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: accentColor,
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: effectColor(const Color.fromARGB(255, 32, 32, 32)),
        overlayBackgroundColor: const .fromARGB(255, 32, 32, 32),
      ),
      scaffoldBackgroundColor: effectColor(
        const Color.fromARGB(255, 32, 32, 32),
      ),
      visualDensity: VisualDensity.standard,
      focusTheme: FocusThemeData(glowFactor: isLargeScreen ? 2.0 : 0.0),
      resources: ResourceDictionary.dark(
        cardStrokeColorDefault: effectColor(
          const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.32),
          // const Color(0xFF1D1D1D),
          modifyColors: true,
        )!,
        cardBackgroundFillColorDefault: effectColor(
          const Color(0xFF2B2B2B),
          micaBackgroundColor: const Color.fromARGB(
            255,
            255,
            255,
            255,
          ).withValues(alpha: 0.05),
        )!,
        cardBackgroundFillColorSecondary: effectColor(
          const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.03),
          // const Color(0xFF323232),
          modifyColors: true,
        )!,
      ),
    );
  }

  FluentThemeData buildLightTheme(AccentColor accentColor, bool isLargeScreen) {
    return FluentThemeData(
      accentColor: accentColor,
      visualDensity: VisualDensity.standard,
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: effectColor(null),
        overlayBackgroundColor: const Color.fromRGBO(243, 243, 243, 100),
      ),
      scaffoldBackgroundColor: effectColor(
        const Color.fromRGBO(243, 243, 243, 100),
      ),
      focusTheme: FocusThemeData(glowFactor: isLargeScreen ? 2.0 : 0.0),
      resources: ResourceDictionary.light(
        cardStrokeColorDefault: effectColor(
          const Color.fromARGB(22, 0, 0, 0), // border color
          modifyColors: true,
        )!,
        cardBackgroundFillColorDefault: effectColor(
          // card color
          const Color(0xFFFBFBFB),
          micaBackgroundColor: const Color.fromARGB(255, 251, 251, 251),
        )!,
        cardBackgroundFillColorSecondary: effectColor(
          const Color.fromARGB(
            255,
            0,
            0,
            0,
          ).withValues(alpha: 0.02), // hover color
          modifyColors: true,
        )!,
      ),
    );
  }
}

@freezed
sealed class AppSettings with _$AppSettings {
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
  factory SettingsService() => _instance;
  SettingsService._();
  static final SettingsService _instance = SettingsService._();

  static ThemeMode themeMode() {
    switch (WinRegistryService.themeModeReg) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static void updateThemeMode(ThemeMode theme) {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'ThemeMode',
      theme.name,
    );
  }
}
