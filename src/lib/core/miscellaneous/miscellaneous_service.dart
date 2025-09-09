import 'package:revitool/core/miscellaneous/kgl_dto.dart';
import 'package:revitool/core/performance/performance_service.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/network_service.dart';

import 'package:win32_registry/win32_registry.dart';

part 'miscellaneous_service.g.dart';

abstract final class MiscellaneousService {
  static final _networkService = NetworkService();

  static bool get statusHibernation {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Power',
          'HibernateEnabled',
        ) ==
        1;
  }

  static Future<void> enableHibernation() async {
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

  static Future<void> disableHibernation() async {
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

  static bool get statusFastStartup {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'System\ControlSet001\Control\Session Manager\Power',
          'HiberbootEnabled',
        ) ==
        1;
  }

  static void enableFastStartup() {
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

  static void disableFastStartup() {
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

  static bool get statusTMMonitoring {
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

  static Future<void> enableTMMonitoring() async {
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

  static void disableTMMonitoring() {
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

  static bool get statusMPO {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\Dwm',
          'OverlayTestMode',
        ) !=
        5;
  }

  static void enableMPO() {
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\Dwm',
      'OverlayTestMode',
    );
  }

  static void disableMPO() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\Dwm',
      'OverlayTestMode',
      5,
    );
  }

  static bool get statusUsageReporting {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Services\DPS',
          'Start',
        ) !=
        4;
  }

  static Future<void> enableUsageReporting() async {
    await shell.run(
      '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableUR.bat"',
    );
  }

  static Future<void> disableUsageReporting() async {
    await shell.run(
      '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableUR.bat"',
    );
  }

  static Future<void> updateKGL() async {
    const api =
        'https://settings.data.microsoft.com/settings/v3.0/xbox/knowngamelist';
    try {
      final json = await _networkService.get(api);
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

      PerformanceService.enableBackgroundApps();
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

// Riverpod Providers
@riverpod
bool hibernationStatus(Ref ref) {
  return MiscellaneousService.statusHibernation;
}

@riverpod
bool fastStartupStatus(Ref ref) {
  return MiscellaneousService.statusFastStartup;
}

@riverpod
bool tmMonitoringStatus(Ref ref) {
  return MiscellaneousService.statusTMMonitoring;
}

@riverpod
bool mpoStatus(Ref ref) {
  return MiscellaneousService.statusMPO;
}

@riverpod
bool usageReportingStatus(Ref ref) {
  return MiscellaneousService.statusUsageReporting;
}
