import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import 'models/store_download_info.dart';
import 'store_enums.dart';
import 'store_service.dart';

class MSStoreCommand({required final StoreService _service}) extends Command<void> {
  this {
    argParser.addMultiOption('id', help: 'The ID of the app to download, e.g. 9WZDNCRFJ3TJ');
    argParser.addOption(
      'ring',
      abbr: 'r',
      defaultsTo: 'Retail',
      allowed: StoreRing.values.map((e) => e.value).toList(),
      help: 'Channel',
    );
    argParser.addOption('download', help: 'Download to specified path.', defaultsTo: '');
    argParser.addOption(
      'arch',
      abbr: 'a',
      help: 'Filter downloads by following architectures:',
      defaultsTo: 'auto',
      allowed: StoreArch.values.map((e) => e.value).toList(),
    );
  }

  /// VCLibs frameworks shipped under [bundledPackagesPath].
  static const bundledProductIds = {'9NBLGGH3FRZM', '9NBLGGH4RV3K'};

  static final String bundledPackagesPath = p.join(directoryExe, 'packages', 'appx');

  String get tag => 'MS Store';

  @override
  String get description => '[$name] Downloads and optionally installs free apps from MS Store';

  @override
  String get name => 'msstore-apps';

  @override
  FutureOr<void> run() async {
    final Set<String> ids = (argResults?['id'] as Iterable<String>)
        .map((id) => id.toUpperCase())
        .toSet();
    final ringValue = argResults?['ring'] as String;
    final archValue = argResults?['arch'] as String;
    final download = argResults?['download'] as String?;

    final StoreRing ring = .values.firstWhere((e) => e.value == ringValue);
    final StoreArch arch = .values.firstWhere((e) => e.value == archValue);
    final bool downloadOnly = download != null && download.isNotEmpty;

    try {
      final StorePackagesByProductId packagesByProductId = await _service
          .getPackages(productIds: ids, ring: ring, arch: arch)
          .then(
            (result) =>
                result.when(success: (value) => value, failure: (exception) => throw exception),
          );

      final Set<StorePackageFileDownload> downloads = await _service
          .download(
            downloadPath: downloadOnly ? download : null,
            ring: ring,
            packagesByProductId: packagesByProductId,
            cancelToken: CancelToken(),
            onProgress: (progress) {
              stdout.write(
                '\rDownloading ${progress.fileName}: ${(progress.fileProgress * 100).toStringAsFixed(1)}%',
              );
              if (progress.fileProgress >= 1.0) stdout.writeln();
            },
          )
          .then(
            (result) =>
                result.when(success: (value) => value, failure: (exception) => throw exception),
          );

      if (downloadOnly) {
        final String path = File(downloads.first.path).parent.path;
        _service.releaseDownloadLocks();
        stdout.writeln(path);
        exit(0);
      }

      final Map<String, ProcessResult> installResults = await _service
          .install(downloads: downloads)
          .then(
            (result) =>
                result.when(success: (value) => value, failure: (exception) => throw exception),
          );

      final List<ProcessResult> failed = installResults.values
          .where((r) => r.exitCode != 0)
          .toList();
      if (failed.isNotEmpty) {
        throw Exception(failed.map((r) => r.stderr).join('\n'));
      }
    } catch (e, st) {
      if (downloadOnly || !ids.every(bundledProductIds.contains)) rethrow;
      logger.w('$name: Store failed, installing bundled appx', error: e, stackTrace: st);
      await _installBundled(arch: arch);
    }

    exit(0);
  }

  Future<void> _installBundled({required StoreArch arch}) async {
    final dir = Directory(bundledPackagesPath);
    if (!dir.existsSync()) {
      throw Exception('Bundled AppX directory missing: $bundledPackagesPath');
    }

    final String resolvedArch = arch == .auto
        ? (WinRegistryService.cpuArch == 'amd64' ? 'x64' : 'arm64')
        : arch.value;

    final List<File> files = dir.listSync().whereType<File>().where((f) {
      final String name = p.basename(f.path).toLowerCase();

      if (!name.endsWith('.appx') && !name.endsWith('.msix')) return false;
      if (arch == .all) return true;

      if (name.contains('_neutral_') || name.contains('_${resolvedArch}_')) return true;
      if (resolvedArch == 'x64' && name.contains('_x86_')) return true;
      if (resolvedArch == 'arm64' && name.contains('_arm_')) return true;
      return false;
    }).toList();

    if (files.isEmpty) {
      throw Exception('No bundled AppX packages found in $bundledPackagesPath');
    }

    for (final file in files) {
      logger.i('$name: Installing bundled ${p.basename(file.path)}');
      final ProcessResult result = await runPSCommand(
        'Add-AppxPackage -Path "${file.path}" -ForceApplicationShutdown',
      );
      if (result.exitCode != 0) {
        throw Exception('Bundled AppX install failed (${result.exitCode}): ${result.stderr}');
      }
    }
  }
}
