import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../extensions.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';
import '../services/win_registry_service.dart';
import '../widgets/app_icon_image.dart';
import '../widgets/card_highlight.dart';
import 'app_settings_provider.dart';
import 'locale_config.dart';
import 'tool_update_service.dart';

final List<ComboBoxItem<String>> languageList = AppLocale.values
    .map(
      (locale) => ComboBoxItem(
        value: locale.name,
        child: Text(LocaleConfig.languageNames[locale.name] ?? locale.name),
      ),
    )
    .toList();

class const SettingsPage({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: const [
        _ThemeModeCard(),
        _ExperimentalCard(),
        _LanguageCard(),
        _AboutCard(),
        _GetHelpLink(),
      ].withSpacing(5),
    );
  }
}

class const _ThemeModeCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings appSettings = ref.watch(appSettingsProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.paint_brush_20_regular,
      label: t.settingsCT,
      description: t.settingsCTDescription,
      action: ComboBox<ThemeMode>(
        value: appSettings.themeMode,
        onChanged: ref.read(appSettingsProvider.notifier).updateThemeMode,
        items: [
          .new(value: .system, child: Text(ThemeMode.system.name.uppercaseFirst())),
          .new(value: .light, child: Text(ThemeMode.light.name.uppercaseFirst())),
          .new(value: .dark, child: Text(ThemeMode.dark.name.uppercaseFirst())),
        ],
      ),
    );
  }
}

class const _ExperimentalCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(settingsExperimentalStatus);
    ref.watch(appSettingsProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.warning_20_regular,
      label: t.settingsEPT,
      // description: t.settingsEPTDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          await WinRegistryService.writeRegistryValue(
            LOCAL_MACHINE,
            r'SOFTWARE\Revision\Revision Tool',
            'Experimental',
            value ? 1 : 0,
          );
          ref.invalidate(settingsExperimentalStatus);
        },
      ),
    );
  }
}

final class const _CheckForUpdatesButton() extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CheckForUpdatesButton> createState() => _CheckForUpdatesButtonState();
}

final class _CheckForUpdatesButtonState() extends ConsumerState<_CheckForUpdatesButton> {
  static const _defaultTitle = 'Check for updates';

  final _toolUpdateService = ToolUpdateService();
  final _updateTitle = ValueNotifier<String>(_defaultTitle);
  bool _isChecking = false;

  void _resetTitleAfterDelay() {
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _updateTitle.value = _defaultTitle;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appSettingsProvider);
    return ValueListenableBuilder(
      valueListenable: _updateTitle,
      builder: (context, value, child) => FilledButton(
        child: Text(_updateTitle.value),
        onPressed: () async {
          if (_isChecking) return;
          _isChecking = true;
          _updateTitle.value = '${t.settingsUpdatingStatus}...';
          try {
            await _toolUpdateService.fetchData();
            final int currentVersion = _toolUpdateService.getCurrentVersion;
            final int latestVersion = _toolUpdateService.getLatestVersion;
            final Map<String, dynamic> data = _toolUpdateService.data;

            if (latestVersion > currentVersion) {
              if (!context.mounted) return;
              _updateTitle.value = t.settingsUpdateButton;

              final bool? shouldInstall = await showDialog<bool>(
                context: context,
                builder: (ctx) => ContentDialog(
                  title: Text(t.settingsUpdateButtonAvailable),
                  content: Text("${t.settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?"),
                  actions: [
                    FilledButton(child: Text(t.okButton), onPressed: () => ctx.pop(true)),
                    Button(child: Text(t.notNowButton), onPressed: () => ctx.pop(false)),
                  ],
                ),
              );

              if (shouldInstall ?? false) {
                if (!context.mounted) return;
                _updateTitle.value = '${t.settingsUpdatingStatus}...';
                try {
                  await _toolUpdateService.downloadNewVersion();
                  await _toolUpdateService.installUpdate();
                  if (!context.mounted) return;
                  _updateTitle.value = t.settingsUpdatingStatusSuccess;
                } catch (e) {
                  if (!context.mounted) return;
                  _updateTitle.value = t.updateFailed;
                  await showDialog(
                    context: context,
                    builder: (c) => ContentDialog(
                      title: const Text('Error'),
                      content: Text(e.toString()),
                      actions: [Button(child: Text(t.okButton), onPressed: () => Navigator.pop(c))],
                    ),
                  );
                  _resetTitleAfterDelay();
                }
              } else {
                _updateTitle.value = _defaultTitle;
              }
            } else {
              if (!context.mounted) return;
              _updateTitle.value = t.settingsUpdatingStatusNotFound;
              _resetTitleAfterDelay();
            }
          } catch (e) {
            if (!context.mounted) return;
            _updateTitle.value = t.updateFailed;
            await showDialog(
              context: context,
              builder: (c) => ContentDialog(
                title: const Text('Error'),
                content: Text(e.toString()),
                actions: [Button(child: Text(t.okButton), onPressed: () => Navigator.pop(c))],
              ),
            );
            _resetTitleAfterDelay();
          } finally {
            _isChecking = false;
          }
        },
      ),
    );
  }
}

class const _LanguageCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.local_language_20_regular,
      label: t.settingsLanguage,
      description: t.settingsLanguageDescription,
      action: ComboBox(
        value: TranslationProvider.of(context).locale.name,
        onChanged: (value) async {
          final String localeName = value ?? AppLocale.en.name;
          await WinRegistryService.writeRegistryValue(
            LOCAL_MACHINE,
            r'SOFTWARE\Revision\Revision Tool',
            'Language',
            localeName,
          );
          ref.read(appSettingsProvider.notifier).updateLocale(localeName);
        },
        items: languageList,
      ),
    );
  }
}

class const _AboutCard() extends StatelessWidget {
  static const _docsUrl = 'https://revi.cc/docs';
  static const _privacyUrl = 'https://revi.cc/privacy';
  static const _appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      initiallyExpanded: true,
      leading: const AppIconImage(
        size: 24.0,
        fallback: Icon(msicons.FluentIcons.info_20_regular, size: 24),
      ),
      label: t.settingsAbout,
      description: 'Revision Tool ${kDebugMode ? '(Debug)' : 'v$_appVersion'}',
      action: const _CheckForUpdatesButton(),
      children: [
        Padding(
          padding: const .only(left: 17.0, top: 16.75, bottom: 16.75, right: 17.0),
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            spacing: 16.0,
            children: [
              _AboutLink(label: t.settingsDocs, url: _docsUrl),
              _AboutLink(label: t.settingsPrivacy, url: _privacyUrl),
            ],
          ),
        ),
      ],
    );
  }
}

final class const _AboutLink({required final String label, required final String url})
    extends StatelessWidget {
  static const _childrenPadding = EdgeInsetsDirectional.symmetric(horizontal: 38.0, vertical: 9.0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .only(
        left: _childrenPadding.resolve(.ltr).left,
        right: _childrenPadding.resolve(.ltr).right,
      ),
      child: Tooltip(
        message: url,
        useMousePosition: false,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: HyperlinkButton(
            style: .new(backgroundColor: .all(Colors.transparent), padding: .all(.zero)),
            child: Text(label),
            onPressed: () async => launchURL(url),
          ),
        ),
      ),
    );
  }
}

final class const _GetHelpLink() extends StatelessWidget {
  static const _discordUrl = 'https://revi.cc/discord';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .centerLeft,
      child: Tooltip(
        useMousePosition: false,
        message: _discordUrl,
        child: HyperlinkButton(
          child: Text(t.settingsGetHelp),
          onPressed: () async => launchURL(_discordUrl),
        ),
      ),
    );
  }
}
