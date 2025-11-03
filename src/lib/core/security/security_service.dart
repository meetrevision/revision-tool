import 'dart:io';

import 'package:revitool/core/winsxs/win_package_service.dart';
import 'package:revitool/shared/trusted_installer/trusted_installer_service.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

part 'security_service.g.dart';

enum Mitigation { meltdownSpectre, downfall }

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

/// Abstract interface for security-related operations
abstract class SecurityService {
  bool get statusDefender;
  bool get statusDefenderProtections;
  bool get statusDefenderProtectionTamper;
  bool get statusDefenderProtectionRealtime;
  bool get statusUAC;

  Future<ProcessResult> openDefenderThreatSettings();
  Future<void> enableDefender();
  Future<void> disableDefender();
  Future<void> enableUAC();
  Future<void> disableUAC();
  bool isMitigationEnabled(Mitigation mitigation);
  Future<void> enableMitigation(Mitigation mitigation);
  Future<void> disableMitigation(Mitigation mitigation);
  Future<void> updateCertificates();
}

/// Implementation of SecurityService
class SecurityServiceImpl implements SecurityService {
  const SecurityServiceImpl();

  String get _mpCmdRunString =>
      '${WinRegistryService.readString(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows Defender', 'InstallLocation') ?? r'C:\Program Files\Windows Defender'}\\MpCmdRun.exe';

  @override
  bool get statusDefender {
    if (WinPackageService.checkPackageInstalled(
      WinPackageType.defenderRemoval,
    )) {
      return false;
    }

    if (WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender',
          'DisableAntiSpyware',
        ) ==
        1) {
      return false;
    }

    if (WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Services\WinDefend',
          'Start',
        ) ==
        4) {
      return false;
    }

    return true;
  }

  @override
  bool get statusDefenderProtections {
    return (statusDefenderProtectionTamper ||
            statusDefenderProtectionRealtime) &&
        statusDefender;
  }

  @override
  bool get statusDefenderProtectionTamper {
    final tp = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows Defender\Features',
      'TamperProtection',
    );
    final tpSource = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows Defender\Features',
      'TamperProtectionSource',
    );

    if (tp == 0 && tpSource == null) {
      return false;
    }

    return tp != 4;
  }

  @override
  bool get statusDefenderProtectionRealtime {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender\Real-Time Protection',
          'DisableRealtimeMonitoring',
        ) !=
        1;
  }

  @override
  Future<ProcessResult> openDefenderThreatSettings() async {
    return await Process.run('start', [
      'windowsdefender://threatsettings',
    ], runInShell: true);
  }

  @override
  Future<void> enableDefender() async {
    try {
      await Future.wait([
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiSpyware',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiVirus',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection',
          'DisableRealtimeMonitoring',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender',
          'DisableAntiSpyware',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender',
          'DisableAntiVirus',
        ),
      ]);

      await WinPackageService.uninstallPackage(WinPackageType.defenderRemoval);

      await shell.run(
        'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force',
      );

      await Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'System\ControlSet001\Services\MDCoreSvc',
          'Start',
          2,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
          'RevisionEnableDefenderCMD',
          '"$_mpCmdRunString" -WDEnable',
        ),
      ]);

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

      await Future.wait(
        subkeys.entries.map(
          (entry) => WinRegistryService.writeRegistryValue(
            Registry.localMachine,
            r'SYSTEM\ControlSet001\Services\' + entry.key,
            'Start',
            entry.value,
          ),
        ),
      );

      final webthreatdefsvcList = WinRegistryService.getUserServices(
        'webthreatdefusersvc',
      );

      await Future.wait(
        webthreatdefsvcList.map(
          (webthreatdefsvc) => WinRegistryService.writeRegistryValue(
            Registry.localMachine,
            r'SYSTEM\ControlSet001\Services\' + webthreatdefsvc,
            'Start',
            2,
          ),
        ),
      );

      await Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
          'SecurityHealth',
          r'%windir%\system32\SecurityHealthSystray.exe',
        ),
        WinRegistryService.deleteKey(
          Registry.localMachine,
          r'Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\smartscreen.exe',
        ),
      ]);

      const smartscreenPath = 'C:\\Windows\\System32\\smartscreen.exe';
      if (!File(smartscreenPath).existsSync() &&
          File('$smartscreenPath.revi').existsSync()) {
        await TrustedInstallerServiceImpl().executeCommand('ren', [
          '$smartscreenPath.revi',
          'smartscreen.exe',
        ]);
      }

      await Future.wait([
        WinRegistryService.deleteKey(
          WinRegistryService.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations',
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer',
          'SmartScreenEnabled',
          'On',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'Software\Policies\Microsoft\System',
          'EnableSmartScreen',
        ),
        WinRegistryService.deleteValue(
          WinRegistryService.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\AppHost',
          'EnableWebContentEvaluation',
        ),
        WinRegistryService.deleteValue(
          WinRegistryService.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\AppHost',
          'PreventOverride',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'Software\Microsoft\Windows\CurrentVersion\AppHost',
          'EnableWebContentEvaluation',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\CI\Policy',
          'VerifiedAndReputablePolicyState',
        ),
        WinRegistryService.deleteKey(
          Registry.localMachine,
          r'Software\Policies\Microsoft\Windows Defender',
        ),
        WinRegistryService.deleteKey(
          Registry.localMachine,
          r'Software\Policies\Microsoft\Windows Advanced Threat Protection',
        ),
        WinRegistryService.deleteKey(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender Security Center',
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender',
          'PUAProtection',
          1,
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\CI\Config',
          'VulnerableDriverBlocklistEnable',
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
          'Enabled',
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\WMI\Autologger\DefenderApiLogger',
          'Start',
          1,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Control\WMI\Autologger\DefenderAuditLogger',
          'Start',
          1,
        ),
      ]);
    } on Exception catch (e) {
      throw ('Failed to enable Windows Defender:\n\n$e');
    }
  }

  @override
  Future<void> disableDefender() async {
    try {
      await WinPackageService.downloadPackage(WinPackageType.defenderRemoval);

      await Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiSpyware',
          1,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender',
          'DisableAntiVirus',
          1,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection',
          'DisableRealtimeMonitoring',
          1,
        ),
      ]);

      await shell.run(
        'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force',
      );

      if (File(_mpCmdRunString).existsSync()) {
        await runPSCommand(
          'Start-Process -FilePath "$_mpCmdRunString" -ArgumentList "-RemoveDefinitions -All" -NoNewWindow -Wait',
        );
      }

      await Future.wait([
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender',
          'DisableAntiSpyware',
          1,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows Defender',
          'DisableAntiVirus',
          1,
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'System\ControlSet001\Services\MDCoreSvc',
          'Start',
          4,
        ),
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
          'RevisionEnableDefenderCMD',
        ),
      ]);

      final packagePath = await WinPackageService.downloadPackage(
        WinPackageType.defenderRemoval,
      );
      await WinPackageService.installPackage(packagePath);
    } on Exception catch (e) {
      throw ('Failed to disable Windows Defender:\n\n$e');
    }
  }

  @override
  bool get statusUAC {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
          'EnableLUA',
        ) ==
        1;
  }

  @override
  Future<void> enableUAC() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        5,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        3,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0,
      ),
    ]);
  }

  @override
  Future<void> disableUAC() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableVirtualization',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableInstallerDetection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'PromptOnSecureDesktop',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableLUA',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableSecureUIAPaths',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorAdmin',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ValidateAdminCodeSignatures',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'EnableUIADesktopToggle',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'ConsentPromptBehaviorUser',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
        'FilterAdministratorToken',
        0,
      ),
    ]);
  }

  @override
  bool isMitigationEnabled(Mitigation mitigation) {
    final val = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
      'FeatureSettingsOverride',
    );
    if (val == null) return true;
    return (val & mitigation.bitmask) == 0;
  }

  @override
  Future<void> enableMitigation(Mitigation mitigation) async {
    final otherMitigation =
        Mitigation.values[(mitigation.index + 1) % Mitigation.values.length];
    if (isMitigationEnabled(otherMitigation)) {
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettings',
        0,
      );
      await WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverride',
      );
      await WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
        'FeatureSettingsOverrideMask',
      );
      return;
    }

    final currentVal = _readOverride();
    final newVal = currentVal & ~mitigation.bitmask;
    _writeOverride(newVal);
  }

  @override
  Future<void> disableMitigation(Mitigation mitigation) async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
      'FeatureSettings',
      1,
    );

    final currentVal = _readOverride();
    final newVal = currentVal | mitigation.bitmask;
    _writeOverride(newVal);
  }

  @override
  Future<void> updateCertificates() async {
    await shell.run(
      'PowerShell -NonInteractive -NoLogo -NoP -C "& {\$tmp = (New-TemporaryFile).FullName; CertUtil -generateSSTFromWU -f \$tmp; if ( (Get-Item \$tmp | Measure-Object -Property Length -Sum).sum -gt 0 ) { \$SST_File = Get-ChildItem -Path \$tmp; \$SST_File | Import-Certificate -CertStoreLocation "Cert:\\LocalMachine\\Root"; \$SST_File | Import-Certificate -CertStoreLocation "Cert:\\LocalMachine\\AuthRoot" } Remove-Item -Path \$tmp}"',
    );
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

Future<void> _writeOverride(int value) async {
  await WinRegistryService.writeRegistryValue(
    Registry.localMachine,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
    'FeatureSettingsOverride',
    value,
  );
  await WinRegistryService.writeRegistryValue(
    Registry.localMachine,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
    'FeatureSettingsOverrideMask',
    value,
  );
}

// Riverpod Providers
@Riverpod(keepAlive: true)
SecurityService securityService(Ref ref) {
  return const SecurityServiceImpl();
}

@riverpod
bool defenderStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusDefender;
}

@riverpod
bool defenderProtectionsStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusDefenderProtections;
}

@riverpod
bool defenderProtectionTamperStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusDefenderProtectionTamper;
}

@riverpod
bool defenderProtectionRealtimeStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusDefenderProtectionRealtime;
}

@riverpod
bool uacStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusUAC;
}

@riverpod
bool meltdownSpectreStatus(Ref ref) {
  return ref
      .watch(securityServiceProvider)
      .isMitigationEnabled(Mitigation.meltdownSpectre);
}

@riverpod
bool downfallStatus(Ref ref) {
  return ref
      .watch(securityServiceProvider)
      .isMitigationEnabled(Mitigation.downfall);
}
