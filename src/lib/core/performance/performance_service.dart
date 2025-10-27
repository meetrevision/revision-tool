import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

part 'performance_service.g.dart';

enum ServiceGrouping { forced, recommended, disabled }

const _userSvcSplitDisabled = {"CDPUserSvc_", "OneSyncSvc_", "WpnUserService_"};

final _recommendedSplitDisabled = {
  "DisplayEnhancementService",
  "PcaSvc",
  "WdiSystemHost",
  "AudioEndpointBuilder",
  "DeviceAssociationService",
  "NcbService",
  "StorSvc",
  "SysMain",
  "TextInputManagementService",
  "TrkWks",
  "hidserv",

  "Appinfo",
  "BITS",
  "LanmanServer",
  "SENS",
  "Schedule",
  "ShellHWDetection",
  "Themes",
  "TokenBroker",
  "UserManager",
  "UsoSvc",
  "Winmgmt",
  "WpnService",
  "gpsvc",
  "iphlpsvc",
  "wuauserv",

  "WinHttpAutoProxySvc",
  "EventLog",
  "TimeBrokerSvc",
  "lmhosts",
  "Dhcp",

  "FontCache",
  "nsi",
  "SstpSvc",
  "DispBrokerDesktopSvc",
  "CDPSvc",
  "EventSystem",
  "LicenseManager",

  "SystemEventsBroker",
  "Power",
  "LSM",
  "DcomLaunch",
  "BrokerInfrastructure",

  "CoreMessagingRegistrar",
  "DPS",

  "AppXSvc",
  "ClipSVC",
};

const _defaultSplitDisabled = {
  "BFE",
  "BrokerInfrastructure",
  "DcomLaunch",
  "DisplayEnhancementService\\Parameters",
  "mpssvc",
  "OneSyncSvc",
  "PimIndexMaintenanceSvc",
  "PlugPlay",
  "Power",
  "RasMan",
  "RemoteAccess",
  "RpcEptMapper",
  "RpcSs",
  "SensorService\\Parameters",
  "SystemEventsBroker",
  "UnistoreSvc",
  "UserDataSvc",
};

// Abstract interface for testing
abstract class PerformanceService {
  bool get statusSuperfetch;
  bool get statusMemoryCompression;
  bool get statusIntelTSX;
  bool get statusFullscreenOptimization;
  bool get statusWindowedOptimization;
  bool get statusBackgroundApps;
  bool get statusCStates;
  bool get statusLastTimeAccessNTFS;
  bool get status8dot3NamingNTFS;
  bool get statusMemoryUsageNTFS;
  ServiceGrouping get statusServicesGrouping;
  int get statusBackgroundWindowMessageRateLimit;

  Future<void> enableSuperfetch();
  Future<void> disableSuperfetch();
  Future<void> enableMemoryCompression();
  Future<void> disableMemoryCompression();
  void enableIntelTSX();
  void disableIntelTSX();
  void enableFullscreenOptimization();
  void disableFullscreenOptimization();
  void enableWindowedOptimization();
  void disableWindowedOptimization();
  void enableBackgroundApps();
  void disableBackgroundApps();
  void enableCStates();
  void disableCStates();
  Future<void> enableLastTimeAccessNTFS();
  Future<void> disableLastTimeAccessNTFS();
  Future<void> enable8dot3NamingNTFS();
  Future<void> disable8dot3NamingNTFS();
  Future<void> enableMemoryUsageNTFS();
  Future<void> disableMemoryUsageNTFS();
  void forcedServicesGrouping();
  void recommendedServicesGrouping();
  void disableServicesGrouping();
  void setBackgroundWindowMessageRateLimit(int milliseconds);
}

// Implementation
class PerformanceServiceImpl implements PerformanceService {
  const PerformanceServiceImpl();

