import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../extensions.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';
import '../services/win_registry_service.dart';
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
        _UpdateCard(),
        _LanguageCard(),
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
      action: Semantics(
        label: t.settingsCT,
        child: ComboBox<ThemeMode>(
          value: appSettings.themeMode,
          onChanged: ref.read(appSettingsProvider.notifier).updateThemeMode,
          items: [
            .new(value: .system, child: Text(ThemeMode.system.name.uppercaseFirst())),
            .new(value: .light, child: Text(ThemeMode.light.name.uppercaseFirst())),
            .new(value: .dark, child: Text(ThemeMode.dark.name.uppercaseFirst())),
          ],
        ),
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
        semanticLabel: t.settingsEPT,
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

class const _UpdateCard() extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState() extends ConsumerState<_UpdateCard> {
  static const _defaultTitle = 'Check for Updates';

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
    return CardHighlight(
      label: t.settingsUpdate,
      icon: msicons.FluentIcons.arrow_clockwise_20_regular,
      action: ValueListenableBuilder(
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
                  builder: (dialogCtx) => ContentDialog(
                    title: Text(t.settingsUpdateButtonAvailable),
                    content: Text("${t.settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?"),
                    actions: [
                      FilledButton(
                        child: Text(t.okButton),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                      ),
                      Button(
                        child: Text(t.notNowButton),
                        onPressed: () => Navigator.pop(dialogCtx, false),
                      ),
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
                        actions: [
                          Button(child: Text(t.okButton), onPressed: () => Navigator.pop(c)),
                        ],
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
      action: Semantics(
        label: t.settingsLanguage,
        child: ComboBox(
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
      ),
    );
  }
}
