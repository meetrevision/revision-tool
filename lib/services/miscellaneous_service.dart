import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';
import 'setup_service.dart';

class MiscellaneousService implements SetupService {
  static final MiscellaneousService _instance = MiscellaneousService._private();

  final RegistryUtilsService _registryUtilsService = RegistryUtilsService();

  factory MiscellaneousService() {
    return _instance;
  }

  MiscellaneousService._private();

  @override
  void recommendation() {
    disableHibernation();
    disableTMMonitoring();
    disableBatteryHealthReporting();
  }

  bool get statusHibernation {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled') ==
        1;
  }

  void enableHibernation() async {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        1);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 1);
    await Shell().run(r'''
                     powercfg -h on
                     powercfg /h /type full
                    ''');
  }

  void disableHibernation() async {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\System',
        'ShowHibernateOption',
        0);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 0);
    await Shell().run(r'''
                     powercfg -h off
                    ''');
  }

  int? get statusHibernationMode {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
        r'System\ControlSet001\Control\Power', 'HiberFileType');
  }

  void setHibernateModeReduced() async {
    await run('powercfg /h /type reduced');
  }

  void setHibernateModeFull() async {
    await run('powercfg /h /type full');
  }

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

  void enableTMMonitoring() async {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 2);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 2);
    await Shell().run(r'''
                    sc start GraphicsPerfSvc
                    sc start Ndu
                    ''');
  }

  void disableTMMonitoring() async {
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

  bool get statusBatteryHealthReporting {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Services\DPS', 'Start') !=
        4;
  }

  void enableBatteryHealthReporting() async {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS', 'Start', 2);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\diagsvc', 'Start', 2);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiServiceHost', 'Start', 2);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiSystemHost', 'Start', 2);
    await Shell().run(r'''
                     wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:true >NUL
                     wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:true >NUL
                     wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:true >NUL
                    ''');
  }

  void disableBatteryHealthReporting() async {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\DPS', 'Start', 4);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\diagsvc', 'Start', 4);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiServiceHost', 'Start', 4);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SYSTEM\ControlSet001\Services\WdiSystemHost', 'Start', 4);
    await Shell().run(r'''
                     wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:false >NUL
                     wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:false >NUL
                     wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:false >NUL
                    ''');
  }
}
