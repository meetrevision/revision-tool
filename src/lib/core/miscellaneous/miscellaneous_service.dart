import 'package:revitool/core/miscellaneous/kgl_dto.dart';
import 'package:revitool/core/performance/performance_service.dart';
import 'package:revitool/shared/trusted_installer/trusted_installer_service.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/network_service.dart';

import 'package:win32_registry/win32_registry.dart';

part 'miscellaneous_service.g.dart';

abstract class MiscellaneousService {
  bool get statusHibernation;
  Future<void> enableHibernation();
  Future<void> disableHibernation();
  bool get statusFastStartup;
  Future<void> enableFastStartup();
  Future<void> disableFastStartup();
  bool get statusTMMonitoring;
  Future<void> enableTMMonitoring();
  Future<void> disableTMMonitoring();
  bool get statusMPO;
  Future<void> enableMPO();
  Future<void> disableMPO();
  bool get statusUsageReporting;
  Future<void> enableUsageReporting();
  Future<void> disableUsageReporting();
  Future<void> updateKGL();
}

class MiscellaneousServiceImpl implements MiscellaneousService {
  const MiscellaneousServiceImpl();

  @override
  bool get statusHibernation {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Power',
          'HibernateEnabled',
        ) ==
        1;
  }

  @override
  Future<void> enableHibernation() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power',
        'HibernateEnabled',
        1,
      ),
      shell.run(r'''
                       powercfg -h on
                       powercfg /h /type full
                      '''),
    ]);
  }

  @override
  Future<void> disableHibernation() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power',
        'HibernateEnabled',
        0,
      ),
      shell.run(r'''
powercfg -h off
'''),
    ]);
  }

  // int? get statusHibernationMode {
  //   return await WinRegistryService.readInt(RegistryHive.localMachine,
  //       r'System\ControlSet001\Control\Power', 'HiberFileType');
  // }

  // Future<void> setHibernateModeReduced() async {
  //   await shell.run('powercfg /h /type reduced');
  // }

  // Future<void> setHibernateModeFull() async {
  //   await shell.run('powercfg /h /type full');
  // }

  @override
  bool get statusFastStartup {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'System\ControlSet001\Control\Session Manager\Power',
          'HiberbootEnabled',
        ) ==
        1;
  }

  @override
  Future<void> enableFastStartup() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'HiberbootEnabled',
        1,
      ),
    ]);
  }

  @override
  Future<void> disableFastStartup() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'HiberbootEnabled',
        0,
      ),
    ]);
  }

  @override
  bool get statusTMMonitoring {
    return WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
              'Start',
            ) ==
            2 &&
        WinRegistryService.readInt(
              RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\Ndu',
              'Start',
            ) ==
            2;
  }

  @override
  Future<void> enableTMMonitoring() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        2,
      ),
    ]);
  }

  @override
  Future<void> disableTMMonitoring() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        4,
      ),
    ]);
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
  bool get statusUsageReporting {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Services\DPS',
          'Start',
        ) !=
        4;
  }

  @override
  Future<void> enableUsageReporting() async {
    await Future.wait([
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-SleepStudy/Diagnostic',
        '/q:true',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-Kernel-Processor-Power/Diagnostic',
        '/q:true',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-UserModePowerService/Diagnostic',
        '/q:true',
      ]),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Power',
        'SleepStudyDisabled',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\diagsvc',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiServiceHost',
        'Start',
        2,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiSystemHost',
        'Start',
        2,
      ),
    ]);
  }

  @override
  Future<void> disableUsageReporting() async {
    await Future.wait([
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-SleepStudy/Diagnostic',
        '/q:false',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-Kernel-Processor-Power/Diagnostic',
        '/q:false',
      ]),
      TrustedInstallerServiceImpl().executeCommand('wevtutil', [
        'sl',
        'Microsoft-Windows-UserModePowerService/Diagnostic',
        '/q:false',
      ]),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Session Manager\Power',
        'SleepStudyDisabled',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\diagsvc',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiServiceHost',
        'Start',
        4,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiSystemHost',
        'Start',
        4,
      ),
    ]);
  }

  @override
  Future<void> updateKGL() async {
    const api =
        'https://settings.data.microsoft.com/settings/v3.0/xbox/knowngamelist';
    try {
      final networkService = NetworkService();
      final json = await networkService.get(api);
      final kgl = KGLModel.fromJson(json.data['settings']);

      await WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\GameDVR',
        'KGLRevision',
        kgl.version,
      );
      await WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\GameDVR',
        'KGLToGCSUpdatedRevision',
        kgl.version,
      );

      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'ActivateOnUpdate',
        kgl.activateOnUpdate,
      );
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'Hash',
        kgl.hash,
      );
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'URI',
        kgl.uri,
      );
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'Version',
        kgl.version,
      );
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'VersionCheckTimeout',
        kgl.versionCheckTimeout,
      );

      const PerformanceServiceImpl().enableBackgroundApps();
    } catch (e) {
      logger.e(
        'Failed to update KGL.',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
MiscellaneousService miscellaneousService(Ref ref) {
  return const MiscellaneousServiceImpl();
}

@riverpod
bool hibernationStatus(Ref ref) {
  return ref.watch(miscellaneousServiceProvider).statusHibernation;
}

@riverpod
bool fastStartupStatus(Ref ref) {
  return ref.watch(miscellaneousServiceProvider).statusFastStartup;
}

@riverpod
bool tmMonitoringStatus(Ref ref) {
  return ref.watch(miscellaneousServiceProvider).statusTMMonitoring;
}

@riverpod
bool mpoStatus(Ref ref) {
  return ref.watch(miscellaneousServiceProvider).statusMPO;
}

@riverpod
bool usageReportingStatus(Ref ref) {
  return ref.watch(miscellaneousServiceProvider).statusUsageReporting;
}
