import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/extensions.dart';

import 'package:revitool/core/settings/app_settings_provider.dart';
import 'package:revitool/core/settings/locale_config.dart';
import 'package:revitool/core/settings/tool_update_service.dart';
import 'package:revitool/i18n/generated/strings.g.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

final languageList = AppLocale.values
    .map(
      (locale) => ComboBoxItem(
        value: locale.name,
        child: Text(LocaleConfig.languageNames[locale.name] ?? locale.name),
      ),
    )
    .toList();

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

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

class _ThemeModeCard extends ConsumerWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.paint_brush_20_regular,
      label: t.settingsCT,
      description: t.settingsCTDescription,
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
    ref.watch(appSettingsProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.warning_20_regular,
      label: t.settingsEPT,
      // description: t.settingsEPTDescription,
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
    ref.watch(appSettingsProvider);
    return CardHighlight(
      label: t.settingsUpdate,
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
                _updateTitle.value = t.settingsUpdateButton;

                final shouldInstall = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => ContentDialog(
                    title: Text(t.settingsUpdateButtonAvailable),
                    content: Text(
                      "${t.settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?",
                    ),
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

                if (shouldInstall == true) {
                  if (!context.mounted) return;
                  _updateTitle.value = "${t.settingsUpdatingStatus}...";
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
                          Button(
                            child: Text(t.okButton),
                            onPressed: () => Navigator.pop(c),
                          ),
                        ],
                      ),
                    );
                  }
                }
              } else {
                if (!context.mounted) return;
                _updateTitle.value = t.settingsUpdatingStatusNotFound;
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
                      child: Text(t.okButton),
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
      label: t.settingsLanguage,
      description: t.settingsLanguageDescription,
      action: ComboBox(
        value: TranslationProvider.of(context).locale.name,
        onChanged: (value) async {
          final localeName = value ?? AppLocale.en.name;
          await WinRegistryService.writeRegistryValue(
            Registry.localMachine,
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
