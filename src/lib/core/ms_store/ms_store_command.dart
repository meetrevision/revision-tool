import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/core/ms_store/msstore_service.dart';

class MSStoreCommand extends Command<String> {
  static final _msStoreService = MSStoreService();

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
      defaultsTo: false,
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

  String get tag => "[MS Store]";
  @override
  String get description =>
      "[$name] Downloads and optionally installs free apps from MS Store";

  @override
  String get name => "msstore-apps";

  @override
  FutureOr<String>? run() async {
    final List<String> ids = argResults?["id"];
    final String ring = argResults?["ring"];
    final String arch = argResults?["arch"] ?? "auto";
    final bool downloadOnly = argResults?["download-only"] ?? false;

    for (final id in ids) {
      stdout.writeln('$tag Starting process - $id ($ring)');
      try {
        await _msStoreService.startProcess(id, ring);
      } catch (e) {
        stderr.writeln(e.toString());
        stderr.writeln('$tag Failed to get any information for $id');
        exit(1);
      }

      if (_msStoreService.packages.isEmpty) {
        stderr.writeln('$tag Failed to get any information for $id');
        exit(1);
      }

      stdout.writeln('$tag Downloading $id...');
      final downloadResult = await _msStoreService.downloadPackages(
        id,
        ring,
        arch,
      );

      if (downloadResult.isEmpty || downloadResult.first.statusCode != 200) {
        stderr.writeln('$tag Failed to download $id');
        exit(1);
      }

      if (downloadOnly) {
        final downloadPath = "${_msStoreService.storeFolder}\\$id\\$ring";
        stdout.writeln('$tag Downloaded $id successfully');
        stdout.writeln(downloadPath);
        continue;
      }

      stdout.writeln('$tag Installing $id...');
      final installResult = await _msStoreService.installPackages(id, ring);

      bool areResultsZero = true;
      for (final e in installResult) {
        if (e.exitCode != 0) {
          stderr.writeln(e.errText);
          stdout.writeln(e.outText);
          areResultsZero = false;
          break;
        }
      }

      if (installResult.isEmpty || !areResultsZero) {
        stderr.writeln('$tag Failed to install $id');
        exit(1);
      }
      stdout.writeln('$tag Successfully installed $id');

      if (!downloadOnly) {
        await _msStoreService.cleanUpDownloads();
      }
    }
    exit(0);
  }
}
