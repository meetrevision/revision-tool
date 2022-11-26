import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool wuPageBool = readRegistryInt(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'IsWUHidden') == 1;
  bool wuDriversBool = readRegistryInt(RegistryHive.localMachine, r'Software\Policies\Microsoft\Windows\WindowsUpdate', 'ExcludeWUDriversInQualityUpdate') != 1;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Windows Updates'),
      ),
      children: [
        //  subtitle(content: const Text('A simple ToggleSwitch')),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.action_center,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Hide the Windows Updates page'),
                      Text(
                        "Showing this page will also enable update notifications.",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(wuPageBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: wuPageBool,
                onChanged: (bool value) async {
                  setState(() {
                    wuPageBool = value;
                  });
                  if (wuPageBool) {
                    writeRegistryString(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'SettingsPageVisibility',
                        "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;windowsinsider-optin;windowsinsider;windowsupdate");
                    writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'IsWUHidden', 1);
                    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
                    await Process.run('explorer.exe', [], runInShell: true);
                  } else {
                    writeRegistryString(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'SettingsPageVisibility',
                        "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;");
                    writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'IsWUHidden', 0);
                    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
                    await Process.run('explorer.exe', [], runInShell: true);
                  }
                },
              ),
            ],
          ),
        ),
        //
        const SizedBox(height: 5.0),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.devices4,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Automatic Driver Updates'),
                      Text(
                        "Windows will automatically update drivers",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(wuDriversBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: wuDriversBool,
                onChanged: (bool value) {
                  setState(() {
                    wuDriversBool = value;
                  });
                  if (wuDriversBool) {
                    writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\Windows\DriverSearching', 'DontPromptForWindowsUpdate', 0);
                    writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows\DriverSearching', 'DontPromptForWindowsUpdate', 0);
                    writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows\WindowsUpdate', 'ExcludeWUDriversInQualityUpdate', 0);
                  } else {
                    writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\Windows\DriverSearching', 'DontPromptForWindowsUpdate', 1);
                    writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows\DriverSearching', 'DontPromptForWindowsUpdate', 1);
                    writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows\WindowsUpdate', 'ExcludeWUDriversInQualityUpdate', 1);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
