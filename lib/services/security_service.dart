import 'package:win32_registry/win32_registry.dart';

import '../utils.dart';
import 'registry_utils_service.dart';
import 'setup_service.dart';
import 'package:process_run/shell_run.dart';

class SecurityService implements SetupService {
  static final _registryUtilsService = RegistryUtilsService();
  static final Shell _shell = Shell();

  static const _instance = SecurityService._private();
  factory SecurityService() {
    return _instance;
  }
  const SecurityService._private();

  @override
  void recommendation() {
    enableDefender();
    enableUAC();
    enableSpectreMeltdown();
    updateCertificates();
  }

  bool get statusDefender {
    return (_registryUtilsService.readInt(RegistryHive.localMachine,
                r'SYSTEM\ControlSet001\Services\WinDefend', 'Start') ??
            4) <=
        3;
  }

  bool get statusTamperProtection {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows Defender\Features',
            'TamperProtection') ==
        5;
  }

  Future<void> enableDefender() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableWD.bat"');
  }

  Future<void> disableDefender() async {
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableWD.bat"');
  }

  bool get statusUAC {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
            'EnableLUA') ==
        1;
  }

  void enableUAC() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        5);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        3);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0);
  }

  void disableUAC() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0);
  }

  bool get statusSpectreMeltdown {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
            'FeatureSettingsOverride') ==
        0;
  }

  void enableSpectreMeltdown() {
    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettings');
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverride',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverrideMask',
        3);
  }

  void disableSpectreMeltdown() {
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettings',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverride',
        3);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverrideMask',
        3);
  }

  Future<void> updateCertificates() async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoP -C "& {\$tmp = (New-TemporaryFile).FullName; CertUtil -generateSSTFromWU -f \$tmp; if ( (Get-Item \$tmp | Measure-Object -Property Length -Sum).sum -gt 0 ) { \$SST_File = Get-ChildItem -Path \$tmp; \$SST_File | Import-Certificate -CertStoreLocation "Cert:\\LocalMachine\\Root"; \$SST_File | Import-Certificate -CertStoreLocation "Cert:\\LocalMachine\\AuthRoot" } Remove-Item -Path \$tmp}"');
  }
}
