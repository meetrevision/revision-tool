import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';

import 'package:revitool/services/network_service.dart';
import 'package:revitool/services/registry_utils_service.dart';
import 'package:revitool/utils.dart';
import 'package:win32_registry/win32_registry.dart';

enum WinPackageType {
  systemComponentsRemoval(
      packageName: 'Revision-ReviOS-SystemPackages-Removal'),
  defenderRemoval(packageName: 'Revision-ReviOS-Defender-Removal');

  const WinPackageType({
    required this.packageName,
  });

  final String packageName;
}

class WinPackageService {
  static const _instance = WinPackageService._private();
  factory WinPackageService() => _instance;
  const WinPackageService._private();

  static final _networkService = NetworkService();
  static final _shell = Shell();

  static final cabPath =
      p.join(Directory.systemTemp.path, 'Revision-Tool', 'CAB');
  static const cbsPackagesRegPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';

  bool checkPackageInstalled(final WinPackageType packageType) {
    final String? key =
        Registry.openPath(RegistryHive.localMachine, path: cbsPackagesRegPath)
            .subkeyNames
            .lastWhereOrNull(
                (final element) => element.startsWith(packageType.packageName));

    if (key == null) {
      return false;
    }

    final int currentState = RegistryUtilsService.readInt(
        RegistryHive.localMachine, cbsPackagesRegPath + key, 'CurrentState')!;

    // installation codes - https://forums.ivanti.com/s/article/Understand-Patch-installation-failure-codes?language=en_US
    return currentState != 5 || currentState != 4294967264;
  }

  Future<void> downloadPackage(final WinPackageType packageType) async {
    final cabPath = p.join(Directory.systemTemp.path, 'Revision-Tool', 'CAB');
    if (await Directory(cabPath).exists()) {
      try {
        await Directory(cabPath).delete(recursive: true);
      } catch (e) {
        stderr.writeln('Failed to delete CAB directory: $e');
      }
    }

    final List<dynamic> assests = (await _networkService
        .getGHLatestRelease(ApiEndpoints.cabPackages))['assets'];
    String name = '';

    final String downloadUrl = assests.firstWhereOrNull((final e) {
      name = e['name'];
      return name.startsWith("${packageType.packageName}31bf3856ad364e35") &&
          name.contains(RegistryUtilsService.cpuArch);
    })['browser_download_url'];

    await _networkService.downloadFile(downloadUrl, "$cabPath\\$name");
  }

  Future<void> installPackage(final WinPackageType packageType) async {
    if (!await File("$directoryExe\\cab-installer.ps1").exists()) {
      throw 'cab-installer.ps1 not found in $directoryExe. Please ensure the file is present by reinstalling Revision Tool.';
    }

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await _shell.run(
        "powershell -EP Unrestricted -NoLogo -NonInteractive -NoP -File \"$directoryExe\\cab-installer.ps1\" -Path \"$cabPath\"");
  }

  Future<void> uninstallPackage(final WinPackageType packageType) async {
    await _shell.run(
        'PowerShell -NonInteractive -NoLogo -NoP -C "Get-WindowsPackage -Online -PackageName \'${packageType.packageName}*\' | Remove-WindowsPackage -Online -NoRestart"');
  }
}
