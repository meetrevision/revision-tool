import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:revitool/shared/network_service.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';

import 'package:win32_registry/win32_registry.dart';

enum WinPackageType {
  systemComponentsRemoval(
    packageName: 'Revision-ReviOS-SystemPackages-Removal',
  ),
  defenderRemoval(packageName: 'Revision-ReviOS-Defender-Removal'),
  aiRemoval(packageName: 'Revision-ReviOS-AI-Removal'),
  oneDriveRemoval(packageName: 'Revision-ReviOS-OneDrive-Removal');

  const WinPackageType({required this.packageName});

  final String packageName;
}

abstract final class WinPackageService {
  static final _networkService = NetworkService();

  static final cabPath = p.join(
    Directory.systemTemp.path,
    'Revision-Tool',
    'CAB',
  );

  static final bundledPackagesPath = p.join(directoryExe, 'packages', 'winsxs');

  static const cbsPackagesRegPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';

  static bool checkPackageInstalled(final WinPackageType packageType) {
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

  static String? getBundledPackagePath(final WinPackageType packageType) {
    try {
      final bundledDir = Directory(bundledPackagesPath);
      if (!bundledDir.existsSync()) {
        logger.w(
          'Bundled packages directory does not exist: $bundledPackagesPath',
        );
        return null;
      }

      final String? packageFile = bundledDir
          .listSync()
          .whereType<File>()
          .map((file) => p.basename(file.path))
          .firstWhereOrNull(
            (name) =>
                name.startsWith("${packageType.packageName}31bf3856ad364e35") &&
                name.contains(WinRegistryService.cpuArch) &&
                name.endsWith('.cab'),
          );

      if (packageFile != null) {
        final fullPath = p.join(bundledPackagesPath, packageFile);
        logger.i('Found bundled package: $fullPath');
        return fullPath;
      }
    } catch (e) {
      logger.w('Error checking bundled packages: $e');
    }
    return null;
  }

  static Future<String> downloadPackage(
    final WinPackageType packageType, {
    String? path,
  }) async {
    final downloadPath = path ?? cabPath;

    try {
      logger.i('Attempting to download package from GitHub...');

      Directory(downloadPath).createSync(recursive: true);

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

      final filePath = p.join(downloadPath, name);

      await _networkService.downloadFile(downloadUrl, filePath);
      if (!File(filePath).existsSync()) {
        throw 'Failed to download package: $name';
      }

      logger.i('Successfully downloaded package from GitHub: $filePath');
      return filePath;
    } catch (e) {
      logger.w('Failed to download from GitHub: $e');
      logger.i('Falling back to bundled packages...');

      final bundledPath = getBundledPackagePath(packageType);
      if (bundledPath != null && File(bundledPath).existsSync()) {
        logger.i('Using bundled package: $bundledPath');

        if (path != null) {
          final targetPath = p.join(path, p.basename(bundledPath));
          Directory(path).createSync(recursive: true);
          await File(bundledPath).copy(targetPath);
          return targetPath;
        }

        return bundledPath;
      }

      logger.e('No bundled package found for ${packageType.packageName}');
      throw 'Failed to download package from GitHub and no bundled package available: $e';
    }
  }

  static Future<void> installPackage(final String packagePath) async {
    if (!File(packagePath).existsSync()) {
      throw 'Package file does not exist: $packagePath';
    }

    String certValue = await runPSCommand(
      '(Get-AuthenticodeSignature -FilePath "$packagePath").SignerCertificate.Extensions.EnhancedKeyUsages.Value',
    );
    certValue = certValue.trim();

    if (certValue.isEmpty || certValue != '1.3.6.1.4.1.311.10.3.6') {
      throw '[win_package] invalid signature: $packagePath';
    }

    WinRegistryService.createKey(
      Registry.localMachine,
      r'Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344',
    );

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await runPSCommand(
      'Add-WindowsPackage -Online -NoRestart -IgnoreCheck -PackagePath "$packagePath"',
    );
    await File(packagePath).delete();
  }

  static Future<void> uninstallPackage(final WinPackageType packageType) async {
    await runPSCommand(
      'Get-WindowsPackage -Online -PackageName "${packageType.packageName}*" | Remove-WindowsPackage -Online -NoRestart',
    );
  }
}
