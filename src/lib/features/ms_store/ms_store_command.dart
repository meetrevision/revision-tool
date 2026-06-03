import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';

import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import 'models/package_info.dart';
import 'ms_store_enums.dart';
import 'ms_store_repository.dart';
import 'services/ms_store_product_details_service.dart';
import 'services/package_file_service.dart';

class MSStoreCommand extends Command<void> {
  MSStoreCommand() {
    argParser.addMultiOption(
      'id',
      help: 'The ID of the app to download, e.g. 9WZDNCRFJ3TJ',
    );
    argParser.addOption(
      'ring',
      abbr: 'r',
      defaultsTo: 'Retail',
      allowed: MSStoreRing.values.map((e) => e.value).toList(),
      help: 'Channel',
    );
    argParser.addFlag(
      'download-only',
      negatable: false,
      help: 'Only downloads the specified package(s) without installing.',
    );
    argParser.addOption(
      'arch',
      abbr: 'a',
      help: 'Filter downloads by following architectures:',
      defaultsTo: 'auto',
      allowed: MSStoreArch.values.map((e) => e.value).toList(),
    );
  }

  late final ApiClient _api = ApiClient();
  late final PackageFileService _fileService = PackageFileService(_api);
  late final MSStoreProductDetailsService _detailsService =
      MSStoreProductDetailsService(_api);
  late final MSStoreRepository _repository = MSStoreRepositoryImpl(
    uwpService: .new(_api),
    searchService: .new(_api),
    detailsService: _detailsService,
    xmlParser: const .new(),
    fileService: _fileService,
    installerService: .new(_fileService),
    win32PackageService: .new(
      api: _api,
      detailsService: _detailsService,
      xmlParser: const .new(),
    ),
  );

  String get tag => 'MS Store';

  @override
  String get description =>
      '[$name] Downloads and optionally installs free apps from MS Store';

  @override
  String get name => 'msstore-apps';

  @override
  FutureOr<void> run() async {
    final ids = argResults?['id'] as List<String>;
    final ringValue = argResults?['ring'] as String;
    final archValue = argResults?['arch'] as String;
    final bool downloadOnly = argResults?['download-only'] as bool? ?? false;

    final MSStoreRing ring = .values.firstWhere((e) => e.value == ringValue);
    final MSStoreArch arch = .values.firstWhere((e) => e.value == archValue);

    for (final id in ids) {
      await installPackage(
        id: id,
        ring: ring,
        arch: arch,
        downloadOnly: downloadOnly,
      );
    }
    exit(0);
  }

  Future<void> installPackage({
    required String id,
    required MSStoreRing ring,
    required MSStoreArch arch,
    required bool downloadOnly,
  }) async {
    logger.i(
      '$name: Starting for id=$id, ring=${ring.label}, arch=${arch.value}',
    );

    try {
      final Result<Set<PackageInfo>> packagesResult = await _repository
          .getPackages(productId: id, ring: ring);
      final Set<PackageInfo> packages = packagesResult.when(
        success: (value) => value,
        failure: (exception) => throw exception,
      );
      if (packages.isEmpty) {
        logger.e('$name: No packages found for id=$id');
        exit(1);
      }

      String resolvedArch = arch.value;
      if (arch == .auto) {
        resolvedArch = WinRegistryService.cpuArch == 'amd64' ? 'x64' : 'arm64';
      }

      final List<PackageInfo> filtered = packages
          .where(
            (p) =>
                arch == .all || p.arch == resolvedArch || p.arch == 'neutral',
          )
          .toList();

      if (filtered.isEmpty) {
        logger.e(
          '$name: No matching packages found for id=$id and arch=$resolvedArch',
        );
        exit(1);
      }

      logger.i('$name: Downloading ${filtered.length} packages for $id...');
      final Result<void> downloadResult = await _repository.downloadPackages(
        productId: id,
        ring: ring,
        packages: filtered,
        cancelToken: CancelToken(),
        onProgress: (fileName, progress) {
          stdout.write(
            '\rDownloading $fileName: ${(progress * 100).toStringAsFixed(1)}%',
          );
          if (progress >= 1.0) stdout.writeln();
        },
      );
      downloadResult.when(
        success: (_) {},
        failure: (exception) => throw exception,
      );

      if (downloadOnly) {
        // Find temp path via internal knowledge (or we could expose it in repository)
        final String path = _fileService.getTempPath(id, ring);
        logger.i('$name: Downloaded successfully to $path');
        stdout.writeln(path);
        return;
      }

      logger.i('$name: Installing packages for $id...');
      final List<ProcessResult> results = await _repository.installPackages(
        productId: id,
        ring: ring,
      );

      final List<ProcessResult> failed = results
          .where((r) => r.exitCode != 0)
          .toList();
      if (failed.isNotEmpty) {
        for (final r in failed) {
          logger.e('$name: Installation failed: ${r.stderr}');
        }
        exit(1);
      }

      logger.i('$name: Successfully installed $id');
      await _repository.cleanup();
    } catch (e) {
      logger.e('$name: Failed to process $id', error: e);
      exit(1);
    }
  }
}
