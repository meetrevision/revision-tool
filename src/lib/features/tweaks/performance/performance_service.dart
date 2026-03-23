import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../../core/cli_generator/annotations.dart';
import '../../../core/services/win_registry_service.dart';
import '../../../core/trusted_installer/trusted_installer_service.dart';
part 'performance_service.g.dart';

enum ServiceGrouping { forced, recommended, disabled }

const _userSvcSplitDisabled = {'CDPUserSvc_', 'OneSyncSvc_', 'WpnUserService_'};

final _recommendedSplitDisabled = {
  'DisplayEnhancementService',
  'PcaSvc',
  'WdiSystemHost',
  'AudioEndpointBuilder',
  'DeviceAssociationService',
  'NcbService',
  'StorSvc',
  'SysMain',
  'TextInputManagementService',
  'TrkWks',
  'hidserv',

  'Appinfo',
  'BITS',
  'LanmanServer',
  'SENS',
  'Schedule',
  'ShellHWDetection',
  'Themes',
  'TokenBroker',
  'UserManager',
  'UsoSvc',
  'Winmgmt',
  'WpnService',
  'gpsvc',
  'iphlpsvc',
  'wuauserv',

  'WinHttpAutoProxySvc',
  'EventLog',
  'TimeBrokerSvc',
  'lmhosts',
  'Dhcp',

  'FontCache',
  'nsi',
  'netprofm',
  'SstpSvc',
  'DispBrokerDesktopSvc',
  'CDPSvc',
  'EventSystem',
  'LicenseManager',

  'SystemEventsBroker',
  'Power',
  'LSM',
  'DcomLaunch',
  'BrokerInfrastructure',

  'CoreMessagingRegistrar',
  'DPS',
  'NcdAutoSetup',

  'AppXSvc',
  'ClipSVC',

  'camsvc',
  'StateRepository',

  'FDResPub',
  'SSDPSRV',

  'CryptSvc',
  'Dnscache',
  'NlaSvc',
  'LanmanWorkstation',

  'KeyIso',
  'VaultSvc',
  'SamSs',
};

const _defaultSplitDisabled = {
  'BFE',
  'BrokerInfrastructure',
  'DcomLaunch',
  r'DisplayEnhancementService\Parameters',
  'mpssvc',
  'OneSyncSvc',
  'PimIndexMaintenanceSvc',
  'PlugPlay',
  'Power',
  'RasMan',
  'RemoteAccess',
  'RpcEptMapper',
  'RpcSs',
  r'SensorService\Parameters',
  'SystemEventsBroker',
  'UnistoreSvc',
  'UserDataSvc',
};

@CliCommand(name: 'performance', description: 'Performance tweaks')
abstract class PerformanceService {
  @CliToggle(
    name: 'powerplan',
    status: 'statusReviPowerPlan',
    enable: 'enableReviPowerPlan',
    disable: 'disableReviPowerPlan',
  )
  bool get statusReviPowerPlan;
  Future<void> enableReviPowerPlan();
  Future<void> disableReviPowerPlan();

  @CliToggle(
    name: 'powerplan-states-c6',
    status: 'statusReviPowerPlanC6States',
    enable: 'enableReviPowerPlanC6States',
    disable: 'disableReviPowerPlanC6States',
  )
  bool get statusReviPowerPlanC6States;
  Future<void> enableReviPowerPlanC6States();
  Future<void> disableReviPowerPlanC6States();

  @CliToggle(
    name: 'superfetch',
    status: 'statusSuperfetch',
    enable: 'enableSuperfetch',
    disable: 'disableSuperfetch',
  )
  bool get statusSuperfetch;
  Future<void> enableSuperfetch();
  Future<void> disableSuperfetch();

  @CliToggle(
    name: 'memory-compression',
    status: 'statusMemoryCompression',
    enable: 'enableMemoryCompression',
    disable: 'disableMemoryCompression',
  )
  bool get statusMemoryCompression;
  Future<void> enableMemoryCompression();
  Future<void> disableMemoryCompression();

