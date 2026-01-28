import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../../core/services/win_registry_service.dart';
import '../../../core/trusted_installer/trusted_installer_service.dart';
import '../../../utils.dart';

part 'utilities_service.g.dart';

abstract class UtilitiesService {
  bool get statusHibernation;
  Future<void> enableHibernation();
  Future<void> disableHibernation();
  bool get statusFastStartup;
  Future<void> enableFastStartup();
  Future<void> disableFastStartup();
  bool get statusTMMonitoring;
  Future<void> enableTMMonitoring();
  Future<void> disableTMMonitoring();

  bool get statusUsageReporting;
  Future<void> enableUsageReporting();
  Future<void> disableUsageReporting();
}

class UtilitiesServiceImpl implements UtilitiesService {
  const UtilitiesServiceImpl();

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
}

@Riverpod(keepAlive: true)
UtilitiesService utilitiesService(Ref ref) {
  return const UtilitiesServiceImpl();
}

@riverpod
bool hibernationStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusHibernation;
}

@riverpod
bool fastStartupStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusFastStartup;
}

@riverpod
bool tmMonitoringStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusTMMonitoring;
}

@riverpod
bool usageReportingStatus(Ref ref) {
  return ref.watch(utilitiesServiceProvider).statusUsageReporting;
}
