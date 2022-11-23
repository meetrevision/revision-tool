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
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Usability - Windows 11'),
      ),
      children: [
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.context_menu,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'A new context menu'),
                      // const Text(
                      //   "",
                      //   style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 207, 207, 207)),
                      // )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(mrcBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: mrcBool,
                onChanged: (bool value) async {
                  setState(() {
                    mrcBool = value;
                  });
                  if (mrcBool) {
                    Shell().run(r'''
                            reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f
	                          reg add "HKLM\Software\Classes\CLSID" /v "IsModernRCEnabled" /t REG_DWORD /d "0" /f
                        ''');
                    // createRegistryKey(Registry.currentUser, r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32');
                    // writeRegistryDword(Registry.localMachine, r'Software\Classes\CLSID', 'IsModernRCEnabled', 1);
                    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
                    await Process.run('explorer.exe', [], runInShell: true);
                  } else {
                    // deleteRegistryKey(Registry.currentUser, r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32');
                    // writeRegistryDword(Registry.localMachine, r'Software\Classes\CLSID', 'IsModernRCEnabled', 0);
                    Shell().run(r'''
                            reg add "HKLM\Software\Classes\CLSID" /v "IsModernRCEnabled" /t REG_DWORD /d "1" /f
                            reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
                        ''');
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
                FluentIcons.explore_content,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'File Explorer Tabs'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(fetBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: fetBool,
                onChanged: (bool value) {
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
          ),
        ),
      ],
    );
  }
}
