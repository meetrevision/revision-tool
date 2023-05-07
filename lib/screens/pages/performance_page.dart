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
  bool _sfBool = (readRegistryInt(RegistryHive.localMachine,
                  r'SYSTEM\ControlSet001\Services\rdyboost', 'Start') ==
              4 &&
          readRegistryInt(RegistryHive.localMachine,
                  r'SYSTEM\ControlSet001\Services\SysMain', 'Start') ==
              4)
      ? false
      : true;

  bool _mcBool = readRegistryInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
          'isMemoryCompressionEnabled') ==
      1;

  bool _foBool = readRegistryInt(RegistryHive.currentUser,
          r'System\GameConfigStore', "GameDVR_FSEBehaviorMode") ==
      0;

  bool _iTSXBool = readRegistryInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Session Manager\Kernel',
          'DisableTsx') ==
      0;

// Experimental

  bool _owgBool = readRegistryString(
              RegistryHive.currentUser,
              r'Software\Microsoft\DirectX\UserGpuPreferences',
              "DirectXUserGlobalSettings")
          ?.contains("SwapEffectUpgradeEnable=1") ??
      false;

  bool _cStatesBool = readRegistryInt(RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities') ==
      516198;

//NTFS
  bool _ntfsLTABool = readRegistryInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem',
          "RefsDisableLastAccessUpdate") ==
      1;
  bool _ntfsEdTBool = readRegistryInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem',
          "NtfsDisable8dot3NameCreation") ==
      1;
  bool _ntfsMUBool = readRegistryInt(RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem', "NtfsMemoryUsage") ==
      2;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pagePerformance),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.top_speed_20_regular,
          label: ReviLocalizations.of(context).perfSuperfetchLabel,
          description: ReviLocalizations.of(context).perfSuperfetchDescription,
          switchBool: _sfBool,
          function: (value) async {
            setState(() {
              _sfBool = value;
            });
            if (_sfBool) {
              await run(
                  '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableSF.bat"');
            } else {
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
                  'isMemoryCompressionEnabled',
                  0);
              await run(
                  '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableSF.bat"');
            }
            // ignore: use_build_context_synchronously
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
        if (_sfBool) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.ram_20_regular,
            label: ReviLocalizations.of(context).perfMCLabel,
            description: ReviLocalizations.of(context).perfMCDescription,
            switchBool: _mcBool,
            function: (value) {
              setState(() {
                _mcBool = value;
              });
              if (_mcBool) {
                run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Enable-MMAgent -mc"');
                writeRegistryDword(
                    Registry.localMachine,
                    r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
                    'isMemoryCompressionEnabled',
                    1);
              } else {
                run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
                writeRegistryDword(
                    Registry.localMachine,
                    r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
                    'isMemoryCompressionEnabled',
                    0);
              }
            },
          ),
        ],
        CardHighlightSwitch(
          icon: msicons.FluentIcons.transmission_20_regular,
          label: ReviLocalizations.of(context).perfITSXLabel,
          description: ReviLocalizations.of(context).perfITSXDescription,
          switchBool: _iTSXBool,
          function: (value) async {
            setState(() {
              _iTSXBool = value;
            });
            if (_iTSXBool) {
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
                  'DisableTsx',
                  0);
            } else {
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
                  'DisableTsx',
                  1);
            }
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.desktop_20_regular,
          label: ReviLocalizations.of(context).perfFOLabel,
          description: ReviLocalizations.of(context).perfFODescription,
          switchBool: _foBool,
          function: (value) async {
            setState(() {
              _foBool = value;
            });
            if (_foBool) {
              writeRegistryDword(Registry.currentUser,
                  r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore',
                  'GameDVR_FSEBehavior');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore',
                  'GameDVR_HonorUserFSEBehaviorMode');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore',
                  'GameDVR_DXGIHonorFSEWindowsCompatible');
              deleteRegistry(Registry.currentUser, r'System\GameConfigStore',
                  'GameDVR_EFSEFeatureFlags');

              writeRegistryDword(
                  Registry.allUsers,
                  r'.DEFAULT\System\GameConfigStore',
                  'GameDVR_FSEBehaviorMode',
                  0);
              deleteRegistry(Registry.allUsers,
                  r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehavior');
              deleteRegistry(
                  Registry.allUsers,
                  r'.DEFAULT\System\GameConfigStore',
                  'GameDVR_HonorUserFSEBehaviorMode');
              deleteRegistry(
                  Registry.allUsers,
                  r'.DEFAULT\System\GameConfigStore',
                  'GameDVR_DXGIHonorFSEWindowsCompatible');
              deleteRegistry(
                  Registry.allUsers,
                  r'.DEFAULT\System\GameConfigStore',
                  'GameDVR_EFSEFeatureFlags');
            } else {
              writeRegistryDword(Registry.currentUser,
                  r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
              writeRegistryDword(
                  Registry.currentUser,
                  r'System\GameConfigStore',
                  'GameDVR_HonorUserFSEBehaviorMode',
                  1);
              writeRegistryDword(
                  Registry.currentUser,
                  r'System\GameConfigStore',
                  'GameDVR_DXGIHonorFSEWindowsCompatible',
                  1);
              writeRegistryDword(Registry.currentUser,
                  r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
              writeRegistryDword(Registry.currentUser,
                  r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);

              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore',
                  'GameDVR_FSEBehaviorMode', 2);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore',
                  'GameDVR_HonorUserFSEBehaviorMode', 1);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore',
                  'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore',
                  'GameDVR_EFSEFeatureFlags', 0);
              writeRegistryDword(Registry.allUsers, r'System\GameConfigStore',
                  'GameDVR_FSEBehavior', 2);
            }
          },
        ),
        if (w11) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.desktop_mac_20_regular,
            label: ReviLocalizations.of(context).perfOWGLabel,
            description: ReviLocalizations.of(context).perfOWGDescription,
            switchBool: _owgBool,
            function: (value) {
              setState(() {
                _owgBool = value;
              });
              if (_owgBool) {
                writeRegistryString(
                    Registry.currentUser,
                    r'Software\Microsoft\DirectX\UserGpuPreferences',
                    'DirectXUserGlobalSettings',
                    r'SwapEffectUpgradeEnable=1;');
              } else {
                deleteRegistry(
                    Registry.currentUser,
                    r'Software\Microsoft\DirectX\UserGpuPreferences',
                    'DirectXUserGlobalSettings');
              }
            },
          ),
        ],
        if (expBool) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.sleep_20_regular,
            label: ReviLocalizations.of(context).perfCStatesLabel,
            description: ReviLocalizations.of(context).perfCStatesDescription,
            switchBool: _cStatesBool,
            function: (value) async {
              setState(() {
                _cStatesBool = value;
              });
              if (_cStatesBool) {
                writeRegistryDword(
                    Registry.localMachine,
                    r'SYSTEM\ControlSet001\Control\Processor',
                    'Capabilities',
                    516198);
              } else {
                deleteRegistry(Registry.localMachine,
                    r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities');
              }
            },
          ),
          subtitle(content: Text(ReviLocalizations.of(context).perfSectionFS)),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
            label: ReviLocalizations.of(context).perfLTALabel,
            description: ReviLocalizations.of(context).perfLTADescription,
            switchBool: _ntfsLTABool,
            function: (value) async {
              setState(() {
                _ntfsLTABool = value;
              });
              if (_ntfsLTABool) {
                run('fsutil behavior set disableLastAccess 1');
              } else {
                run('fsutil behavior set disableLastAccess 0');
              }
            },
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.hard_drive_20_regular,
            label: ReviLocalizations.of(context).perfEdTLabel,
            description: ReviLocalizations.of(context).perfEdTDescription,
            switchBool: _ntfsEdTBool,
            function: (value) {
              setState(() {
                _ntfsEdTBool = value;
              });
              if (_ntfsEdTBool) {
                run('fsutil behavior set disable8dot3 1');
              } else {
                run('fsutil behavior set disable8dot3 0');
              }
            },
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.memory_16_regular,
            label: ReviLocalizations.of(context).perfMULabel,
            switchBool: _ntfsMUBool,
            function: (value) async {
              setState(() {
                _ntfsMUBool = value;
              });
              if (_ntfsMUBool) {
                run('fsutil behavior set memoryusage 2');
              } else {
                run('fsutil behavior set memoryusage 1');
              }
            },
            codeSnippet: ReviLocalizations.of(context).perfMUDescription,
          ),
        ]
      ],
    );
  }
}
