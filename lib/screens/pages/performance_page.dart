import 'package:fluent_ui/fluent_ui.dart';
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

  String powerPlan = readRegistryString(RegistryHive.localMachine, r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes', 'ActivePowerScheme');

  @override
  Widget build(BuildContext context) {
    
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Performance'),
      ),
      children: [
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
                    run('"$directoryExe\\NSudoLG.exe" -U:T -P:E cmd /min /c "$directoryExe\\EnableSF.bat"');
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
                    writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 0);
                    run('"$directoryExe\\NSudoLG.exe" -U:T -P:E cmd /min /c "$directoryExe\\DisableSF.bat"');
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
                          "Save memory by compressing unused programs running in the background. Has a small impact on CPU Usage",
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
                      run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Enable-MMAgent -mc"');
                      writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters', 'isMemoryCompressionEnabled', 1);
                    } else {
                      run('PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
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
                      Text(
                        "Fullscreen Optimizations may lead to better gaming and app performance when they are running in fullscreen mode",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
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

        if (expBool) ...[
          const SizedBox(height: 5.0),
          CardHighlight(
            child: Row(
              children: [
                const SizedBox(width: 5.0),
                const Icon(
                  FluentIcons.lightbulb,
                  size: 24,
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoLabel(label: 'Power Mode'),
                        Text(
                          "Customized powerplans to improve system latency",
                          style: FluentTheme.of(context).brightness.isDark
                              ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                              : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                        )
                      ],
                    ),
                  ),
                ),
                ComboBox(
                  value: powerPlan,
                  items: [
                    ComboBoxItem(
                      value: "3ff9831b-6f80-4830-8178-736cd4229e7b",
                      child: Text("Ultra Performance"),
                      onTap: () => setState(() {
                        powerPlan = "3ff9831b-6f80-4830-8178-736cd4229e7b";
                      }),
                    ),
                    ComboBoxItem(
                      value: "e19c287e-faa8-494f-adf0-d8ed5ee4eef1",
                      child: Text("Ultimate Performance"),
                      onTap: () => setState(() {
                        powerPlan = "e19c287e-faa8-494f-adf0-d8ed5ee4eef1";
                      }),
                    ),
                  ],
                  onChanged: (value) {
                    if (powerPlan == "3ff9831b-6f80-4830-8178-736cd4229e7b") {
                      run('"powercfg /S 3ff9831b-6f80-4830-8178-736cd4229e7b"');
                    } else {
                      run('"powercfg /S e19c287e-faa8-494f-adf0-d8ed5ee4eef1"');
                    }
                  /* Error 0x80070005: Access is denied.
                    if (powerPlan == "3ff9831b-6f80-4830-8178-736cd4229e7b") {
                      writeRegistryString(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes', 'ActivePowerScheme', "3ff9831b-6f80-4830-8178-736cd4229e7b");
                    } else {
                      writeRegistryString(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes', 'ActivePowerScheme', "e19c287e-faa8-494f-adf0-d8ed5ee4eef1");
                    }
                  */
                  },
                ),
              ],
            ),
          ),
          subtitle(content: const Text("Filesystem")),
          const SizedBox(height: 5.0),
          CardHighlight(
            child: Row(
              children: [
                const SizedBox(width: 5.0),
                const Icon(FluentIcons.time_entry, size: 24),
                const SizedBox(width: 15.0),
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoLabel(label: 'Last Access Time'),
                        Text(
                          "Disabling Last Time Access improves the speed of file and directory access, reduces disk I/O load and latency",
                          style: FluentTheme.of(context).brightness.isDark
                              ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                              : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(ntfsLTABool ? "On" : "Off"),
                const SizedBox(width: 10.0),
                ToggleSwitch(
                  checked: ntfsLTABool,
                  onChanged: (bool value) async {
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
              ],
            ),
          ),
          const SizedBox(height: 5.0),
          CardHighlight(
            child: Row(
              children: [
                const SizedBox(width: 5.0),
                const Icon(FluentIcons.file_system, size: 24),
                const SizedBox(width: 15.0),
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoLabel(label: '8.3 Naming'),
                        Text(
                          "Disabling 8.3 names improves speed and security",
                          style: FluentTheme.of(context).brightness.isDark
                              ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                              : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(ntfsEdTBool ? "On" : "Off"),
                const SizedBox(width: 10.0),
                ToggleSwitch(
                  checked: ntfsEdTBool,
                  onChanged: (bool value) async {
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
              ],
            ),
          ),
          const SizedBox(height: 5.0),
          CardHighlight(
            expandTitle: "More information",
            codeSnippet:
                "Increasing the physical memory doesn't always increase the amount of paged pool memory available to NTFS. Setting memoryusage to 2 raises the limit of paged pool memory. This might improve performance if your system is opening and closing many files in the same fileset and is not already using large amounts of system memory for other apps or for cache memory. If your computer is already using large amounts of system memory for other apps or for cache memory, increasing the limit of NTFS paged and non-paged pool memory reduces the available pool memory for other processes. This might reduce overall system performance.\n\nDefault is Off",
            child: Row(
              children: [
                const SizedBox(width: 5.0),
                const Icon(FluentIcons.hard_drive_unlock, size: 24),
                const SizedBox(width: 15.0),
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoLabel(label: 'Increase the limit of paged pool memory to NTFS'),
                        // Text(
                        //   "improve performance if your system is opening and closing many files in the same file set and is not already using large amounts of system memory for other apps or for cache memory",
                        //   style: FluentTheme.of(context).brightness.isDark
                        //       ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                        //       : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                        // )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(ntfsMUBool ? "On" : "Off"),
                const SizedBox(width: 10.0),
                ToggleSwitch(
                  checked: ntfsMUBool,
                  onChanged: (bool value) async {
                    setState(() {
                      ntfsMUBool = value;
                    });

                    if (ntfsMUBool) {
                      run('fsutil behavior set memoryusage 2');
                    } else {
                      run('fsutil behavior set memoryusage 1');
                    }
                  },
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }
}
