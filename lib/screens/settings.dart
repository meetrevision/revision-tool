import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/theme.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode theme;
  String _updateTitle = "Check for Updates";

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return ScaffoldPage.scrollable(
      resizeToAvoidBottomInset: false,
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageSettings),
      ),
      children: [
        CardHighlight(
          icon: msicons.FluentIcons.paint_brush_20_regular,
          label: ReviLocalizations.of(context).settingsCTLabel,
          description: ReviLocalizations.of(context).settingsCTDescription,
          child: ComboBox(
            value: appTheme.themeMode,
            onChanged: appTheme.updateThemeMode,
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
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.warning_20_regular,
          label: ReviLocalizations.of(context).settingsEPTLabel,
          // description: ReviLocalizations.of(context).settingsEPTDescription,
          switchBool: expBool,
          function: (value) =>
            setState(() {
              writeRegistryDword(Registry.localMachine,
                  r'SOFTWARE\Revision\Revision Tool', 'Experimental', value ? 1 : 0);
              expBool = value;
            })
          ,
        ),
        CardHighlight(
          label: ReviLocalizations.of(context).settingsUpdateLabel,
          icon: msicons.FluentIcons.arrow_clockwise_20_regular,
          child: FilledButton(
            child: Text(_updateTitle),
            onPressed: () async {
              final Directory tempDir = await getTemporaryDirectory();
              final PackageInfo packageInfo = await PackageInfo.fromPlatform();
              final int currentVersion =
                  int.parse(packageInfo.version.replaceAll(".", ""));
              Map<String, dynamic> data = await Network.getJSON(
                  "https://api.github.com/repos/meetrevision/revision-tool/releases/latest");
              int latestVersion =
                  int.parse(data["tag_name"].toString().replaceAll(".", ""));
              if (latestVersion > currentVersion) {
                setState(() {
                  _updateTitle =
                      ReviLocalizations.of(context).settingsUpdateButton;
                });
                // ignore: use_build_context_synchronously
                showDialog(
                  context: context,
                  builder: (context) => ContentDialog(
                    title: Text(ReviLocalizations.of(context)
                        .settingsUpdateButtonAvailable),
                    content: Text(
                        "${ReviLocalizations.of(context).settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?"),
                    actions: [
                      FilledButton(
                        child: Text(ReviLocalizations.of(context).okButton),
                        onPressed: () async {
                          setState(() {
                            _updateTitle =
                                "${ReviLocalizations.of(context).settingsUpdatingStatus}...";
                          });
                          Navigator.pop(context);
                          await Network.downloadNewVersion(
                              data["assets"][0]["browser_download_url"],
                              tempDir.path);
                          setState(() {
                            _updateTitle = ReviLocalizations.of(context)
                                .settingsUpdatingStatusSuccess;
                          });
                        },
                      ),
                      Button(
                        child: Text(ReviLocalizations.of(context).notNowButton),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              } else {
                setState(() {
                  _updateTitle = ReviLocalizations.of(context)
                      .settingsUpdatingStatusNotFound;
                });
              }
            },
          ),
        ),
        CardHighlight(
          icon: msicons.FluentIcons.local_language_20_regular,
          label: ReviLocalizations.of(context).settingsLanguageLabel,
          child: ComboBox(
            value: appLanguage,
            onChanged: (value) {
              setState(() {
                appLanguage = value ?? 'en_US';
                writeRegistryString(Registry.localMachine,
                    r'SOFTWARE\Revision\Revision Tool', 'Language', appLanguage);
              });
              showDialog(
                context: context,
                builder: (context) => ContentDialog(
                  content: Text(ReviLocalizations.of(context).restartAppDialog),
                  actions: [
                    Button(
                      child: Text(ReviLocalizations.of(context).okButton),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              );
            },
            items: const [
              ComboBoxItem(
                value: 'en_US',
                child: Text('English'),
              ),
                ComboBoxItem(
                value: 'pt_BR',
                child: Text('Português (Brasileiro)'),
              ),
                 ComboBoxItem(
                 value: 'zh_CN',
                 child: Text('简体中文'),
              )
            ],
          ),
        ),
      ],
    );
  }
}
