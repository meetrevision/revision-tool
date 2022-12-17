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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Windows Updates'),
      ),
      children: [
        CardHighlightSwitch(
          icon: FluentIcons.action_center,
          label: "Hide the Windows Updates page",
          description: "Showing this page will also enable update notifications.",
          switchBool: wuPageBool,
          function: (value) async {
            setState(() {
              wuPageBool = value;
            });
            if (wuPageBool) {
              writeRegistryString(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'SettingsPageVisibility',
                  "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;windowsinsider-optin;windowsinsider;windowsupdate");
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'IsWUHidden', 1);
            } else {
              writeRegistryString(
                  Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'SettingsPageVisibility', "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;");
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'IsWUHidden', 0);
            }
          },
        ),
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.devices4,
          label: "Automatic Driver Updates",
          description: "Windows will automatically update drivers",
          switchBool: wuDriversBool,
          function: (value) async {
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
    );
  }
}
