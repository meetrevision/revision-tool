import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart';

import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Performance'),
      ),
      children: [
        //  subtitle(content: const Text('A simple ToggleSwitch')),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.speed_high,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Superfetch'),
                      Text(
                        "Speed up your system performance by prefetching frequently used apps. Recommended to only enable it on HDD",
                        // style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 207, 207, 207), overflow: TextOverflow.ellipsis),
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2.0),
              Text(sfBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: sfBool,
                onChanged: (bool value) async {
                  setState(() {
                    sfBool = value;
                  });
                  if (sfBool) {
                    await run('${directoryExe.path}\\NSudoLG.exe -U:T -P:E cmd /min /c "${directoryExe.path}\\EnableSF.bat"');
                    showDialog(
                      context: context,
                      builder: (context) => ContentDialog(
                        content: const Text("You must restart your computer for the changes to take effect"),
                        actions: [
                          Button(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    // await run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
                    writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 0);
                    await run('${directoryExe.path}\\NSudoLG.exe -U:T -P:E cmd /min /c "${directoryExe.path}\\DisableSF.bat"');
                    showDialog(
                      context: context,
                      builder: (context) => ContentDialog(
                        content: const Text("You must restart your computer for the changes to take effect"),
                        actions: [
                          Button(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        //
        const SizedBox(height: 5.0),
        if (sfBool) ...[
          CardHighlight(
            child: Row(
              children: [
                const SizedBox(width: 5.0),
                const Icon(
                  msicons.FluentIcons.ram_20_regular,
                  size: 24,
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoLabel(label: 'Memory Compression'),
                        Text(
                          "Save memory by compressing of unused programs running in background. Has a little impact on CPU",
                          style: FluentTheme.of(context).brightness.isDark
                              ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                              : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(mcBool ? "On" : "Off"),
                const SizedBox(width: 10.0),
                ToggleSwitch(
                  checked: mcBool,
                  onChanged: (bool value) async {
                    setState(() {
                      mcBool = value;
                    });
                    if (mcBool) {
                      await run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Enable-MMAgent -mc"');
                      writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 1);
                    } else {
                      await run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
                      writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 0);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 5.0),
          //
        ],

        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(FluentIcons.t_v_monitor, size: 24),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Fullscreen optimization'),
                      // Text(
                      //   "Save memory by compressing of unused programs running in background. Has a little impact on CPU",
                      //   style: FluentTheme.of(context).brightness.isDark
                      //       ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                      //       : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      // )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(foBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: foBool,
                onChanged: (bool value) async {
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
            ],
          ),
        ),
      ],
    );
  }
}
