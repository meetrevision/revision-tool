import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import '../utils.dart';
import 'registry_utils_service.dart';
import 'setup_service.dart';

class PerformanceService implements SetupService {
  static final _shell = Shell();

  static const _instance = PerformanceService._private();
  factory PerformanceService() {
    return _instance;
  }
  const PerformanceService._private();

  @override
  void recommendation() {
    // TODO: implement recommendation
    enableIntelTSX();
    enableFullscreenOptimization();
    enableWindowedOptimization();
    disableCStates();
    disableLastTimeAccessNTFS();
    disable8dot3NamingNTFS();
    disableMemoryUsageNTFS();
  }

  bool get statusSuperfetch {
    return !(RegistryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\rdyboost', 'Start') ==
            4 &&
        RegistryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\SysMain', 'Start') ==
            4);
  }

  Future<void> enableSuperfetch() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableSF.bat"');
  }

  Future<void> disableSuperfetch() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableSF.bat"');
  }

  // TODO: Find a batter way to detect Memory Compression
  // isMemoryCompressionEnabled is added by ReviOS, due to complexity of detecting the value without PowerShell
  Future<bool> get statusMemoryCompression async {
    final value = await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoProfile -Command "(Get-MMAgent).MemoryCompression"', );
        return value.outText == 'True';
  }

  Future<void> enableMemoryCompression() async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoProfile -Command "Enable-MMAgent -mc"');
  }

  Future<void> disableMemoryCompression() async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
  }

  bool get statusIntelTSX {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Session Manager\Kernel',
            'DisableTsx') ==
        0;
  }

  void enableIntelTSX() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
        'DisableTsx',
        0);
  }

  void disableIntelTSX() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
        'DisableTsx',
        1);
  }

  bool get statusFullscreenOptimization {
    return RegistryUtilsService.readInt(RegistryHive.currentUser,
            r'System\GameConfigStore', "GameDVR_FSEBehaviorMode") ==
        0;
  }

  void enableFullscreenOptimization() {
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
    RegistryUtilsService.deleteValue(
        Registry.currentUser, r'System\GameConfigStore', 'GameDVR_FSEBehavior');
    RegistryUtilsService.deleteValue(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode');
    RegistryUtilsService.deleteValue(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible');
    RegistryUtilsService.deleteValue(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags');

    RegistryUtilsService.writeDword(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
    RegistryUtilsService.deleteValue(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehavior');
    RegistryUtilsService.deleteValue(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode');
    RegistryUtilsService.deleteValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_DXGIHonorFSEWindowsCompatible');
    RegistryUtilsService.deleteValue(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_EFSEFeatureFlags');
  }

  void disableFullscreenOptimization() {
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);

    // RegistryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
    // RegistryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
    // RegistryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
    // RegistryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
    // RegistryUtilsService.writeDword(
    //     Registry.allUsers, r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);
  }

  bool get statusWindowedOptimization {
    return RegistryUtilsService
            .readString(
                RegistryHive.currentUser,
                r'Software\Microsoft\DirectX\UserGpuPreferences',
                "DirectXUserGlobalSettings")
            ?.contains("SwapEffectUpgradeEnable=1") ??
        false;
  }

  void enableWindowedOptimization() {
    RegistryUtilsService.writeString(
        Registry.currentUser,
        r'Software\Microsoft\DirectX\UserGpuPreferences',
        'DirectXUserGlobalSettings',
        r'SwapEffectUpgradeEnable=1;');
  }

  void disableWindowedOptimization() {
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Microsoft\DirectX\UserGpuPreferences',
        'DirectXUserGlobalSettings');
  }

  bool get statusBackgroundApps {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'Software\Policies\Microsoft\Windows\AppPrivacy',
            'LetAppsRunInBackground') !=
        2;
  }

  void enableBackgroundApps() {
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle');
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle');

    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
        'GlobalUserDisabled');
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\AppPrivacy',
        'LetAppsRunInBackground');
  }

  void disableBackgroundApps() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle',
        0);

    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
        'GlobalUserDisabled',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\AppPrivacy',
        'LetAppsRunInBackground',
        2);
  }

  bool get statusCStates {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities') ==
        516198;
  }

  void enableCStates() {
    RegistryUtilsService.deleteValue(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities');
  }

  void disableCStates() {
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities', 516198);
  }

  bool get statusLastTimeAccessNTFS {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\FileSystem',
            "RefsDisableLastAccessUpdate") ==
        1;
  }

  Future<void> enableLastTimeAccessNTFS() async {
    await _shell.run('fsutil behavior set disableLastAccess 0');
  }

  Future<void> disableLastTimeAccessNTFS() async {
    await _shell.run('fsutil behavior set disableLastAccess 1');
  }

  bool get status8dot3NamingNTFS {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\FileSystem',
            "NtfsDisable8dot3NameCreation") ==
        1;
  }

  Future<void> enable8dot3NamingNTFS() async {
    await _shell.run('fsutil behavior set disable8dot3 2');
  }

  Future<void> disable8dot3NamingNTFS() async {
    await _shell.run('fsutil behavior set disable8dot3 1');
  }

  bool get statusMemoryUsageNTFS {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\FileSystem', "NtfsMemoryUsage") ==
        2;
  }

  Future<void> enableMemoryUsageNTFS() async {
    await _shell.run('fsutil behavior set memoryusage 2');
  }

  Future<void> disableMemoryUsageNTFS() async {
    await _shell.run('fsutil behavior set memoryusage 1');
  }
}
