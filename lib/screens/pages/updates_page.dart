import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool _wuPageBool = readRegistryString(
              RegistryHive.localMachine,
              r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
              'SettingsPageVisibility')
          ?.contains("windowsupdate") ??
      false;

  bool _wuDriversBool = readRegistryInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
          'PreventDeviceMetadataFromNetwork') ==
      0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageUpdates),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.arrow_sync_20_regular,
          label: ReviLocalizations.of(context).wuPageLabel,
          description: ReviLocalizations.of(context).wuPageDescription,
          switchBool: _wuPageBool,
          function: (value) async {
            setState(() {
              _wuPageBool = value;
            });
            if (_wuPageBool) {
              writeRegistryString(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
                  'SettingsPageVisibility',
                  "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;windowsinsider-optin;windowsinsider;windowsupdate");
            } else {
              writeRegistryString(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
                  'SettingsPageVisibility',
                  "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;");
            }
          },
        ),
        CardHighlightSwitch(
          icon: FluentIcons.devices4,
          label: ReviLocalizations.of(context).wuDriversLabel,
          description: ReviLocalizations.of(context).wuDriversDescription,
          switchBool: _wuDriversBool,
          function: (value) async {
            setState(() {
              _wuDriversBool = value;
            });
            if (_wuDriversBool) {
              deleteRegistryKey(Registry.currentUser,
                  r'Software\Policies\Microsoft\Windows\DriverSearching');
              deleteRegistryKey(Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\DriverSearching');

              deleteRegistry(
                  Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\WindowsUpdate',
                  'ExcludeWUDriversInQualityUpdate');
              deleteRegistry(
                  Registry.localMachine,
                  r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
                  'PreventDeviceMetadataFromNetwork');
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
                  'PreventDeviceMetadataFromNetwork',
                  0);
            } else {
              writeRegistryDword(
                  Registry.currentUser,
                  r'Software\Policies\Microsoft\Windows\DriverSearching',
                  'DontPromptForWindowsUpdate',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\DriverSearching',
                  'DontPromptForWindowsUpdate',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\DriverSearching',
                  'SearchOrderConfig',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\WindowsUpdate',
                  'ExcludeWUDriversInQualityUpdate',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
                  'PreventDeviceMetadataFromNetwork',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
                  'PreventDeviceMetadataFromNetwork',
                  1);
            }
          },
        ),
      ],
    );
  }
}