  @CliToggle(
    name: 'intel-tsx',
    status: 'statusIntelTSX',
    enable: 'enableIntelTSX',
    disable: 'disableIntelTSX',
  )
  bool get statusIntelTSX;
  Future<void> enableIntelTSX();
  Future<void> disableIntelTSX();

  @CliToggle(
    name: 'swapchain-fso',
    status: 'statusFullscreenOptimization',
    enable: 'enableFullscreenOptimization',
    disable: 'disableFullscreenOptimization',
  )
  bool get statusFullscreenOptimization;
  Future<void> enableFullscreenOptimization();
  Future<void> disableFullscreenOptimization();

  @CliToggle(
    name: 'swapchain-wo',
    status: 'statusWindowedOptimization',
    enable: 'enableWindowedOptimization',
    disable: 'disableWindowedOptimization',
  )
  bool get statusWindowedOptimization;
  Future<void> enableWindowedOptimization();
  Future<void> disableWindowedOptimization();

  @CliToggle(
    name: 'swapchain-mpo',
    status: 'statusMPO',
    enable: 'enableMPO',
    disable: 'disableMPO',
  )
  bool get statusMPO;
  Future<void> enableMPO();
  Future<void> disableMPO();

  @CliToggle(
    name: 'background-apps',
    status: 'statusBackgroundApps',
    enable: 'enableBackgroundApps',
    disable: 'disableBackgroundApps',
  )
  bool get statusBackgroundApps;
  Future<void> enableBackgroundApps();
  Future<void> disableBackgroundApps();

  @CliToggle(
    name: 'ntfs-last-access',
    status: 'statusLastTimeAccessNTFS',
    enable: 'enableLastTimeAccessNTFS',
    disable: 'disableLastTimeAccessNTFS',
  )
  bool get statusLastTimeAccessNTFS;
  Future<void> enableLastTimeAccessNTFS();
  Future<void> disableLastTimeAccessNTFS();

  @CliToggle(
    name: 'ntfs-8dot3-naming',
    status: 'status8dot3NamingNTFS',
    enable: 'enable8dot3NamingNTFS',
    disable: 'disable8dot3NamingNTFS',
  )
  bool get status8dot3NamingNTFS;
  Future<void> enable8dot3NamingNTFS();
  Future<void> disable8dot3NamingNTFS();

  @CliToggle(
    name: 'ntfs-memory-usage',
    status: 'statusMemoryUsageNTFS',
    enable: 'enableMemoryUsageNTFS',
    disable: 'disableMemoryUsageNTFS',
  )
  bool get statusMemoryUsageNTFS;
  Future<void> enableMemoryUsageNTFS();
  Future<void> disableMemoryUsageNTFS();

  @CliEnumSubCommand(
    name: 'service-grouping',
    values: ServiceGrouping.values,
    status: 'statusServicesGrouping',
    setMethod: 'setServiceGroupingMode',
  )
  ServiceGrouping get statusServicesGrouping;
  Future<void> setServiceGroupingMode(ServiceGrouping target);

  @CliValue(
    name: 'background-window-message-rate-limit',
    status: 'statusBackgroundWindowMessageRateLimit',
    set: 'setBackgroundWindowMessageRateLimit',
  )
  int get statusBackgroundWindowMessageRateLimit;
  Future<void> setBackgroundWindowMessageRateLimit(int milliseconds);
}

class PerformanceServiceImpl implements PerformanceService {
  const PerformanceServiceImpl();

  @override
  bool get statusReviPowerPlan {
    return WinRegistryService.readString(
          .localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6',
          'FriendlyName',
        ) !=
        null;
  }

