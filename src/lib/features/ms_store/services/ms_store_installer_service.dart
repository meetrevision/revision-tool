import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../../../utils.dart';
import '../models/package_info.dart';
import '../ms_store_enums.dart';
import 'package_file_service.dart';

/// Service responsible for installing MS Store packages.
class MSStoreInstallerService {
  const MSStoreInstallerService(this._fileService);

  final PackageFileService _fileService;

  /// Installs downloaded packages and returns installation results.
  Future<List<ProcessResult>> installPackages({
    required String productId,
    required MSStoreRing ring,
    required MSStoreAppType appType,
    required Set<PackageInfo>? cachedPackages,
  }) async {
    final List<File> files = _fileService.listDownloadedFiles(productId, ring);
    if (files.isEmpty) return [];

    if (appType == .uwp) {
      return _installUwpPackages(productId, ring, files, cachedPackages);
    } else {
      return _installWin32Packages(files, cachedPackages);
    }
  }

  /// Installs UWP packages (dependencies first, then main packages).
  Future<List<ProcessResult>> _installUwpPackages(
    String productId,
    MSStoreRing ring,
    List<File> files,
    Set<PackageInfo>? cachedPackages,
  ) async {
    final results = <ProcessResult>[];
    final String basePath = _fileService.getTempPath(productId, ring);
    final baseDir = Directory(basePath);
    final depsDir = Directory('$basePath\\Dependencies');

    // Install dependencies first if they exist
    if (depsDir.existsSync()) {
      final Iterable<File> deps = depsDir.listSync().whereType<File>();
      for (final file in deps) {
        final String fileName = p.basenameWithoutExtension(file.path);
        final String fileHash = await _fileService.computeFileSha256(file);

        final PackageInfo? matchedPkg = cachedPackages?.firstWhereOrNull(
          (pkg) => pkg.fileModel?.digest == fileHash,
        );

        if (matchedPkg != null) {
          logger.i('Hash verified for dependency: $fileName');
        } else {
          logger.w('Hash verification failed for dependency: $fileName');
        }

        results.add(await _fileService.runAppxInstall(file.path));
      }
    }

    // Install main packages
    final Iterable<File> mainFiles = baseDir.listSync().whereType<File>().where(
      (f) => !f.path.contains('Dependencies'),
    );

    for (final file in mainFiles) {
      final String fileName = p.basenameWithoutExtension(file.path);
      final String fileHash = await _fileService.computeFileSha256(file);

      final PackageInfo? matchedPkg = cachedPackages?.firstWhereOrNull(
        (pkg) => pkg.fileModel?.digest == fileHash,
      );

      if (matchedPkg != null) {
        logger.i('Hash verified for package: $fileName');
      } else {
        logger.w('Hash verification failed for package: $fileName');
      }

      results.add(await _fileService.runAppxInstall(file.path));
    }

    return results;
  }

  /// Installs Win32 packages (exe/msi).
  Future<List<ProcessResult>> _installWin32Packages(
    List<File> files,
    Set<PackageInfo>? cachedPackages,
  ) async {
    final results = <ProcessResult>[];

    for (final file in files) {
      final String fileName = p.basenameWithoutExtension(file.path);
      final String fileHash = await _fileService.computeFileSha256(file);

      final PackageInfo? matchedPkg = cachedPackages?.firstWhereOrNull(
        (pkg) => pkg.fileModel?.digest == fileHash,
      );

      if (matchedPkg != null) {
        logger.i('Matched package by digest for $fileName');
      }

      final List<String> arguments =
          matchedPkg?.commandLines?.split(' ') ?? List<String>.empty();

      results.add(await _fileService.runWin32Install(file.path, arguments));
    }

    return results;
  }
}
