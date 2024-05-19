import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:revitool/services/network_service.dart';
import 'package:win32_registry/win32_registry.dart';

import '../utils.dart';
import 'registry_utils_service.dart';
import 'setup_service.dart';
import 'package:process_run/shell_run.dart';
import 'package:path/path.dart' as p;

class SecurityService implements SetupService {
  static final _shell = Shell();
  static final _networkService = NetworkService();

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
    const path =
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';
    final String? key = Registry.openPath(RegistryHive.localMachine, path: path)
        .subkeyNames
        .lastWhereOrNull((element) =>
            element.startsWith("Revision-ReviOS-Defender-Removal"));

    return key == null ||
        RegistryUtilsService.readInt(
                RegistryHive.localMachine, path + key, 'CurrentState') ==
            5; // installation codes - https://forums.ivanti.com/s/article/Understand-Patch-installation-failure-codes?language=en_US
  }

  bool get statusDefenderProtections {
    return (RegistryUtilsService.readInt(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows Defender\Features',
                'TamperProtection') !=
            4 ||
        RegistryUtilsService.readInt(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows Defender\Real-Time Protection',
                'DisableRealtimeMonitoring') !=
            1);
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

      await _shell.run(
          'PowerShell -NonInteractive -NoLogo -NoP -C "Get-WindowsPackage -Online -PackageName \'Revision-ReviOS-Defender-Removal*\' | Remove-WindowsPackage -Online -NoRestart"');

      await _shell.run(
          'start /WAIT /MIN /B "" "%systemroot%\\System32\\gpupdate.exe" /Target:Computer /Force');

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
    final cabPath = p.join(Directory.systemTemp.path, 'Revision-Tool', 'CAB');
    if (await Directory(cabPath).exists()) {
      try {
        await Directory(cabPath).delete(recursive: true);
      } catch (e) {
        stderr.writeln('Failed to delete CAB directory: $e');
      }
    }

    final Map<String, dynamic> json =
        await _networkService.getGHLatestRelease(ApiEndpoints.cabPackages);
    final List<dynamic> assests = json['assets'];
    String name = '';

    final String downloadUrl = assests.firstWhereOrNull((element) {
      name = element['name'];
      return name
              .startsWith("Revision-ReviOS-Defender-Removal31bf3856ad364e35") &&
          name.contains(RegistryUtilsService.cpuArch);
    })['browser_download_url'];
    await _networkService.downloadFile(downloadUrl, "$cabPath\\$name");

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

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await _shell.run(
        "powershell -EP Unrestricted -NoLogo -NonInteractive -NoP -File \"$directoryExe\\cab-installer.ps1\" -Path \"$cabPath\"");
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