  /// Revision's custom power plan based on Windows's Ultimate Performance with additional changes.
  ///
  /// Power Scheme GUID change is intentional to match the ReviOS Playbook's UniqueId.
  ///
  /// For more info:
  /// https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/hardware/power/power-performance-tuning#processor-performance-increase-and-decrease-of-thresholds-and-policies
  ///
  @override
  Future<void> enableReviPowerPlan() async {
    const command = r'''
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 6a93ec26-284d-4943-9fc4-c9616def55c6
powercfg -changename 6a93ec26-284d-4943-9fc4-c9616def55c6 "Revision - Ultra Performance" "Windows's Ultimate Performance with additional changes."
powercfg -s 6a93ec26-284d-4943-9fc4-c9616def55c6
powercfg -delete 3ff9831b-6f80-4830-8178-736cd4229e7b
''';

    shell.runExecutableArgumentsSync('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-NoLogo',
      '-Command',
      command,
    ]);

    // **PERFINCPOL**, **PERFDECPOL**, **PERFINCTHRESHOLD**, **PERFDECTHRESHOLD** only take effect on non-HWP systems or when **PERFAUTONOMOUS** is disabled.
    await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
      () async => Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\465e1f50-b610-473a-ab58-00d1077dc418', // Processor power management -> Processor performance increase policy; PERFINCPOL
          'ACSettingIndex',
          2,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\40fbefc7-2e9d-4d25-a185-0cfd8574bac6', // Processor power management -> Processor performance decrease policy; PERFDECPOL
          'ACSettingIndex',
          1,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\06cadf0e-64ed-448a-8927-ce7bf90eb35d', // Processor power management -> Processor performance increase threshold; PERFINCTHRESHOLD
          'ACSettingIndex',
          10,
        ),

        // **CPMINCORES** and **CPMINCORES1** to 100 prevents core parking.
        // When hybrid architecture processsor is present (such as E and P Cores) powerplan GUID parameters suffix ending with 1 is for P Cores else E-Cores, meaning the P cores are parked by default on high performance power plans.
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583', // Processor power management -> Processor performance core parking min cores; CPMINCORES
          'ACSettingIndex',
          100,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584', // Processor power management -> Processor performance core parking min cores for Processor Power Efficiency Class 1; CPMINCORES1
          'ACSettingIndex',
          100,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009', // USB settings -> USB 3 Link Power Mangement
          'ACSettingIndex',
          0,
        ),
      ]),
    );
    await _setActiveSchemeCurrent();
  }

  @override
  Future<void> disableReviPowerPlan() async {
    const command = r'''
powercfg -s 381b4222-f694-41f0-9685-ff5bb260df2e
if ($LASTEXITCODE -ne 0) {
  powercfg -restoreindividualdefaultscheme 381b4222-f694-41f0-9685-ff5bb260df2e
}
powercfg -s 381b4222-f694-41f0-9685-ff5bb260df2e
powercfg -delete 6a93ec26-284d-4943-9fc4-c9616def55c6
''';

    shell.runExecutableArgumentsSync('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-NoLogo',
      '-Command',
      command,
    ]);
  }

  Future<void> _setActiveSchemeCurrent() async {
    await runPSCommand(
      'powercfg /setactive scheme_current',
      loggerInfoOutput: false,
    );
  }

  /// Processor idle promote/demote threshold
  @override
  bool get statusReviPowerPlanC6States {
    final int? idlePromote = WinRegistryService.readInt(
      .localMachine,
      r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c',
      'ACSettingIndex',
    );
    final int? idleDemote = WinRegistryService.readInt(
      .localMachine,
      r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119',
      'ACSettingIndex',
    );

    return idlePromote == 100 && idleDemote == 80;
  }

  @override
  Future<void> enableReviPowerPlanC6States() async {
    if (!statusReviPowerPlan) await enableReviPowerPlan();

    await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
      () async => Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c',
          'ACSettingIndex',
          60,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119',
          'ACSettingIndex',
          40,
        ),
        WinRegistryService.deleteValue(
          // LEGACY approach: https://learn.microsoft.com/en-us/previous-versions/troubleshoot/windows-server/virtual-machines-slow-startup-shutdown
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Processor',
          'Capabilities',
        ),
      ]),
    );
    await _setActiveSchemeCurrent();
  }

  /// Power Saver uses 40/20, Balanced and High Performance powerplans use 60/40, so the Hysteresis gap is 20%. 100/80 maintains this 20% gap. Without the gap, Windows may whipsaw a core between C‑states multiple times per second, increasing latency and possibly causing audio underruns.
  @override
  Future<void> disableReviPowerPlanC6States() async {
    if (!statusReviPowerPlan) await enableReviPowerPlan();

    await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
      () async => Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c',
          'ACSettingIndex',
          100,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\Power\User\PowerSchemes\6a93ec26-284d-4943-9fc4-c9616def55c6\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119',
          'ACSettingIndex',
          80,
        ),
      ]),
    );

    await _setActiveSchemeCurrent();
  }

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
    final List<String>? lowerFilters = WinRegistryService.getStringArrayValue(
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

    final String hardDriveType = (await runPSCommand(
      r'(Get-PhysicalDisk -SerialNumber (Get-Disk -Number (Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1)).DiskNumber).SerialNumber.TrimStart()).MediaType',
    )).stdout.toString().trim();

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
    final List<String>? lowerFilters = WinRegistryService.getStringArrayValue(
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
          'GameDVR_FSEBehaviorMode',
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
    final String? value = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      'DirectXUserGlobalSettings',
    );
    return value == null || !value.contains('SwapEffectUpgradeEnable=0');
  }

  @override
  Future<void> enableWindowedOptimization() async {
    final String? currentValue = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      'DirectXUserGlobalSettings',
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
    final String? currentValue = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Software\Microsoft\DirectX\UserGpuPreferences',
      'DirectXUserGlobalSettings',
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
  bool get statusMPO {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\Dwm',
          'OverlayTestMode',
        ) !=
        5;
  }

  @override
  Future<void> enableMPO() async {
    await WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\Dwm',
      'OverlayTestMode',
    );
  }

  @override
  Future<void> disableMPO() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\Dwm',
      'OverlayTestMode',
      5,
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
  bool get statusLastTimeAccessNTFS {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\FileSystem',
          'RefsDisableLastAccessUpdate',
        ) !=
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
          'NtfsDisable8dot3NameCreation',
        ) !=
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
          'NtfsMemoryUsage',
        ) ==
        2;
  }

  @override
  ServiceGrouping get statusServicesGrouping {
    final int? value = WinRegistryService.readInt(
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
      for (final String service in _userSvcSplitDisabled) {
        final Iterable<String> finalService =
            WinRegistryService.getUserServices(service);
        finalService.forEach(_recommendedSplitDisabled.add);
      }
      return ServiceGrouping.recommended;
    }
    return ServiceGrouping.disabled;
  }

  @override
  Future<void> setServiceGroupingMode(ServiceGrouping mode) {
    return switch (mode) {
      .forced => () async {
        await WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\CurrentControlSet\Control',
          'SvcHostSplitThresholdInKB',
          0xFFFFFFFF,
        );
      }(),
      .recommended => () async {
        await WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\CurrentControlSet\Control',
          'SvcHostSplitThresholdInKB',
          0x380000, // default value
        );
        final Set<String> services = {
          ..._defaultSplitDisabled,
          ..._recommendedSplitDisabled,
        };
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
      }(),
      .disabled => () async {
        final Set<String> servicesToDelete = _recommendedSplitDisabled
            .difference(_defaultSplitDisabled);
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
      }(),
    };
  }

  @override
  int get statusBackgroundWindowMessageRateLimit {
    final rawMouseThrottleEnabled =
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

    final int pollFrequency = (1000 / rawMouseThrottleDuration).round();
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
bool reviPowerPlanStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusReviPowerPlan;
}

@riverpod
bool reviPowerPlanC6StatesStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusReviPowerPlanC6States;
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
bool mpoStatus(Ref ref) {
  return ref.watch(performanceServiceProvider).statusMPO;
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
