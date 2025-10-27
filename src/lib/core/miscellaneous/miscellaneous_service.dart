import 'package:revitool/core/miscellaneous/kgl_dto.dart';
import 'package:revitool/core/performance/performance_service.dart';
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
  void enableFastStartup();
  void disableFastStartup();
  bool get statusTMMonitoring;
  Future<void> enableTMMonitoring();
  void disableTMMonitoring();
  bool get statusMPO;
  void enableMPO();
  void disableMPO();
  bool get statusUsageReporting;
  Future<void> enableUsageReporting();
  Future<void> disableUsageReporting();
  Future<void> updateKGL();
}

/// Implementation of MiscellaneousService
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
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\System',
      'ShowHibernateOption',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\Power',
      'HibernateEnabled',
      1,
    );
    await shell.run(r'''
                     powercfg -h on
                     powercfg /h /type full
                    ''');
  }

  @override
  Future<void> disableHibernation() async {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\System',
      'ShowHibernateOption',
      0,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\Power',
      'HibernateEnabled',
      0,
    );
    await shell.run(r'''
powercfg -h off
''');
  }

  // int? get statusHibernationMode {
  //   return WinRegistryService.readInt(RegistryHive.localMachine,
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
  void enableFastStartup() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'System\ControlSet001\Control\Session Manager\Power',
      'HiberbootEnabled',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\System',
      'HiberbootEnabled',
      1,
    );
  }

  @override
  void disableFastStartup() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'System\ControlSet001\Control\Session Manager\Power',
      'HiberbootEnabled',
      0,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\System',
      'HiberbootEnabled',
      0,
    );
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
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
      'Start',
      2,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Services\Ndu',
      'Start',
      2,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Services\DPS',
      'Start',
      2,
    );
  }

  @override
  void disableTMMonitoring() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc',
      'Start',
      4,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Services\Ndu',
      'Start',
      4,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Services\DPS',
      'Start',
      4,
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
  void enableMPO() {
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\Dwm',
      'OverlayTestMode',
    );
  }

  @override
  void disableMPO() {
    WinRegistryService.writeRegistryValue(
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
    await shell.run(
      '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableUR.bat"',
    );
  }

  @override
  Future<void> disableUsageReporting() async {
    await shell.run(
      '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableUR.bat"',
    );
  }

  @override
  Future<void> updateKGL() async {
    const api =
        'https://settings.data.microsoft.com/settings/v3.0/xbox/knowngamelist';
    try {
      final networkService = NetworkService();
      final json = await networkService.get(api);
      final kgl = KGLModel.fromJson(json.data['settings']);

      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\GameDVR',
        'KGLRevision',
        kgl.version,
      );
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\GameDVR',
        'KGLToGCSUpdatedRevision',
        kgl.version,
      );

      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'ActivateOnUpdate',
        kgl.activateOnUpdate,
      );
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'Hash',
        kgl.hash,
      );
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'URI',
        kgl.uri,
      );
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\KGL\OneSettings',
        'Version',
        kgl.version,
      );
      WinRegistryService.writeRegistryValue(
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

// Riverpod Providers
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
