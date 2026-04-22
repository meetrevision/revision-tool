import 'dart:io';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../../core/cli_generator/annotations.dart';
import '../../../core/services/win_registry_service.dart';
import '../../../core/trusted_installer/trusted_installer_service.dart';
import '../../winsxs/win_package_service.dart';
import 'security_exceptions.dart';

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

@CliCommand(name: 'security', description: 'Security tweaks')
abstract class SecurityService {
  bool get statusDefenderProtections;
  bool get statusDefenderProtectionTamper;
  bool get statusDefenderProtectionRealtime;
  Future<ProcessResult> openDefenderThreatSettings();

  @CliToggle(
    name: 'defender',
    status: 'statusDefender',
    enable: 'enableDefenderCLI',
    disable: 'disableDefenderCLI',
    enableForce: 'enableDefender',
    disableForce: 'disableDefender',
  )
  bool get statusDefender;
  Future<void> enableDefender();
  Future<void> disableDefender();
  Future<void> enableDefenderCLI();
  Future<void> disableDefenderCLI();

  @CliToggle(
    name: 'uac',
    status: 'statusUAC',
    enable: 'enableUAC',
    disable: 'disableUAC',
  )
  bool get statusUAC;
  Future<void> enableUAC();
  Future<void> disableUAC();

  @CliEnumSubCommand(
    name: 'mitigation',
    values: Mitigation.values,
    status: 'isMitigationEnabled',
    enableMethod: 'enableMitigation',
    disableMethod: 'disableMitigation',
  )
  bool isMitigationEnabled(Mitigation mitigation);
  Future<void> enableMitigation(Mitigation mitigation);
  Future<void> disableMitigation(Mitigation mitigation);

  @CliToggle(
    name: 'vbs',
    status: 'statusVbs',
    enable: 'enableVbs',
    disable: 'disableVbs',
  )
  bool get statusVbs;
  Future<void> enableVbs();
  Future<void> disableVbs();

