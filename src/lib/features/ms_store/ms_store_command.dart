import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';

import 'package:process_run/shell_run.dart';

import '../../utils.dart';
import 'msstore_service.dart';

class MSStoreCommand extends Command<String> {
  MSStoreCommand() {
    argParser.addMultiOption(
      'id',
      help: 'The ID of the app to download, e.g. 9WZDNCRFJ3TJ',
    );
    argParser.addOption(
      'ring',
      abbr: 'r',
      defaultsTo: 'Retail',
      allowed: const ['Retail', 'RP', 'WIS', 'WIF'],
      allowedHelp: const {
        'Retail': 'Retail/stable ring (recommended)',
        'RP': 'Release Preview',
        'WIS': 'Windows Insider Slow',
        'WIF': 'Windows Insider Fast',
      },
      help: 'Channel',
      valueHelp: 'Retail',
    );
    argParser.addFlag(
      'download-only',
      negatable: false,
      help:
          'Only downloads the specified package(s) without installing. Useful for offline installation or manual package management',
    );
    argParser.addOption(
      'arch',
      abbr: 'a',
      help: 'Filter downloads by following architectures:',
      defaultsTo: 'auto',
      allowed: const ['auto', 'x64', 'arm64', 'all'],
      allowedHelp: const {
        'auto': 'Prioritizes neutral and system arch packages',
        'x64': 'Prioritizes x64 and neutral packages',
        'arm64': 'Prioritizes arm64 and neutral packages',
        'all': 'Ignores architecture and downloads all packages',
      },
    );
  }
  static final _msStoreService = MSStoreService();

  String get tag => 'MS Store';

  @override
  String get description =>
      '[$name] Downloads and optionally installs free apps from MS Store';

  @override
  String get name => 'msstore-apps';

  @override
  FutureOr<String>? run() async {
    final ids = argResults?['id'] as List<String>;
    final ring = argResults?['ring'] as String;
    final String arch = argResults?['arch'] as String? ?? 'auto';
    final bool downloadOnly = argResults?['download-only'] as bool? ?? false;

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
    required String ring,
    required String arch,
    required bool downloadOnly,
  }) async {
    logger.i(
      '$name(installPackage): Starting id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
    );
    try {
      await _msStoreService.startProcess(id, ring);
    } catch (e) {
      logger.e(
        '$name(installPackage): Failed to start process for id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
        error: e,
        stackTrace: StackTrace.current,
      );
      exit(1);
    }

    if (_msStoreService.packages.isEmpty) {
      logger.e(
        '$name(installPackage): No packages found for id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
        error: 'No packages found',
        stackTrace: StackTrace.current,
      );
      exit(1);
    }

    logger.i(
      '$name(installPackage): Downloading id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
    );
    final List<Response<dynamic>> downloadResult = await _msStoreService
        .downloadPackages(id, ring, arch);

    if (downloadResult.isEmpty || downloadResult.first.statusCode != 200) {
      logger.e(
        '$name(installPackage): Download failed for id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
        error: 'Download failed',
      );
      exit(1);
    }

    if (downloadOnly) {
      final downloadPath = '${_msStoreService.storeFolder}\\$id\\$ring';
      logger.i(
        '$name(installPackage): Downloaded $id successfully to $downloadPath. downloadOnly=$downloadOnly therefore not installing',
      );
      stdout.writeln(downloadPath);
      return;
    }

    logger.i(
      '$name(installPackage): Installing id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
    );
    final List<ProcessResult> installResult = await _msStoreService
        .installPackages(id, ring);

    var areResultsZero = true;
    for (final e in installResult) {
      if (e.exitCode != 0) {
        logger.e(
          '$name(installPackage): Installation failed for id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly; ${e.outText}',
          error: e.errText,
          stackTrace: StackTrace.current,
        );
        areResultsZero = false;
        break;
      }
    }

    if (installResult.isEmpty || !areResultsZero) {
      logger.e(
        '$name(installPackage): Installation failed for id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
        error: 'Installation failed',
        stackTrace: StackTrace.current,
      );
      exit(1);
    }

    logger.i(
      '$name(installPackage): Successfully installed id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
    );

    if (!downloadOnly) {
      await _msStoreService.cleanUpDownloads();
      logger.i(
        '$name(installPackage): Cleaned up downloads for id=$id, ring=$ring, arch=$arch, downloadOnly=$downloadOnly',
      );
    }
  }
}
