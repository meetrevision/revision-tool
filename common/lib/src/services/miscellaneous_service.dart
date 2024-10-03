import 'package:common/src/utils.dart';
import 'package:process_run/shell_run.dart';

import 'package:win32_registry/win32_registry.dart';

import 'win_registry_service.dart';
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
    return WinRegistryService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled') ==
        1;
  }

  Future<void> enableHibernation() async {
    WinRegistryService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        1);
    WinRegistryService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 1);
    await _shell.run(r'''
                     powercfg -h on
                     powercfg /h /type full
                    ''');
  }

  Future<void> disableHibernation() async {
    WinRegistryService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        0);
    WinRegistryService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 0);
    await _shell.run(r'''
powercfg -h off
''');
  }

  // int? get statusHibernationMode {
  //   return WinRegistryService.readInt(RegistryHive.localMachine,
  //       r'System\ControlSet001\Control\Power', 'HiberFileType');
  // }

  // Future<void> setHibernateModeReduced() async {
  //   await _shell.run('powercfg /h /type reduced');
  // }

  // Future<void> setHibernateModeFull() async {
  //   await _shell.run('powercfg /h /type full');
  // }

  bool get statusFastStartup {
    return WinRegistryService.readInt(
            RegistryHive.localMachine,
            r'System\ControlSet001\Control\Session Manager\Power',
            'HiberbootEnabled') ==
        1;
  }

  void enableFastStartup() {
    WinRegistryService.writeDword(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        1);
    WinRegistryService.writeDword(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System', 'HiberbootEnabled', 1);
  }

  void disableFastStartup() {
    WinRegistryService.writeDword(
        Registry.localMachine,
        r'System\ControlSet001\Control\Session Manager\Power',
        'HiberbootEnabled',
        0);
    WinRegistryService.writeDword(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System', 'HiberbootEnabled', 0);
  }

  bool get statusTMMonitoring {
    return WinRegistryService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start') ==
            2 &&
        WinRegistryService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\Ndu', 'Start') ==
            2;
  }

  Future<void> enableTMMonitoring() async {
    WinRegistryService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 2);
    WinRegistryService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 2);
    await _shell.run(r'''
                    sc start GraphicsPerfSvc
                    sc start Ndu
                    ''');
  }

  void disableTMMonitoring() {
    WinRegistryService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 4);
    WinRegistryService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 4);
  }

  bool get statusMPO {
    return WinRegistryService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode') !=
        5;
  }

  void enableMPO() {
    WinRegistryService.deleteValue(Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode');
  }

  void disableMPO() {
    WinRegistryService.writeDword(Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode', 5);
  }

  bool get statusUsageReporting {
    return WinRegistryService.readInt(RegistryHive.localMachine,
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