  @override
  bool get statusSuperfetch {
    return !(WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\rdyboost',
              'Start',
            ) ==
            4 &&
        WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\SysMain',
              'Start',
            ) ==
            4);
  }

  @override
  Future<void> enableSuperfetch() async {
    await shell.run(
      '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableSF.bat"',
    );
  }

  @override
  Future<void> disableSuperfetch() async {
    await shell.run(
      '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableSF.bat"',
    );
  }

  @override
  bool get statusMemoryCompression {
    return isProcessRunning('Memory Compression');
  }

  @override
  Future<void> enableMemoryCompression() async {
    await runPSCommand('Enable-MMAgent -mc');
  }

  @override
  Future<void> disableMemoryCompression() async {
    await runPSCommand('Disable-MMAgent -mc');
  }

  @override
  bool get statusIntelTSX {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Session Manager\Kernel',
          'DisableTsx',
        ) ==
        0;
  }

  @override
  void enableIntelTSX() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
      'DisableTsx',
      0,
    );
  }

  @override
  void disableIntelTSX() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
      'DisableTsx',
      1,
    );
  }

  @override
  bool get statusFullscreenOptimization {
    return WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'System\GameConfigStore',
          "GameDVR_FSEBehaviorMode",
        ) ==
        0;
  }

  @override
  void enableFullscreenOptimization() {
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_FSEBehaviorMode',
      0,
    );
    WinRegistryService.deleteValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_FSEBehavior',
    );
    WinRegistryService.deleteValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_HonorUserFSEBehaviorMode',
    );
    WinRegistryService.deleteValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_DXGIHonorFSEWindowsCompatible',
    );
    WinRegistryService.deleteValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_EFSEFeatureFlags',
    );

    WinRegistryService.writeRegistryValue(
      Registry.allUsers,
      r'.DEFAULT\System\GameConfigStore',
      'GameDVR_FSEBehaviorMode',
      0,
    );
    WinRegistryService.deleteValue(
      Registry.allUsers,
      r'.DEFAULT\System\GameConfigStore',
      'GameDVR_FSEBehavior',
    );
    WinRegistryService.deleteValue(
      Registry.allUsers,
      r'.DEFAULT\System\GameConfigStore',
      'GameDVR_HonorUserFSEBehaviorMode',
    );
    WinRegistryService.deleteValue(
      Registry.allUsers,
      r'.DEFAULT\System\GameConfigStore',
      'GameDVR_DXGIHonorFSEWindowsCompatible',
    );
    WinRegistryService.deleteValue(
      Registry.allUsers,
      r'.DEFAULT\System\GameConfigStore',
      'GameDVR_EFSEFeatureFlags',
    );
  }

  @override
  void disableFullscreenOptimization() {
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_FSEBehaviorMode',
      2,
    );
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_HonorUserFSEBehaviorMode',
      1,
    );
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_DXGIHonorFSEWindowsCompatible',
      1,
    );
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_EFSEFeatureFlags',
      0,
    );
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'System\GameConfigStore',
      'GameDVR_FSEBehavior',
      2,
    );

    // WinRegistryService.writeRegistryValue(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_FSEBehaviorMode', 2);
    // WinRegistryService.writeRegistryValue(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_HonorUserFSEBehaviorMode', 1);
    // WinRegistryService.writeRegistryValue(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_DXGIHonorFSEWindowsCompatible', 1);
    // WinRegistryService.writeRegistryValue(Registry.allUsers,
    //     r'System\GameConfigStore', 'GameDVR_EFSEFeatureFlags', 0);
    // WinRegistryService.writeRegistryValue(
    //     Registry.allUsers, r'System\GameConfigStore', 'GameDVR_FSEBehavior', 2);
  }

  @override
  bool get statusWindowedOptimization {
    final value = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      "DirectXUserGlobalSettings",
    );
    return value == null || !value.contains('SwapEffectUpgradeEnable=0');
  }

  @override
  void enableWindowedOptimization() {
    final currentValue = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      "DirectXUserGlobalSettings",
    );

    final String newValue;
    if (currentValue == null || currentValue.isEmpty) {
      newValue = 'SwapEffectUpgradeEnable=1;';
    } else {
      newValue =
          'SwapEffectUpgradeEnable=1;${currentValue.replaceAll('SwapEffectUpgradeEnable=0;', '').replaceAll('SwapEffectUpgradeEnable=0', '')}';
    }

    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      'DirectXUserGlobalSettings',
      newValue,
    );
  }

  @override
  void disableWindowedOptimization() {
    final currentValue = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      "DirectXUserGlobalSettings",
    );

    final String newValue;
    if (currentValue == null || currentValue.isEmpty) {
      newValue = 'SwapEffectUpgradeEnable=0;';
    } else {
      newValue =
          'SwapEffectUpgradeEnable=0;${currentValue.replaceAll('SwapEffectUpgradeEnable=1;', '').replaceAll('SwapEffectUpgradeEnable=1', '')}';
    }

    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      'DirectXUserGlobalSettings',
      newValue,
    );
  }

  @override
  bool get statusBackgroundApps {
    return WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'Software\Policies\Microsoft\Windows\AppPrivacy',
              'LetAppsRunInBackground',
            ) !=
            2 &&
        WinRegistryService.readInt(
              RegistryHive.currentUser,
              r'Software\Microsoft\Windows\CurrentVersion\Search',
              'BackgroundAppGlobalToggle',
            ) !=
            0 &&
        WinRegistryService.readInt(
              RegistryHive.currentUser,
              r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
              'GlobalUserDisabled',
            ) !=
            1;
  }

  @override
  void enableBackgroundApps() {
    WinRegistryService.deleteValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\Windows\CurrentVersion\Search',
      'BackgroundAppGlobalToggle',
    );
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'Software\Microsoft\Windows\CurrentVersion\Search',
      'BackgroundAppGlobalToggle',
    );

    WinRegistryService.deleteValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
      'GlobalUserDisabled',
    );
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\AppPrivacy',
      'LetAppsRunInBackground',
    );
  }

  @override
  void disableBackgroundApps() {
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\Windows\CurrentVersion\Search',
      'BackgroundAppGlobalToggle',
      0,
    );

    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
      'GlobalUserDisabled',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\AppPrivacy',
      'LetAppsRunInBackground',
      2,
    );
  }

  @override
  bool get statusCStates {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Processor',
          'Capabilities',
        ) ==
        516198;
  }

  @override
  void enableCStates() {
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\Processor',
      'Capabilities',
    );
  }

  @override
  void disableCStates() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\Processor',
      'Capabilities',
      516198,
    );
  }

  @override
  bool get statusLastTimeAccessNTFS {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem',
          "RefsDisableLastAccessUpdate",
        ) ==
        1;
  }

  @override
  Future<void> enableLastTimeAccessNTFS() async {
    await shell.run('fsutil behavior set disableLastAccess 0');
  }

  @override
  Future<void> disableLastTimeAccessNTFS() async {
    await shell.run('fsutil behavior set disableLastAccess 1');
  }

  @override
  bool get status8dot3NamingNTFS {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem',
          "NtfsDisable8dot3NameCreation",
        ) ==
        1;
  }

  @override
  Future<void> enable8dot3NamingNTFS() async {
    await shell.run('fsutil behavior set disable8dot3 2');
  }

  @override
  Future<void> disable8dot3NamingNTFS() async {
    await shell.run('fsutil behavior set disable8dot3 1');
  }

  @override
  bool get statusMemoryUsageNTFS {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem',
          "NtfsMemoryUsage",
        ) ==
        2;
  }

  @override
  ServiceGrouping get statusServicesGrouping {
    final value = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SYSTEM\ControlSet001\Control',
      'SvcHostSplitThresholdInKB',
    );

    if (value == 0xFFFFFFFF) {
      return ServiceGrouping.forced;
    } else if (WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Services\AudioEndpointBuilder',
          'SvcHostSplitDisable',
        ) ==
        1) {
      for (final service in _userSvcSplitDisabled) {
        final finalService = WinRegistryService.getUserServices(service);
        for (final userService in finalService) {
          _recommendedSplitDisabled.add(userService);
        }
      }
      return ServiceGrouping.recommended;
    }
    return ServiceGrouping.disabled;
  }

  @override
  void forcedServicesGrouping() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control',
      'SvcHostSplitThresholdInKB',
      0xFFFFFFFF,
    );
  }

  @override
  void recommendedServicesGrouping() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control',
      'SvcHostSplitThresholdInKB',
      0x380000, // default value
    );
    for (final service in {
      ..._defaultSplitDisabled,
      ..._recommendedSplitDisabled,
    }) {
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\' + service,
        'SvcHostSplitDisable',
        1,
      );
    }
  }

  @override
  void disableServicesGrouping() {
    final servicesToDelete = _recommendedSplitDisabled.difference(
      _defaultSplitDisabled,
    );
    for (final service in servicesToDelete) {
      WinRegistryService.deleteValue(
        Registry.localMachine,
        'SYSTEM\\ControlSet001\\Services\\$service',
        'SvcHostSplitDisable',
      );
    }
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control',
      'SvcHostSplitThresholdInKB',
      0x380000, // default value
    );
  }

  @override
  int get statusBackgroundWindowMessageRateLimit {
    final bool rawMouseThrottleEnabled =
        WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Control Panel\Mouse',
          'RawMouseThrottleEnabled',
        ) !=
        0;

    if (!rawMouseThrottleEnabled) {
      return -1;
    }

    final int rawMouseThrottleDuration =
        WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Control Panel\Mouse',
          'RawMouseThrottleDuration',
        ) ??
        8;

    if (!_rmtdValidator(rawMouseThrottleDuration)) {
      return -1;
    }

    final pollFrequency = (1000 / rawMouseThrottleDuration).round();
    return pollFrequency;
  }

  bool _rmtdValidator(int value) {
    if (value < 3 || value > 20) {
      throw ArgumentError('Value must be between 3 and 20 (inclusive).');
    }
    return true;
  }

  /// For more info: https://github.com/valleyofdoom/PC-Tuning?tab=readme-ov-file#window-message-rate
  @override
  void setBackgroundWindowMessageRateLimit(int value) {
    if (!_rmtdValidator(value)) {
      throw ArgumentError('DWORD value must be between 3 and 20');
    }

    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Control Panel\Mouse',
      'RawMouseThrottleEnabled',
      1,
    );

    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Control Panel\Mouse',
      'RawMouseThrottleDuration',
      value,
    );
  }

  @override
  Future<void> enableMemoryUsageNTFS() async {
    await shell.run('fsutil behavior set memoryusage 2');
  }

  @override
  Future<void> disableMemoryUsageNTFS() async {
    await shell.run('fsutil behavior set memoryusage 1');
  }
}

// Provider for PerformanceService instance
@Riverpod(keepAlive: true)
PerformanceService performanceService(Ref ref) {
  return const PerformanceServiceImpl();
}

@riverpod
bool superfetchStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusSuperfetch;
}

@riverpod
bool memoryCompressionStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusMemoryCompression;
}

@riverpod
bool intelTSXStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusIntelTSX;
}

@riverpod
bool fullscreenOptimizationStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusFullscreenOptimization;
}

@riverpod
bool windowedOptimizationStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusWindowedOptimization;
}

@riverpod
bool backgroundAppsStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusBackgroundApps;
}

@riverpod
ServiceGrouping servicesGroupingStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusServicesGrouping;
}

@riverpod
int backgroundWindowMessageRateLimitStatus(Ref ref) {
  return ref
      .watch(performanceServiceProvider)
      .statusBackgroundWindowMessageRateLimit;
}

@riverpod
bool cStatesStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusCStates;
}

@riverpod
bool lastTimeAccessNTFSStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusLastTimeAccessNTFS;
}

@riverpod
bool dot3NamingNTFSStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).status8dot3NamingNTFS;
}

@riverpod
bool memoryUsageNTFSStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusMemoryUsageNTFS;
}
