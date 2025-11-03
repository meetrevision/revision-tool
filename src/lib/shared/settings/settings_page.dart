import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/extensions.dart';

import 'package:revitool/shared/settings/app_settings_provider.dart';
import 'package:revitool/shared/settings/tool_update_service.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

const languageList = [
  ComboBoxItem(value: 'en_US', child: Text('English')),
  ComboBoxItem(value: 'pt_BR', child: Text('Portuguese (Brazil)')),
  ComboBoxItem(value: 'zh_CN', child: Text('Chinese (Simplified)')),
  ComboBoxItem(value: 'zh_TW', child: Text('Chinese (Traditional)')),
  ComboBoxItem(value: 'de_DE', child: Text('German')),
  ComboBoxItem(value: 'fr_FR', child: Text('French')),
  ComboBoxItem(value: 'ru_RU', child: Text('Russian')),
  ComboBoxItem(value: 'uk_UA', child: Text('Ukrainian')),
  ComboBoxItem(value: 'hu_HU', child: Text('Hungarian')),
  ComboBoxItem(value: 'tr_TR', child: Text('Turkish')),
  ComboBoxItem(value: 'ar_SA', child: Text('Arabic')),
  ComboBoxItem(value: 'it_IT', child: Text('Italian')),
];

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageSettings)),
      children: const [
        _ThemeModeCard(),
        _ExperimentalCard(),
        _UpdateCard(),
        _LanguageCard(),
      ],
    );
  }
}

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.paint_brush_20_regular,
      label: context.l10n.settingsCTLabel,
      description: context.l10n.settingsCTDescription,
      action: ComboBox(
        value: appSettings.themeMode,
        onChanged: ref.read(appSettingsProvider.notifier).updateThemeMode,
        items: [
          ComboBoxItem(
            value: ThemeMode.system,
            child: Text(ThemeMode.system.name.uppercaseFirst()),
          ),
          ComboBoxItem(
            value: ThemeMode.light,
            child: Text(ThemeMode.light.name.uppercaseFirst()),
          ),
          ComboBoxItem(
            value: ThemeMode.dark,
            child: Text(ThemeMode.dark.name.uppercaseFirst()),
          ),
        ],
      ),
    );
  }
}

class _ExperimentalCard extends ConsumerWidget {
  const _ExperimentalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(settingsExperimentalStatus);

    return CardHighlight(
      icon: msicons.FluentIcons.warning_20_regular,
      label: context.l10n.settingsEPTLabel,
      // description: context.l10n.settingsEPTDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          WinRegistryService.writeRegistryValue(
            Registry.localMachine,
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

class _UpdateCard extends ConsumerStatefulWidget {
  const _UpdateCard();

  @override
  ConsumerState<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<_UpdateCard> {
  final _toolUpdateService = ToolUpdateService();
  final _updateTitle = ValueNotifier<String>("Check for Updates");

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      label: context.l10n.settingsUpdateLabel,
      icon: msicons.FluentIcons.arrow_clockwise_20_regular,
      action: ValueListenableBuilder(
        valueListenable: _updateTitle,
        builder: (context, value, child) => FilledButton(
          child: Text(_updateTitle.value),
          onPressed: () async {
            try {
              await _toolUpdateService.fetchData();
              final currentVersion = _toolUpdateService.getCurrentVersion;
              final latestVersion = _toolUpdateService.getLatestVersion;
              final data = _toolUpdateService.data;

              if (latestVersion > currentVersion) {
                if (!context.mounted) return;
                _updateTitle.value = context.l10n.settingsUpdateButton;

                final shouldInstall = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => ContentDialog(
                    title: Text(context.l10n.settingsUpdateButtonAvailable),
                    content: Text(
                      "${context.l10n.settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?",
                    ),
                    actions: [
                      FilledButton(
                        child: Text(context.l10n.okButton),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                      ),
                      Button(
                        child: Text(context.l10n.notNowButton),
                        onPressed: () => Navigator.pop(dialogCtx, false),
                      ),
                    ],
                  ),
                );

                if (shouldInstall == true) {
                  if (!context.mounted) return;
                  _updateTitle.value =
                      "${context.l10n.settingsUpdatingStatus}...";
                  try {
                    await _toolUpdateService.downloadNewVersion();
                    await _toolUpdateService.installUpdate();
                    if (!context.mounted) return;
                    _updateTitle.value =
                        context.l10n.settingsUpdatingStatusSuccess;
                  } catch (e) {
                    if (!context.mounted) return;
                    _updateTitle.value = "Update failed";
                    await showDialog(
                      context: context,
                      builder: (c) => ContentDialog(
                        title: const Text('Error'),
                        content: Text(e.toString()),
                        actions: [
                          Button(
                            child: Text(context.l10n.okButton),
                            onPressed: () => Navigator.pop(c),
                          ),
                        ],
                      ),
                    );
                  }
                }
              } else {
                if (!context.mounted) return;
                _updateTitle.value =
                    context.l10n.settingsUpdatingStatusNotFound;
              }
            } catch (e) {
              if (!context.mounted) return;
              await showDialog(
                context: context,
                builder: (c) => ContentDialog(
                  title: const Text('Error'),
                  content: Text(e.toString()),
                  actions: [
                    Button(
                      child: Text(context.l10n.okButton),
                      onPressed: () => Navigator.pop(c),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.local_language_20_regular,
      label: context.l10n.settingsLanguageLabel,
      description: context.l10n.settingsLanguageDescription,
      action: ComboBox(
        value: appLanguage,
        onChanged: (value) async {
          final newLanguage = value ?? 'en_US';
          WinRegistryService.writeRegistryValue(
            Registry.localMachine,
            r'SOFTWARE\Revision\Revision Tool',
            'Language',
            newLanguage,
          );
          ref.read(appSettingsProvider.notifier).updateLocale(newLanguage);
        },
        items: languageList,
      ),
    );
  }
}
