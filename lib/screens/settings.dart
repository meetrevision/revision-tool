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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode theme;
  String updateTitle = "Check for Updates";

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
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.brush,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: ReviLocalizations.of(context).settingsCTLabel),
                      Text(
                        ReviLocalizations.of(context).settingsCTDescription,
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              ComboBox(
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
            ],
          ),
        ),
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.picture_library,
          label: ReviLocalizations.of(context).settingsEPTLabel,
          description: ReviLocalizations.of(context).settingsEPTDescription,
          switchBool: expBool,
          function: (value) {
            setState(() {
              if (value) {
                writeRegistryDword(Registry.localMachine, r'SOFTWARE\Revision\Revision Tool', 'Experimental', 1);
              } else {
                writeRegistryDword(Registry.localMachine, r'SOFTWARE\Revision\Revision Tool', 'Experimental', 0);
              }
              expBool = value;
            });
          },
        ),

        //
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: SizedBox(
                  width: 150,
                  child: Button(
                    child: Text(updateTitle),
                    onPressed: () async {
                      Directory tempDir = await getTemporaryDirectory();
                      PackageInfo packageInfo = await PackageInfo.fromPlatform();
                      int currentVersion = int.parse(packageInfo.version.replaceAll(".", ""));
                      Map<String, dynamic> data = await Network.getJSON("https://api.github.com/repos/meetrevision/revision-tool/releases/latest");
                      int latestVersion = int.parse(data["tag_name"].toString().replaceAll(".", ""));
                      if (latestVersion > currentVersion) {
                        setState(() {
                          updateTitle = ReviLocalizations.of(context).settingsUpdateButton;
                        });
                        showDialog(
                          context: context,
                          builder: (context) => ContentDialog(
                            title: Text(ReviLocalizations.of(context).settingsUpdateButtonAvailable),
                            content: Text("${ReviLocalizations.of(context).settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?"),
                            actions: [
                              Button(
                                child: Text(ReviLocalizations.of(context).okButton),
                                onPressed: () async {
                                  setState(() {
                                    updateTitle = "${ReviLocalizations.of(context).settingsUpdatingStatus}...";
                                  });
                                  Navigator.pop(context);
                                  await Network.downloadNewVersion(data["assets"][0]["browser_download_url"], tempDir.path);
                                  setState(() {
                                    updateTitle = ReviLocalizations.of(context).settingsUpdatingStatusSuccess;
                                  });
                                },
                              ),
                              FilledButton(
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
                          updateTitle = ReviLocalizations.of(context).settingsUpdatingStatusNotFound;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
