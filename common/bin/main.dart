import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:common/common.dart';

Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    if (!WinRegistryService.isSupported || !Directory(ameTemp).existsSync()) {
      logger.i(
        'Unsupported build detected. Please apply ReviOS on your system',
      );
      exit(55);
    }
    final vers =
        const String.fromEnvironment("APP_VERSION").replaceAll(".", "");
    stdout.writeln("Running Revision Tool $vers");
    final runner = CommandRunner<String>("revitool", "Revision Tool CLI")
      ..addCommand(MSStoreCommand())
      ..addCommand(DefenderCommand())
      ..addCommand(WindowsPackageCommand())
      ..addCommand(PlaybookPatchesCommand());
    // ..addCommand(RecommendationCommand());
    await runner.run(args);
    exit(0);
  }
}
