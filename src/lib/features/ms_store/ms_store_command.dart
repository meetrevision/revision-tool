import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';

import '../../utils.dart';
import 'models/store_download_info.dart';
import 'store_enums.dart';
import 'store_service.dart';

class MSStoreCommand extends Command<void> {
  MSStoreCommand({required this._service}) {
    argParser.addMultiOption(
      'id',
      help: 'The ID of the app to download, e.g. 9WZDNCRFJ3TJ',
    );
    argParser.addOption(
      'ring',
      abbr: 'r',
      defaultsTo: 'Retail',
      allowed: StoreRing.values.map((e) => e.value).toList(),
      help: 'Channel',
    );
    argParser.addOption(
      'download',
      help: 'Download to specified path.',
      defaultsTo: '',
    );
    argParser.addOption(
      'arch',
      abbr: 'a',
      help: 'Filter downloads by following architectures:',
      defaultsTo: 'auto',
      allowed: StoreArch.values.map((e) => e.value).toList(),
    );
  }

  final StoreService _service;

  String get tag => 'MS Store';

  @override
  String get description =>
      '[$name] Downloads and optionally installs free apps from MS Store';

  @override
  String get name => 'msstore-apps';

  @override
  FutureOr<void> run() async {
    final ids = argResults?['id'] as Iterable<String>;
    final ringValue = argResults?['ring'] as String;
    final archValue = argResults?['arch'] as String;
    final download = argResults?['download'] as String?;

    final StoreRing ring = .values.firstWhere((e) => e.value == ringValue);
    final StoreArch arch = .values.firstWhere((e) => e.value == archValue);

    final StorePackagesByProductId packagesByProductId = await _service
        .getPackages(productIds: ids.toSet(), ring: ring, arch: arch)
        .then(
          (result) => result.when(
            success: (value) => value,
            failure: (exception) => throw exception,
          ),
        );

    final Set<StorePackageFileDownload> downloads = await _service
        .download(
          downloadPath: download != null && download.isNotEmpty
              ? download
              : null,
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
          (result) => result.when(
            success: (value) => value,
            failure: (exception) => throw exception,
          ),
        );

    if (download != null && download.isNotEmpty) {
      final String path = File(downloads.first.path).parent.path;

      _service.releaseDownloadLocks();

      stdout.writeln(path);
      exit(0);
    }

    final Map<String, ProcessResult> installResults = await _service
        .install(downloads: downloads)
        .then(
          (result) => result.when(
            success: (value) => value,
            failure: (exception) => throw exception,
          ),
        );

    final List<ProcessResult> failed = installResults.values
        .where((r) => r.exitCode != 0)
        .toList();
    if (failed.isNotEmpty) {
      for (final r in failed) {
        logger.e('$name: Install failed (${r.exitCode}): ${r.stderr}');
      }
      exit(1);
    }

    exit(0);
  }
}
