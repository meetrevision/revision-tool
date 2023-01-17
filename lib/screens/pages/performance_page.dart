import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
// import 'package:flutter/material.dart';

import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:revitool/widgets/subtitle.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:process_run/shell_run.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  bool sfBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Services\rdyboost', 'Start') == 4 &&
          readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Services\SysMain', 'Start') == 4
      ? false
      : true;
  bool mcBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled') != 0;
  bool foBool = readRegistryInt(RegistryHive.currentUser, r'System\GameConfigStore', "GameDVR_FSEBehaviorMode") != 2;

//NTFS
  bool ntfsLTABool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Control\FileSystem', "RefsDisableLastAccessUpdate") != 1;
  bool ntfsEdTBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Control\FileSystem', "NtfsDisable8dot3NameCreation") != 1;
  bool ntfsMUBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Control\FileSystem', "NtfsMemoryUsage") == 2;

  String? powerPlan = readRegistryString(RegistryHive.localMachine, r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes', 'ActivePowerScheme');

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
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pagePerformance),
      ),
      children: [
        CardHighlightSwitch(
          icon: FluentIcons.speed_high,
          label: ReviLocalizations.of(context).perfSuperfetchLabel,
          description: ReviLocalizations.of(context).perfSuperfetchDescription,
          switchBool: sfBool,
          function: (value) async {
            setState(() {
              sfBool = value;
            });
            if (sfBool) {
              await run('"$directoryExe\\NSudoLG.exe" -U:T -P:E cmd /min /c "$directoryExe\\EnableSF.bat"');
            } else {
              writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 0);
              await run('"$directoryExe\\NSudoLG.exe" -U:T -P:E cmd /min /c "$directoryExe\\DisableSF.bat"');
            }
            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                content: Text(ReviLocalizations.of(context).restartDialog),
                actions: [
                  Button(
                    child: Text(ReviLocalizations.of(context).okButton),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        if (sfBool) ...[
          const SizedBox(height: 5.0),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.ram_20_regular,
            label: ReviLocalizations.of(context).perfMCLabel,
            description: ReviLocalizations.of(context).perfMCDescription,
            switchBool: mcBool,
            function: (value) {
              setState(() {
                mcBool = value;
              });
              if (mcBool) {
                run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Enable-MMAgent -mc"');
                writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 1);
              } else {
                run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
                writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 0);
              }
            },
          ),
        ],
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.t_v_monitor,
          label: ReviLocalizations.of(context).perfFOLabel,
          description: ReviLocalizations.of(context).perfFODescription,
          switchBool: foBool,
          function: (value) async {
            setState(() {
              foBool = value;
            });
            if (foBool) {
              writeRegistryDword(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_FSEBehavior');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore', 'Win32_AutoGameModeDefaultProfile');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore', 'Win32_GameModeRelatedProcesses');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags');

              writeRegistryDword(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
              deleteRegistry(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehavior');
              deleteRegistry(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'Win32_AutoGameModeDefaultProfile');
              deleteRegistry(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'Win32_GameModeRelatedProcesses');
              deleteRegistry(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode');
              deleteRegistry(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible');
              deleteRegistry(Registry.allUsers, r'.DEFAULT\System\GameConfigStore', 'GameDVR_EFSEFeatureFlags');
            } else {
              writeRegistryDword(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
              writeRegistryDword(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
              writeRegistryDword(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
              writeRegistryDword(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
              writeRegistryDword(Registry.currentUser, r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);

              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);
              await Shell().run(r'''
                      reg add "HKCU\System\GameConfigStore" /v "Win32_AutoGameModeDefaultProfile" /t REG_BINARY /d "01000100000000000000000000000000000000000000000000000000000000000000000000000000" /f
                      reg add "HKCU\System\GameConfigStore" /v "Win32_GameModeRelatedProcesses" /t REG_BINARY /d "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" /f
                      reg add "HKU\.DEFAULT\System\GameConfigStore" /v "Win32_AutoGameModeDefaultProfile" /t REG_BINARY /d "01000100000000000000000000000000000000000000000000000000000000000000000000000000" /f
                      reg add "HKU\.DEFAULT\System\GameConfigStore" /v "Win32_GameModeRelatedProcesses" /t REG_BINARY /d "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" /f
                    ''');
            }
          },
        ),
        if (expBool) ...[
          subtitle(content: Text(ReviLocalizations.of(context).perfSectionFS)),
          const SizedBox(height: 5.0),
          CardHighlightSwitch(
            icon: FluentIcons.time_entry,
            label: ReviLocalizations.of(context).perfLTALabel,
            description: ReviLocalizations.of(context).perfLTADescription,
            switchBool: ntfsLTABool,
            function: (value) async {
              setState(() {
                ntfsLTABool = value;
              });
              if (ntfsLTABool) {
                run('fsutil behavior set disableLastAccess 0');
              } else {
                run('fsutil behavior set disableLastAccess 1');
              }
            },
          ),
          const SizedBox(height: 5.0),
          CardHighlightSwitch(
            icon: FluentIcons.file_system,
            label: ReviLocalizations.of(context).perfEdTLabel,
            description: ReviLocalizations.of(context).perfEdTDescription,
            switchBool: ntfsEdTBool,
            function: (value) {
              setState(() {
                ntfsEdTBool = value;
              });
              if (ntfsEdTBool) {
                run('fsutil behavior set disable8dot3 0');
              } else {
                run('fsutil behavior set disable8dot3 1');
              }
            },
          ),
          const SizedBox(height: 5.0),
          CardHighlightSwitch(
            icon: FluentIcons.hard_drive_unlock,
            label: ReviLocalizations.of(context).perfMULabel,
            switchBool: ntfsMUBool,
            function: (value) async {
              setState(() {
                ntfsMUBool = value;
              });
              if (ntfsMUBool) {
                run('fsutil behavior set memoryusage 2');
              } else {
                run('fsutil behavior set memoryusage 1');
              }
            },
            expandTitle: "More information",
            codeSnippet: ReviLocalizations.of(context).perfMUDescription,
          ),
        ]
      ],
    );
  }
}
