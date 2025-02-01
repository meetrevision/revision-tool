import 'dart:io';

import 'package:common/src/services/win_package_service.dart';
import 'package:win32_registry/win32_registry.dart';

import '../utils.dart';
import 'win_registry_service.dart';
import 'setup_service.dart';
import 'package:process_run/shell.dart';

enum Mitigation {
  meltdownSpectre,
  downfall,
}

extension MitigationBits on Mitigation {
  int get bitmask {
    switch (this) {
      case Mitigation.meltdownSpectre:
        return 0x00000003;
      case Mitigation.downfall:
        return 0x02000000;
    }
  }
}

class SecurityService implements SetupService {
  static final _shell = Shell();
  static final _winPackageService = WinPackageService();

  static const _instance = SecurityService._private();

  static final String _mpCmdRunString =
      '${WinRegistryService.readString(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows Defender', 'InstallLocation')!}MpCmdRun.exe';

  factory SecurityService() {
    return _instance;
  }
  const SecurityService._private();

  @override
  void recommendation() {
    enableDefender();
    enableUAC();
    updateCertificates();
  }

  bool get statusDefender {
    if (_winPackageService
        .checkPackageInstalled(WinPackageType.defenderRemoval)) {
      return false;
    }

    if (WinRegistryService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows Defender', 'DisableAntiSpyware') ==
        1) {
      return false;
    }

    if (WinRegistryService.readInt(RegistryHive.localMachine,
            r'SYSTEM\ControlSet001\Services\WinDefend', 'Start') ==
        4) {
      return false;
    }

    return true;
  }

  bool get statusDefenderProtections {
    return (statusDefenderProtectionTamper ||
            statusDefenderProtectionRealtime) &&
        statusDefender;
  }

  bool get statusDefenderProtectionTamper {
    final tp = WinRegistryService.readInt(RegistryHive.localMachine,
        r'SOFTWARE\Microsoft\Windows Defender\Features', 'TamperProtection');
    final tpSource = WinRegistryService.readInt(
        RegistryHive.localMachine,
        r'SOFTWARE\Microsoft\Windows Defender\Features',
        'TamperProtectionSource');

    if (tp == 0 && tpSource == null) {
      return false;
    }

    return tp != 4;
  }

  bool get statusDefenderProtectionRealtime {
    return WinRegistryService.readInt(
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
      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiSpyware');
      WinRegistryService.deleteValue(Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender', 'DisableAntiVirus');
      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection',
          'DisableRealtimeMonitoring');

      // WinRegistryService.writeRegistryValue(Registry.localMachine,
      //     r'SOFTWARE\Microsoft\Windows Defender', 'DisableAntiSpyware', 0);
      // WinRegistryService.writeRegistryValue(Registry.localMachine,
      //     r'SOFTWARE\Microsoft\Windows Defender', 'DisableAntiVirus', 0);

      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg delete "HKLM\\SOFTWARE\\Microsoft\\Windows Defender" /v DisableAntiSpyware /f');
      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg delete "HKLM\\SOFTWARE\\Microsoft\\Windows Defender" /v DisableAntiVirus /f');

      await _winPackageService.uninstallPackage(WinPackageType.defenderRemoval);

      await _shell.run(
          'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force');

      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\System\\ControlSet001\\Services\\MDCoreSvc" /v Start /t REG_DWORD /d 2 /f');

      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
          'RevisionEnableDefenderCMD',
          '"$_mpCmdRunString" -WDEnable');

      // Legacy
      const subkeys = <String, int>{
        'MsSecCore': 0,
        'MsSecFlt': 0,
        'MsSecWfp': 3,
        'SecurityHealthService': 3,
        'Sense': 3,
        'WdBoot': 0,
        'WdFilter': 0,
        'WdNisDrv': 3,
        'WdNisSvc': 3,
        'WinDefend': 2,
        'wscsvc': 2,
        'MDCoreSvc': 2,
        'SgrmAgent': 0,
        'SgrmBroker': 2,
        'webthreatdefsvc': 3,
        'webthreatdefusersvc': 2,
      };

      for (final entry in subkeys.entries) {
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Services\' + entry.key,
          'Start',
          entry.value,
        );
      }

      final webthreatdefsvcList =
          WinRegistryService.getUserServices('webthreatdefusersvc');

      for (final webthreatdefsvc in webthreatdefsvcList) {
        WinRegistryService.writeRegistryValue(Registry.localMachine,
            r'SYSTEM\ControlSet001\Services\' + webthreatdefsvc, 'Start', 2);
      }

      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
          'SecurityHealth',
          r'%windir%\system32\SecurityHealthSystray.exe');

      WinRegistryService.deleteKey(Registry.localMachine,
          r'Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\smartscreen.exe');

      const smartscreenPath = 'C:\\Windows\\System32\\smartscreen.exe';
      if (!File(smartscreenPath).existsSync() &&
          File('$smartscreenPath.revi').existsSync()) {
        await _shell.run(
            '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller ren "$smartscreenPath.revi" smartscreen.exe');
      }

      WinRegistryService.deleteKey(Registry.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations');
      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer',
          'SmartScreenEnabled',
          'On');
      WinRegistryService.deleteValue(Registry.localMachine,
          r'Software\Policies\Microsoft\System', 'EnableSmartScreen');

      WinRegistryService.deleteValue(
          Registry.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\AppHost',
          'EnableWebContentEvaluation');
      WinRegistryService.deleteValue(
          Registry.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\AppHost',
          'PreventOverride');
      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'Software\Microsoft\Windows\CurrentVersion\AppHost',
          'EnableWebContentEvaluation');

      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\CI\Policy',
          'VerifiedAndReputablePolicyState');

      WinRegistryService.deleteKey(Registry.localMachine,
          r'Software\Policies\Microsoft\Windows Defender');
      WinRegistryService.deleteKey(Registry.localMachine,
          r'Software\Policies\Microsoft\Windows Advanced Threat Protection');
      WinRegistryService.deleteKey(Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender Security Center');

      WinRegistryService.writeRegistryValue(Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender', 'PUAProtection', 1);

      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\CI\Config',
          'VulnerableDriverBlocklistEnable');
      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
          'Enabled');

      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\WMI\Autologger\DefenderApiLogger',
          'Start',
          1);
      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\WMI\Autologger\DefenderAuditLogger',
          'Start',
          1);
    } on Exception catch (e) {
      throw ('Failed to enable Windows Defender:\n\n$e');
    }
  }

  Future<void> disableDefender() async {
    try {
      await _winPackageService.downloadPackage(WinPackageType.defenderRemoval);

      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiSpyware',
          1);
      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiVirus',
          1);
      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection',
          'DisableRealtimeMonitoring',
          1);

      await _shell.run(
          'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force');

      if (await File(_mpCmdRunString).exists()) {
        await _shell.run(
            "PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP -C 'Start-Process -FilePath \"$_mpCmdRunString\" -ArgumentList \"-RemoveDefinitions -All\" -NoNewWindow -Wait'");
      }

      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\SOFTWARE\\Microsoft\\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f');
      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\SOFTWARE\\Microsoft\\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f');

      await _shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller reg add "HKLM\\System\\ControlSet001\\Services\\MDCoreSvc" /v Start /t REG_DWORD /d 4 /f');

      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
          'RevisionEnableDefenderCMD');

      await _winPackageService.installPackage(WinPackageType.defenderRemoval);
    } on Exception catch (e) {
      throw ('Failed to disable Windows Defender:\n\n$e');
    }
  }

  bool get statusUAC {
    return WinRegistryService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
            'EnableLUA') ==
        1;
  }

  void enableUAC() {
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        5);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        3);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0);
  }

  void disableUAC() {
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0);
  }

  bool isMitigationEnabled(Mitigation mitigation) {
    final val = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
      'FeatureSettingsOverride',
    );
    if (val == null) return true;
    return (val & mitigation.bitmask) == 0;
  }

  void enableMitigation(Mitigation mitigation) {
    final otherMitigation =
        Mitigation.values[(mitigation.index + 1) % Mitigation.values.length];
    if (isMitigationEnabled(otherMitigation)) {
      WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          'FeatureSettings',
          0);
      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          'FeatureSettingsOverride');
      WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          'FeatureSettingsOverrideMask');
      return;
    }

    final currentVal = _readOverride();
    final newVal = currentVal & ~mitigation.bitmask;
    _writeOverride(newVal);
  }

  void disableMitigation(Mitigation mitigation) {
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettings',
        1);

    final currentVal = _readOverride();
    final newVal = currentVal | mitigation.bitmask;
    _writeOverride(newVal);
  }

  Future<void> updateCertificates() async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoP -C "& {\$tmp = (New-TemporaryFile).FullName; CertUtil -generateSSTFromWU -f \$tmp; if ( (Get-Item \$tmp | Measure-Object -Property Length -Sum).sum -gt 0 ) { \$SST_File = Get-ChildItem -Path \$tmp; \$SST_File | Import-Certificate -CertStoreLocation "Cert:\\LocalMachine\\Root"; \$SST_File | Import-Certificate -CertStoreLocation "Cert:\\LocalMachine\\AuthRoot" } Remove-Item -Path \$tmp}"');
  }
}

int _readOverride() {
  return WinRegistryService.readInt(
        RegistryHive.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverride',
      ) ??
      0;
}

void _writeOverride(int value) {
  WinRegistryService.writeRegistryValue(
    Registry.localMachine,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
    'FeatureSettingsOverride',
    value,
  );
  WinRegistryService.writeRegistryValue(
    Registry.localMachine,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
    'FeatureSettingsOverrideMask',
    value,
  );
}
