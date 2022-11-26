import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:revitool/theme.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode theme;
  String updateTitle = "Check for Updates";

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {

    final appTheme = context.watch<AppTheme>();
    
    return ScaffoldPage.scrollable(
      resizeToAvoidBottomInset: false,
      header: const PageHeader(
        title: Text('Settings'),
      ),
      children: [
        CardHighlight(
          child: Row(
            children: [
              /* const SizedBox(width: 5.0),
              const Icon(FluentIcons.refresh, size: 24),
              const SizedBox(width: 15.0), */
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Revision Tool'),
                      Text(
                         'Version ${_packageInfo.version}.${_packageInfo.buildNumber}',
                         style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              Button(
                    child: Text(updateTitle),
                    onPressed: () async {
                      Directory tempDir = await getTemporaryDirectory();
                      PackageInfo packageInfo = await PackageInfo.fromPlatform();
                      int currentVersion = int.parse(packageInfo.version.replaceAll(".", ""));
                      Map<String, dynamic> data = await Network.getJSON("https://api.github.com/repos/meetrevision/revision-tool/releases/latest");
                      int latestVersion = int.parse(data["tag_name"].toString().replaceAll(".", ""));
                      if (latestVersion > currentVersion) {
                        setState(() {
                          updateTitle = "Update was found";
                        });
                        showDialog(
                          context: context,
                          builder: (context) => ContentDialog(
                            title: const Text("Update Available"),
                            content: Text("Would you like to update Revision Tool to ${data["tag_name"]}?"),
                            actions: [
                              Button(
                                child: const Text('OK'),
                                onPressed: () async {
                                  setState(() {
                                    updateTitle = "Updating...";
                                  });
                                  Navigator.pop(context);
                                  await Network.downloadNewVersion(data["assets"][0]["browser_download_url"], tempDir.path);
                                  setState(() {
                                    updateTitle = "Updated successfully";
                                  });
                                },
                              ),
                              FilledButton(
                                child: const Text('Not now'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        setState(() {
                          updateTitle = "No update was found";
                        });
                      }
                    },
              ),
            ],
          ),
        ),
        const SizedBox(height: 5.0),
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
                      InfoLabel(label: 'Color Theme'),
                      Text(
                        "Switch between light and dark mode, or automatically change the theme with Windows",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              ComboBox(
                value: appTheme.mode,
                items: [
                  ComboBoxItem(
                    value: ThemeMode.system,
                    child: Text(ThemeMode.system.name.uppercaseFirst()),
                    onTap: () => setState(() {
                      theme = ThemeMode.system;
                    }),
                  ),
                  ComboBoxItem(
                    value: ThemeMode.light,
                    child: Text(ThemeMode.light.name.uppercaseFirst()),
                    onTap: () => setState(() {
                      theme = ThemeMode.light;
                    }),
                  ),
                  ComboBoxItem(
                    value: ThemeMode.dark,
                    child: Text(ThemeMode.dark.name.uppercaseFirst()),
                    onTap: () => setState(() {
                      theme = ThemeMode.dark;
                    }),
                  ),
                ],
                onChanged: (value) {
                  appTheme.mode = theme;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 5.0),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(FluentIcons.picture_library, size: 24),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Show experimental tweaks'),
                      Text(
                        "Show additional, experimental tweaks inside the Revision Tool",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(expBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: expBool,
                onChanged: (bool value) async {
                  setState(() {
                    expBool = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
