import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:path/path.dart' as p;
import 'package:win32_registry/win32_registry.dart';

import '../../../../core/services/win_registry_service.dart';
import '../../../../utils.dart';
import '../../domain/entities/win_package.dart';
import '../../domain/winsxs_exceptions.dart';
import '../datasources/api_cab_datasource.dart';
import '../models/release_model.dart';
import 'win_package_repository.dart';

final class const WinPackageRepositoryImpl({required final ApiCabDataSource api})
    implements WinPackageRepository {
  static final String bundledPackagesPath = p.join(directoryExe, 'packages', 'winsxs');

  static const _cbsPackagesRegPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';

  static bool _isPackageKeyInstalled(String packageKey) {
    final int? currentState = WinRegistryService.readInt(
      LOCAL_MACHINE,
      '$_cbsPackagesRegPath$packageKey',
      'CurrentState',
    );

    if (currentState == null) return true;

    // installation codes - https://forums.ivanti.com/s/article/Understand-Patch-installation-failure-codes?language=en_US
    return currentState != 5 && currentState != 4294967264;
  }

  static bool isCbsPackageInstalled(String packageName) {
    final RegistryKey packageRoot = LOCAL_MACHINE.open(_cbsPackagesRegPath);
    try {
      return packageRoot.keys.where((e) => e.startsWith(packageName)).any(_isPackageKeyInstalled);
    } finally {
      packageRoot.close();
    }
  }

  @override
  Future<ReleaseModel> fetchRelease() => api.fetchLatestRelease();

  @override
  Future<void> downloadAsset({required CabAsset asset, required String filePath}) async {
    await api.downloadFile(url: asset.downloadUrl, filePath: filePath);
    if (!fileExists(filePath)) {
      throw WinSxSPackageDownloadException('Failed to download package: ${asset.name}');
    }
  }

  @override
  void ensureDirectory(String path) {
    Directory(path).createSync(recursive: true);
  }

  @override
  bool fileExists(String path) {
    return File(path).existsSync();
  }

  @override
  void copyFile({required String sourcePath, required String targetPath}) {
    File(sourcePath).copySync(targetPath);
  }

  @override
  String? findBundledPackage(WinPackageType type) {
    try {
      final bundledDir = Directory(bundledPackagesPath);
      if (!bundledDir.existsSync()) {
        logger.w('Bundled packages directory does not exist: $bundledPackagesPath');
        return null;
      }

      final String? packageFile = bundledDir
          .listSync()
          .whereType<File>()
          .map((file) => p.basename(file.path))
          .firstWhereOrNull((name) => isWinPackageFile(name, type, WinRegistryService.cpuArch));

      if (packageFile != null) {
        final String fullPath = p.join(bundledPackagesPath, packageFile);
        logger.i('Found bundled package: $fullPath');
        return fullPath;
      }
    } catch (e, stackTrace) {
      logger.w('Error checking bundled packages', error: e, stackTrace: stackTrace);
    }
    return null;
  }

  @override
  Future<IList<String>> fetchInstalledPackageNames(WinPackageType type) async {
    try {
      final RegistryKey packageRoot = LOCAL_MACHINE.open(_cbsPackagesRegPath);
      try {
        final IList<String> fromRegistry = packageRoot.keys
            .where((k) => k.startsWith(type.packageName))
            .where(_isPackageKeyInstalled)
            .toIList();
        if (fromRegistry.isNotEmpty) return fromRegistry;
      } finally {
        packageRoot.close();
      }
    } catch (e) {
      logger.d('CBS registry lookup unavailable for ${type.packageName}, falling back to DISM', error: e);
    }

    // Fallback: query via DISM PowerShell if registry yields no results
    final ProcessResult result = await runPSCommand(
      'Get-WindowsPackage -Online -PackageName "${type.packageName}*" | Where-Object { \$_.PackageState -eq "Installed" } | Select-Object -ExpandProperty PackageName',
      stdout: true,
      loggerInfoOutput: false,
    );
    return result.stdout
        .toString()
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toIList();
  }

  @override
  Future<String> fetchSignatureUsage(String packagePath) async {
    final ProcessResult result = await runPSCommand(
      '(Get-AuthenticodeSignature -FilePath "$packagePath").SignerCertificate.Extensions.EnhancedKeyUsages.Value',
    );
    return result.stdout.toString().trim();
  }

  @override
  Future<void> addPackage(String packagePath) async {
    WinRegistryService.createKey(
      LOCAL_MACHINE,
      r'Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344',
    );

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await runPSCommand(
      'Add-WindowsPackage -Online -NoRestart -IgnoreCheck -PackagePath "$packagePath"',
    );
  }

  @override
  Future<void> removePackages(WinPackageType type) async {
    final IList<String> installed = await fetchInstalledPackageNames(type);
    for (final name in installed) {
      logger.i('winsxs: Removing package=$name');
      await removePackageByName(name);
    }
  }

  @override
  Future<void> removePackageByName(String packageName) =>
      runPSCommand('Remove-WindowsPackage -Online -NoRestart -PackageName "$packageName"');

  @override
  void deleteTempPackage(String packagePath) {
    if (!p.isWithin(bundledPackagesPath, packagePath)) File(packagePath).deleteSync();
  }

  @override
  bool isPackageInstalled(WinPackageType type) {
    return WinPackageRepositoryImpl.isCbsPackageInstalled(type.packageName);
  }
}
