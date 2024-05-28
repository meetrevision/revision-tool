import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:revitool/services/network_service.dart';
import 'package:revitool/services/win_package_service.dart';
import 'package:win32_registry/win32_registry.dart';

import '../utils.dart';
import 'registry_utils_service.dart';
import 'setup_service.dart';
import 'package:process_run/shell_run.dart';
import 'package:path/path.dart' as p;

class SecurityService implements SetupService {
  static final _shell = Shell();
  static final _networkService = NetworkService();
  static final _winPackageService = WinPackageService();

  static const _instance = SecurityService._private();

  static final String _mpCmdRunString =
      '${RegistryUtilsService.readString(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows Defender', 'InstallLocation')!}MpCmdRun.exe';

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
    if (_winPackageService
        .checkPackageInstalled(WinPackageType.defenderRemoval)) return false;

    if (RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows Defender', 'DisableAntiSpyware') ==
        1) {
      return false;
    }

    if (RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Services\WinDefend', 'Start') ==
        4) {
      return false;
    }

    return true;
  }

  bool get statusDefenderProtections {
    return statusDefender &&
        (statusDefenderProtectionTamper || statusDefenderProtectionRealtime);
  }

  bool get statusDefenderProtectionTamper {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows Defender\Features',
            'TamperProtection') !=
        4;
  }

  bool get statusDefenderProtectionRealtime {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows Defender\Real-Time Protection',
            'DisableRealtimeMonitoring') !=
        1;
  }

  Future<ProcessResult> openDefenderThreatSettings() async {
    return await Process.run(
      'start',
      ['windowsdefender://threatsettings'],
      runInShell: true,
    );
  }

  Future<void> enableDefender() async {
    try {
      RegistryUtilsService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiSpyware');
      RegistryUtilsService.deleteValue(Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender', 'DisableAntiVirus');
      RegistryUtilsService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection',
          'DisableRealtimeMonitoring');

      RegistryUtilsService.writeDword(Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender', 'DisableAntiSpyware', 0);
      RegistryUtilsService.writeDword(Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender', 'DisableAntiVirus', 0);

      await _winPackageService.uninstallPackage(WinPackageType.defenderRemoval);

      await _shell.run(
          'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force');

      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\System\\ControlSet001\\Services\\MDCoreSvc" /v Start /t REG_DWORD /d 2 /f');

      RegistryUtilsService.writeString(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
          'RevisionEnableDefenderCMD',
          '"$_mpCmdRunString" -WDEnable');
    } on Exception catch (e) {
      throw ('Failed to enable Windows Defender:\n\n$e');
    }
  }

  Future<void> disableDefender() async {
    await _winPackageService.downloadPackage(WinPackageType.defenderRemoval);

    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows Defender',
        'DisableAntiSpyware',
        1);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows Defender', 'DisableAntiVirus', 1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection',
        'DisableRealtimeMonitoring',
        1);

    await _shell.run(
        'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force');

    await _shell.run(
        "PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP -C 'Start-Process -FilePath \"$_mpCmdRunString\" -ArgumentList \"-RemoveDefinitions -All\" -NoNewWindow -Wait'");

    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\SOFTWARE\\Microsoft\\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f');
    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\SOFTWARE\\Microsoft\\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f');

    await _shell.run(
        '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\System\\ControlSet001\\Services\\MDCoreSvc" /v Start /t REG_DWORD /d 4 /f');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'RevisionEnableDefenderCMD');

    await _winPackageService.installPackage(WinPackageType.defenderRemoval);
  }

  bool get statusUAC {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
            'EnableLUA') ==
        1;
  }

  void enableUAC() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        5);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        3);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0);
  }

  void disableUAC() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0);
  }

  bool get statusSpectreMeltdown {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
            'FeatureSettingsOverride') ==
        null;
  }

  void enableSpectreMeltdown() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettings',
        0);
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverride');
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverrideMask');
  }

  void disableSpectreMeltdown() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettings',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverride',
        3);
    RegistryUtilsService.writeDword(
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
