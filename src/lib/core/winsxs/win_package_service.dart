import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:revitool/core/security/security_service.dart';
import 'package:revitool/shared/network_service.dart';
import 'package:revitool/shared/win_registry_service.dart';

import 'package:win32_registry/win32_registry.dart';

enum WinPackageType {
  systemComponentsRemoval(
    packageName: 'Revision-ReviOS-SystemPackages-Removal',
  ),
  defenderRemoval(packageName: 'Revision-ReviOS-Defender-Removal'),
  aiRemoval(packageName: 'Revision-ReviOS-AI-Removal');

  const WinPackageType({required this.packageName});

  final String packageName;
}

class WinPackageService {
  static const _instance = WinPackageService._private();
  factory WinPackageService() => _instance;
  const WinPackageService._private();

  static final _networkService = NetworkService();
  static final _shell = Shell();
  static final _securityService = SecurityService();

  static final cabPath = p.join(
    Directory.systemTemp.path,
    'Revision-Tool',
    'CAB',
  );
  static const cbsPackagesRegPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';

  bool checkPackageInstalled(final WinPackageType packageType) {
    final String? key =
        Registry.openPath(
          RegistryHive.localMachine,
          path: cbsPackagesRegPath,
        ).subkeyNames.lastWhereOrNull(
          (final element) => element.startsWith(packageType.packageName),
        );

    if (key == null) {
      return false;
    }

    final int currentState = WinRegistryService.readInt(
      RegistryHive.localMachine,
      cbsPackagesRegPath + key,
      'CurrentState',
    )!;

    final int? lastError = WinRegistryService.readInt(
      RegistryHive.localMachine,
      cbsPackagesRegPath + key,
      'LastError',
    );

    // installation codes - https://forums.ivanti.com/s/article/Understand-Patch-installation-failure-codes?language=en_US
    return (currentState != 5 || currentState != 4294967264) &&
        lastError == null;
  }

  Future<String> downloadPackage(final WinPackageType packageType) async {
    final cabPath = p.join(Directory.systemTemp.path, 'Revision-Tool', 'CAB');
    if (await Directory(cabPath).exists()) {
      try {
        await Directory(cabPath).delete(recursive: true);
      } catch (e) {
        stderr.writeln('Failed to delete CAB directory: $e');
      }
    }

    final List<dynamic> assests = (await _networkService.getGHLatestRelease(
      ApiEndpoints.cabPackages,
    ))['assets'];
    String name = '';

    final String? downloadUrl = assests.firstWhereOrNull((final e) {
      name = e['name'];
      return name.startsWith("${packageType.packageName}31bf3856ad364e35") &&
          name.contains(WinRegistryService.cpuArch);
    })['browser_download_url'];

    if (downloadUrl == null) {
      throw 'No matching package found for ${packageType.packageName} with architecture ${WinRegistryService.cpuArch}';
    }

    final downloadPath = "$cabPath\\$name";
    await _networkService.downloadFile(downloadUrl, downloadPath);
    if (!File(downloadPath).existsSync()) {
      throw 'Failed to download package: $name';
    }

    return downloadPath;
  }

  Future<void> installPackage(final String packagePath) async {
    WinRegistryService.createKey(
      Registry.localMachine,
      r'Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344',
    );

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await _shell.run(
      "powershell -EP Unrestricted -NoLogo -NonInteractive -NoP -C \"Add-WindowsPackage -Online -NoRestart -IgnoreCheck -PackagePath '$packagePath'\"",
    );
  }

  Future<void> uninstallPackage(final WinPackageType packageType) async {
    if (packageType == WinPackageType.defenderRemoval) {
      await _securityService.enableDefender();
    }

    await _shell.run(
      'PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP -C "Get-WindowsPackage -Online -PackageName \'${packageType.packageName}*\' | Remove-WindowsPackage -Online -NoRestart"',
    );
  }
}
