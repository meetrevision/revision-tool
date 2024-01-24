import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:revitool/services/msstore_service.dart';

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
  }

  @override
  String get description =>
      "[$name] Downloads and installs free apps from MS Store";

  @override
  String get name => "msstore-apps";

  @override
  FutureOr<String>? run() async {
    final ids = argResults?["id"];
    final ring = argResults?["ring"];

    for (final id in ids) {
      stdout.writeln('[MS Store] Starting process - $id ($ring)');
      try {
        await _msStoreService.startProcess(id, ring);
      } catch (_) {
        stderr.writeln('[MS Store] Failed to get any information for $id');
        exit(1);
      }

      if (_msStoreService.packages.isNotEmpty) {
        stdout.writeln('[MS Store] Downloading $id...');
        final downloadResult = await _msStoreService.downloadPackages(id);

        if (downloadResult.first.statusCode != 200) {
          stderr.writeln('[MS Store] Failed to download $id');
          exit(1);
        }

        stdout.writeln('[MS Store] Installing $id...');
        final installResult = await _msStoreService.installPackages(id);

        if (installResult.first.exitCode != 0) {
          stderr.writeln('[MS Store] Failed to install $id');
          exit(1);
        }

        stdout.writeln('[MS Store] Successfully installed $id');
        // exit(0);
      }
      stderr.writeln('[MS Store] Failed to get any information for $id');
      exit(1);
    }
    exit(0);
  }
}
