import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'dart:io';
import 'package:process_run/shell_run.dart';

class UsabilityPageTwo extends StatefulWidget {
  const UsabilityPageTwo({super.key});

  @override
  State<UsabilityPageTwo> createState() => _UsabilityPageTwoState();
}

class _UsabilityPageTwoState extends State<UsabilityPageTwo> {
  bool mrcBool = readRegistryInt(RegistryHive.localMachine, r'Software\Classes\CLSID', 'IsModernRCEnabled') != 0;
  bool fetBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'EnabledState') != 1;

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
        title: Text('Usability > Windows 11'),
      ),
      children: [
        CardHighlightSwitch(
          icon: FluentIcons.context_menu,
          label: "New Windows 11 Context Menu",
          switchBool: mrcBool,
          function: (value) async {
            setState(() {
              mrcBool = value;
            });
            if (mrcBool) {
              Shell().run(r'reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f');
              // Error 0x80070005: Access is denied.
              // deleteRegistryKey(Registry.currentUser, r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}');
              writeRegistryDword(Registry.localMachine, r'Software\Classes\CLSID', 'IsModernRCEnabled', 1);
              await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
              await Process.run('explorer.exe', [], runInShell: true);
            } else {
              createRegistryKey(Registry.currentUser, r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32');
              writeRegistryString(Registry.currentUser, r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32', '', '');
              writeRegistryDword(Registry.localMachine, r'Software\Classes\CLSID', 'IsModernRCEnabled', 0);
              await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
              await Process.run('explorer.exe', [], runInShell: true);
            }
          },
        ),
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.explore_content,
          label: "File Explorer Tabs",
          switchBool: fetBool,
          function: (value) async {
            setState(() {
              fetBool = value;
            });
            if (fetBool) {
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'EnabledState', 2);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'EnabledStateOptions', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'Variant', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'VariantPayload', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'VariantPayloadKind', 0);

              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'EnabledState', 2);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'EnabledStateOptions', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'Variant', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'VariantPayload', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'VariantPayloadKind', 0);
            } else {
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'EnabledState', 1);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'EnabledStateOptions', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'Variant', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'VariantPayload', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1931258509', 'VariantPayloadKind', 0);

              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'EnabledState', 1);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'EnabledStateOptions', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'Variant', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'VariantPayload', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\2733408908', 'VariantPayloadKind', 0);
            }
          },
        ),
      ],
    );
  }
}
