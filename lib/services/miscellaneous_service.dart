import 'package:process_run/shell_run.dart';
import 'package:revitool/utils.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';
import 'setup_service.dart';

class MiscellaneousService implements SetupService {
  static final _registryUtilsService = RegistryUtilsService();
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
    return _registryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled') ==
        1;
  }

  Future<void> enableHibernation() async {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        1);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 1);
    await _shell.run(r'''
                     powercfg -h on
                     powercfg /h /type full
                    ''');
  }

  Future<void> disableHibernation() async {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        0);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 0);
    await _shell.run(r'''
                     powercfg -h off
                    ''');
  }

  // int? get statusHibernationMode {
  //   return _registryUtilsService.readInt(RegistryHive.localMachine,
  //       r'System\ControlSet001\Control\Power', 'HiberFileType');
  // }

  // Future<void> setHibernateModeReduced() async {
  //   await _shell.run('powercfg /h /type reduced');
  // }

  // Future<void> setHibernateModeFull() async {
  //   await _shell.run('powercfg /h /type full');
  // }

  bool get statusFastStartup {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'System\ControlSet001\Control\Session Manager\Power',
            'HiberbootEnabled') ==
        1;
  }

  void enableFastStartup() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        1);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System', 'HiberbootEnabled', 1);
  }

  void disableFastStartup() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        0);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System', 'HiberbootEnabled', 0);
  }

  bool get statusTMMonitoring {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start') ==
            2 &&
        _registryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\Ndu', 'Start') ==
            2;
  }

  Future<void> enableTMMonitoring() async {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 2);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 2);
    await _shell.run(r'''
                    sc start GraphicsPerfSvc
                    sc start Ndu
                    ''');
  }

  void disableTMMonitoring() {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 4);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 4);
  }

  bool get statusMPO {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode') !=
        5;
  }

  void enableMPO() {
    _registryUtilsService.deleteValue(Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode');
  }

  void disableMPO() {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode', 5);
  }

  bool get statusUsageReporting {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
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
