import 'package:process_run/shell_run.dart';
import 'package:revitool/utils.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';
import 'setup_service.dart';

class MiscellaneousService implements SetupService {
  static final _shell = Shell();

  static const _instance = MiscellaneousService._private();
  factory MiscellaneousService() {
    return _instance;
  }
  const MiscellaneousService._private();

  @override
  void recommendation() {
    disableHibernation();
    disableTMMonitoring();
    disableUsageReporting();
  }

  bool get statusHibernation {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled') ==
        1;
  }

  Future<void> enableHibernation() async {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        1);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 1);
    await _shell.run(r'''
                     powercfg -h on
                     powercfg /h /type full
                    ''');
  }

  Future<void> disableHibernation() async {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        0);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 0);
    await _shell.run(r'''
                     powercfg -h off
                    ''');
  }

  // int? get statusHibernationMode {
  //   return RegistryUtilsService.readInt(RegistryHive.localMachine,
  //       r'System\ControlSet001\Control\Power', 'HiberFileType');
  // }

  // Future<void> setHibernateModeReduced() async {
  //   await _shell.run('powercfg /h /type reduced');
  // }

  // Future<void> setHibernateModeFull() async {
  //   await _shell.run('powercfg /h /type full');
  // }

  bool get statusFastStartup {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'System\ControlSet001\Control\Session Manager\Power',
            'HiberbootEnabled') ==
        1;
  }

  void enableFastStartup() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        1);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System', 'HiberbootEnabled', 1);
  }

  void disableFastStartup() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        0);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System', 'HiberbootEnabled', 0);
  }

  bool get statusTMMonitoring {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start') ==
            2 &&
        RegistryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\Ndu', 'Start') ==
            2;
  }

  Future<void> enableTMMonitoring() async {
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 2);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 2);
    await _shell.run(r'''
                    sc start GraphicsPerfSvc
                    sc start Ndu
                    ''');
  }

  void disableTMMonitoring() {
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 4);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 4);
  }

  bool get statusMPO {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode') !=
        5;
  }

  void enableMPO() {
    RegistryUtilsService.deleteValue(Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode');
  }

  void disableMPO() {
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode', 5);
  }

  bool get statusUsageReporting {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Services\DPS', 'Start') !=
        4;
  }

  Future<void> enableUsageReporting() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableUR.bat"');
  }

  Future<void> disableUsageReporting() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableUR.bat"');
  }
}
