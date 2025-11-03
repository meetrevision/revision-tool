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
  Future<void> enableIntelTSX();
  Future<void> disableIntelTSX();
  Future<void> enableFullscreenOptimization();
  Future<void> disableFullscreenOptimization();
  Future<void> enableWindowedOptimization();
  Future<void> disableWindowedOptimization();
  Future<void> enableBackgroundApps();
  Future<void> disableBackgroundApps();
  Future<void> enableCStates();
  Future<void> disableCStates();
  Future<void> enableLastTimeAccessNTFS();
  Future<void> disableLastTimeAccessNTFS();
  Future<void> enable8dot3NamingNTFS();
  Future<void> disable8dot3NamingNTFS();
  Future<void> enableMemoryUsageNTFS();
  Future<void> disableMemoryUsageNTFS();
  Future<void> forcedServicesGrouping();
  Future<void> recommendedServicesGrouping();
  Future<void> disableServicesGrouping();
  Future<void> setBackgroundWindowMessageRateLimit(int milliseconds);
}

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
    final lowerFilters = WinRegistryService.getStringArrayValue(
      RegistryHive.localMachine,
      r'SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}',
      'LowerFilters',
    );
    if (lowerFilters != null &&
        !lowerFilters.any((e) => e.toLowerCase() == 'rdyboost')) {
      lowerFilters.add('rdyboost');
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}',
        'LowerFilters',
        lowerFilters,
      );
    }

    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\rdyboost',
        'Start',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\SysMain',
        'Start',
        2,
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'EnableSuperfetch',
      ),
    ]);

    final hardDriveType = await runPSCommand(
      '(Get-PhysicalDisk -SerialNumber (Get-Disk -Number (Get-Partition -DriveLetter \$env:SystemDrive.Substring(0, 1)).DiskNumber).SerialNumber.TrimStart()).MediaType',
    );
    if (hardDriveType == 'HDD') {
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'EnableSuperfetch',
        3,
      );
    }

    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'EnablePrefetcher',
        3,
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt',
        'GroupPolicyDisallowCaches',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt',
        'AllowNewCachesByDefault',
      ),
    ]);
  }

  @override
  Future<void> disableSuperfetch() async {
    final lowerFilters = WinRegistryService.getStringArrayValue(
      RegistryHive.localMachine,
      r'SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}',
      'LowerFilters',
    );
    lowerFilters!.removeWhere((e) => e.toLowerCase() == 'rdyboost');
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}',
      'LowerFilters',
      lowerFilters,
    );

    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\SysMain',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\rdyboost',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'EnablePrefetcher',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters',
        'EnableSuperfetch',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt',
        'GroupPolicyDisallowCaches',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt',
        'AllowNewCachesByDefault',
        0,
      ),
    ]);
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
  Future<void> enableIntelTSX() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel',
      'DisableTsx',
      0,
    );
  }

  @override
  Future<void> disableIntelTSX() async {
    await WinRegistryService.writeRegistryValue(
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
  Future<void> enableFullscreenOptimization() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_FSEBehaviorMode',
        0,
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_FSEBehavior',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_HonorUserFSEBehaviorMode',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_DXGIHonorFSEWindowsCompatible',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_EFSEFeatureFlags',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_FSEBehaviorMode',
        0,
      ),
      WinRegistryService.deleteValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_FSEBehavior',
      ),
      WinRegistryService.deleteValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_HonorUserFSEBehaviorMode',
      ),
      WinRegistryService.deleteValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_DXGIHonorFSEWindowsCompatible',
      ),
      WinRegistryService.deleteValue(
        Registry.allUsers,
        r'.DEFAULT\System\GameConfigStore',
        'GameDVR_EFSEFeatureFlags',
      ),
    ]);
  }

  @override
  Future<void> disableFullscreenOptimization() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_FSEBehaviorMode',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_HonorUserFSEBehaviorMode',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_DXGIHonorFSEWindowsCompatible',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_EFSEFeatureFlags',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'System\GameConfigStore',
        'GameDVR_FSEBehavior',
        2,
      ),
    ]);
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
  Future<void> enableWindowedOptimization() async {
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

    await WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      'DirectXUserGlobalSettings',
      newValue,
    );
  }

  @override
  Future<void> disableWindowedOptimization() async {
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

    await WinRegistryService.writeRegistryValue(
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
  Future<void> enableBackgroundApps() async {
    await Future.wait([
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
        'GlobalUserDisabled',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\AppPrivacy',
        'LetAppsRunInBackground',
      ),
    ]);
  }

  @override
  Future<void> disableBackgroundApps() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\Search',
        'BackgroundAppGlobalToggle',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications',
        'GlobalUserDisabled',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\AppPrivacy',
        'LetAppsRunInBackground',
        2,
      ),
    ]);
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
  Future<void> enableCStates() async {
    await WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\Processor',
      'Capabilities',
    );
  }

  @override
  Future<void> disableCStates() async {
    await WinRegistryService.writeRegistryValue(
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
  Future<void> forcedServicesGrouping() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control',
      'SvcHostSplitThresholdInKB',
      0xFFFFFFFF,
    );
  }

  @override
  Future<void> recommendedServicesGrouping() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control',
      'SvcHostSplitThresholdInKB',
      0x380000, // default value
    );
    final services = {..._defaultSplitDisabled, ..._recommendedSplitDisabled};
    await Future.wait(
      services.map(
        (service) => WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Services\' + service,
          'SvcHostSplitDisable',
          1,
        ),
      ),
    );
  }

  @override
  Future<void> disableServicesGrouping() async {
    final servicesToDelete = _recommendedSplitDisabled.difference(
      _defaultSplitDisabled,
    );
    await Future.wait([
      ...servicesToDelete.map(
        (service) => WinRegistryService.deleteValue(
          Registry.localMachine,
          'SYSTEM\\ControlSet001\\Services\\$service',
          'SvcHostSplitDisable',
        ),
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control',
        'SvcHostSplitThresholdInKB',
        0x380000,
      ),
    ]);
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
  Future<void> setBackgroundWindowMessageRateLimit(int value) async {
    if (!_rmtdValidator(value)) {
      throw ArgumentError('DWORD value must be between 3 and 20');
    }

    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Control Panel\Mouse',
        'RawMouseThrottleEnabled',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Control Panel\Mouse',
        'RawMouseThrottleDuration',
        value,
      ),
    ]);
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