  @CliToggle(
    name: 'memory-integrity',
    status: 'statusMemoryIntegrity',
    enable: 'enableMemoryIntegrity',
    disable: 'disableMemoryIntegrity',
  )
  bool get statusMemoryIntegrity;
  Future<void> enableMemoryIntegrity();
  Future<void> disableMemoryIntegrity();
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
    final int? tp = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows Defender\Features',
      'TamperProtection',
    );
    final int? tpSource = WinRegistryService.readInt(
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
    return Process.run('start', [
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

      await runPSCommand(
        r'& $env:SystemRoot\System32\gpupdate.exe /Target:Computer /Force',
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

      await Future.wait([
        WinRegistryService.deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray',
          'HideSystray',
        ),
        WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
          'SecurityHealth',
          r'%windir%\system32\SecurityHealthSystray.exe',
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

      final Iterable<String> webthreatdefsvcList =
          WinRegistryService.getUserServices('webthreatdefusersvc');

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

      const smartscreenPath = r'C:\Windows\System32\smartscreen.exe';
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
      throw DefenderOperationException('Failed to enable Windows Defender', e);
    }
  }

  @override
  Future<void> disableDefender() async {
    try {
      final String packagePath = await WinPackageService.downloadPackage(
        WinPackageType.defenderRemoval,
      );

      /// Internal helper
      Future<void> applyPolicyWrites() async {
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
        await runPSCommand(
          r'& $env:SystemRoot\System32\gpupdate.exe /Target:Computer /Force',
        );
        if (File(_mpCmdRunString).existsSync()) {
          await runPSCommand(
            'Start-Process -FilePath "$_mpCmdRunString" -ArgumentList "-RemoveDefinitions -All" -NoNewWindow -Wait',
          );
        }
      }

      await applyPolicyWrites();

      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows Defender',
        'DisableAntiSpyware',
        1,
        useTrustedInstaller: true,
      );
      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows Defender',
        'DisableAntiVirus',
        1,
        useTrustedInstaller: true,
      );

      // WORKAROUND: Force a second policy update after modifying the core Defender registry keys. After the January 2026 security updates, 'gpupdate' automatically removes 'DisableAntiSpyware' in the Policies path, when security intelligence updates is installed. Re-applying policies after modifying the core Defender registries ensures both locations are synchronized, resolving permission errors that occur when trying to disable Defender services directly.
      await applyPolicyWrites();

      await WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'System\ControlSet001\Services\MDCoreSvc',
        'Start',
        4,
        useTrustedInstaller: true,
      );

      await WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'RevisionEnableDefenderCMD',
      );

      await WinPackageService.installPackage(packagePath);
    } on Exception catch (e) {
      throw DefenderOperationException('Failed to disable Windows Defender', e);
    }
  }

  @override
  Future<void> enableDefenderCLI() {
    if (statusDefender) {
      logger.i('security: Windows Defender is already enabled');
      return Future.value();
    }
    return enableDefender();
  }

  @override
  Future<void> disableDefenderCLI() async {
    if (!statusDefender) {
      logger.i('security: Windows Defender is already disabled');
      return;
    }
    logger.i(
      'security: Checking if Virus and Threat Protections are enabled...',
    );
    var count = 0;
    while (statusDefenderProtections) {
      if (count > 10) {
        throw DefenderOperationException(
          'Unable to disable Defender. Disable Realtime and Tamper protections, then retry.',
        );
      }

      if (!statusDefenderProtectionTamper) {
        await runPSCommand(
          r'Set-MpPreference -DisableRealtimeMonitoring $true',
        );
        break;
      }

      logger.i('security: Please disable Realtime and Tamper Protections');
      await openDefenderThreatSettings();
      await Future<void>.delayed(const Duration(seconds: 7));
      count++;
    }

    await Process.run('taskkill', ['/f', '/im', 'SecHealthUI.exe']);
    await disableDefender();
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
    final int? val = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
      'FeatureSettingsOverride',
    );
    if (val == null) return true;
    return (val & mitigation.bitmask) == 0;
  }

  @override
  Future<void> enableMitigation(Mitigation mitigation) async {
    final Mitigation otherMitigation =
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

    final int currentVal = _readOverride();
    final int newVal = currentVal & ~mitigation.bitmask;
    await _writeOverride(newVal);
  }

  @override
  Future<void> disableMitigation(Mitigation mitigation) async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
      'FeatureSettings',
      1,
    );

    final int currentVal = _readOverride();
    final int newVal = currentVal | mitigation.bitmask;
    await _writeOverride(newVal);
  }

  @override
  bool get statusVbs {
    if (statusMemoryIntegrity) return true;

    final int? policyVbs = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SOFTWARE\Policies\Microsoft\Windows\DeviceGuard',
      'EnableVirtualizationBasedSecurity',
    );
    final int? systemVbs = WinRegistryService.readInt(
      RegistryHive.localMachine,
      r'SYSTEM\ControlSet001\Control\DeviceGuard',
      'EnableVirtualizationBasedSecurity',
    );

    return policyVbs == 1 || systemVbs == 1;

    // final ProcessResult process = Process.runSync('powershell', [
    //   '-NoProfile',
    //   '-NonInteractive',
    //   '-NoLogo',
    //   '-Command',
    //   r'(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).VirtualizationBasedSecurityStatus',
    // ], runInShell: true);

    // if (process.exitCode == 0) {
    //   final int result = int.parse(process.stdout.toString().trim());
    //   return result != 0;
    // }

    // return false;
  }

  @override
  bool get statusMemoryIntegrity {
    final int? hvciEnabled = WinRegistryService.readInt(
      .localMachine,
      r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
      'Enabled',
    );

    return hvciEnabled == 1;
  }

  @override
  Future<void> enableVbs() async {
    await Future.wait([
      runPSCommand(
        'Invoke-Command -ScriptBlock { bcdedit /deletevalue hypervisorlaunchtype; bcdedit /deletevalue vsmlaunchtype }',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\DeviceGuard',
        'EnableVirtualizationBasedSecurity',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard',
        'EnableVirtualizationBasedSecurity',
        1,
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard',
        'Mandatory',
      ),

      // Legacy: HVCIMATRequired can no longer be found in newer W11 builds
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\DeviceGuard',
        'HVCIMATRequired',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard',
        'HVCIMATRequired',
      ),
    ]);
  }

  @override
  Future<void> disableVbs() async {
    await Future.wait([
      runPSCommand(
        'Invoke-Command -ScriptBlock { bcdedit /set vsmlaunchtype off }',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\DeviceGuard',
        'EnableVirtualizationBasedSecurity',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard',
        'EnableVirtualizationBasedSecurity',
        0,
      ),

      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard',
        'Mandatory',
        0,
      ),

      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\DeviceGuard',
        'LsaCfgFlags',
        0,
      ),

      // Even if VBS registries are set to the disabled state, if Memory Integrity is enabled, VBS will still be active
      disableMemoryIntegrity(),

      // Legacy: HVCIMATRequired can no longer be found in newer W11 builds
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\DeviceGuard',
        'HVCIMATRequired',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard',
        'HVCIMATRequired',
        0,
      ),
    ]);
  }

  @override
  Future<void> enableMemoryIntegrity() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
      'Enabled',
      1,
    );
  }

  @override
  Future<void> disableMemoryIntegrity() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
        'Enabled',
        0,
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
        'WasEnabledBy',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity',
        'ChangedInBootCycle',
      ),
    ]);
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

@riverpod
bool vbsStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusVbs;
}

@riverpod
bool memoryIntegrityStatus(Ref ref) {
  return ref.watch(securityServiceProvider).statusMemoryIntegrity;
}
