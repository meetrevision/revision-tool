import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import '../utils.dart';
import 'registry_utils_service.dart';
import 'setup_service.dart';

class PerformanceService implements SetupService {
  static final _registryUtilsService = RegistryUtilsService();
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
    return !(_registryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\rdyboost', 'Start') ==
            4 &&
        _registryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\SysMain', 'Start') ==
            4);
  }

  Future<void> enableSuperfetch() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableSF.bat"');
  }

  Future<void> disableSuperfetch() async {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'isMemoryCompressionEnabled',
        0);
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableSF.bat"');
  }

  // TODO: Find a batter way to detect Memory Compression
  // isMemoryCompressionEnabled is added by ReviOS, due to complexity of detecting the value without PowerShell
  bool get statusMemoryCompression {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
            'isMemoryCompressionEnabled') ==
        1;
  }

  Future<void> enableMemoryCompression() async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoProfile -Command "Enable-MMAgent -mc"');
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'isMemoryCompressionEnabled',
        1);
  }

  Future<void> disableMemoryCompression() async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc"');
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'isMemoryCompressionEnabled',
        0);
  }

  bool get statusIntelTSX {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Session Manager\Kernel',
            'DisableTsx') ==
        0;
  }

  void enableIntelTSX() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
        'DisableTsx',
        0);
  }

  void disableIntelTSX() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
        'DisableTsx',
        1);
  }

  bool get statusFullscreenOptimization {
    return _registryUtilsService.readInt(RegistryHive.currentUser,
            r'System\GameConfigStore', "GameDVR_FSEBehaviorMode") ==
        0;
  }

  void enableFullscreenOptimization() {
    _registryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
    _registryUtilsService.deleteValue(
        Registry.currentUser, r'System\GameConfigStore', 'GameDVR_FSEBehavior');
    _registryUtilsService.deleteValue(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode');
    _registryUtilsService.deleteValue(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible');
    _registryUtilsService.deleteValue(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags');

    _registryUtilsService.writeDword(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 0);
    _registryUtilsService.deleteValue(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_FSEBehavior');
    _registryUtilsService.deleteValue(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode');
    _registryUtilsService.deleteValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_DXGIHonorFSEWindowsCompatible');
    _registryUtilsService.deleteValue(Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore', 'GameDVR_EFSEFeatureFlags');
  }

  void disableFullscreenOptimization() {
    _registryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
    _registryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
    _registryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
    _registryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
    _registryUtilsService.writeDword(Registry.currentUser,
        r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);

    // _registryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
    // _registryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
    // _registryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
    // _registryUtilsService.writeDword(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
    // _registryUtilsService.writeDword(
    //     Registry.allUsers, r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);
  }

  bool get statusWindowedOptimization {
    return _registryUtilsService
            .readString(
                RegistryHive.currentUser,
                r'Software\Microsoft\DirectX\UserGpuPreferences',
                "DirectXUserGlobalSettings")
            ?.contains("SwapEffectUpgradeEnable=1") ??
        false;
  }

  void enableWindowedOptimization() {
    _registryUtilsService.writeString(
        Registry.currentUser,
        r'Software\Microsoft\DirectX\UserGpuPreferences',
        'DirectXUserGlobalSettings',
        r'SwapEffectUpgradeEnable=1;');
  }

  void disableWindowedOptimization() {
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Microsoft\DirectX\UserGpuPreferences',
        'DirectXUserGlobalSettings');
  }

  bool get statusBackgroundApps {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'Software\Policies\Microsoft\Windows\AppPrivacy',
            'LetAppsRunInBackground') !=
        2;
  }

  void enableBackgroundApps() {
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle');
    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle');

    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
        'GlobalUserDisabled');
    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\AppPrivacy',
        'LetAppsRunInBackground');
  }

  void disableBackgroundApps() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle',
        0);

    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
        'GlobalUserDisabled',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\AppPrivacy',
        'LetAppsRunInBackground',
        2);
  }

  bool get statusCStates {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities') ==
        516198;
  }

  void enableCStates() {
    _registryUtilsService.deleteValue(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities');
  }

  void disableCStates() {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Processor', 'Capabilities', 516198);
  }

  bool get statusLastTimeAccessNTFS {
    return _registryUtilsService.readInt(
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
    return _registryUtilsService.readInt(
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
    return _registryUtilsService.readInt(RegistryHive.localMachine,
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
