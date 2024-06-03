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

  String get tag => "[MS Store]";

  @override
  String get description =>
      "[$name] Downloads and installs free apps from MS Store";

  @override
  String get name => "msstore-apps";

  @override
  FutureOr<String>? run() async {
    final List<String> ids = argResults?["id"];
    final String ring = argResults?["ring"];

    for (final id in ids) {
      stdout.writeln('$tag Starting process - $id ($ring)');
      try {
        await _msStoreService.startProcess(id, ring);
      } catch (_) {
        stderr.writeln('$tag Failed to get any information for $id');
        exit(1);
      }

      if (_msStoreService.packages.isEmpty) {
        stderr.writeln('$tag Failed to get any information for $id');
        exit(1);
      }

      stdout.writeln('$tag Downloading $id...');
      final downloadResult = await _msStoreService.downloadPackages(id, ring);

      if (downloadResult.isEmpty || downloadResult.first.statusCode != 200) {
        stderr.writeln('$tag Failed to download $id');
        exit(1);
      }

      stdout.writeln('$tag Installing $id...');
      final installResult = await _msStoreService.installPackages(id, ring);

      if (installResult.isEmpty || installResult.first.exitCode != 0) {
        stderr.writeln('$tag Failed to install $id');
        exit(1);
      }

      stdout.writeln('$tag Successfully installed $id');

      await _msStoreService.cleanUpDownloads();
    }
    exit(0);
  }
}
