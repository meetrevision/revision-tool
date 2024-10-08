import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:common/common.dart';

Future<void> main(List<String> args) async {
  if (!WinRegistryService.isSupported && !Directory(ameTemp).existsSync()) {
    logger.i('Unsupported build detected. Please apply ReviOS on your system');
    exit(55);
  }

  if (args.isEmpty) {
    final guiPath =
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\revitoolw.exe";
    if (await File(guiPath).exists()) {
      await Process.start('revitoolw', []);
      exit(0);
    }
    exit(1);
  }

  logger.i('Revision Tool CLI is starting');

  final runner = CommandRunner<String>("revitool",
      "Revision Tool CLI v${const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}")
    ..addCommand(MSStoreCommand())
    ..addCommand(DefenderCommand())
    ..addCommand(WindowsPackageCommand())
    ..addCommand(PlaybookPatchesCommand());
  // ..addCommand(RecommendationCommand());
  await runner.run(args);
  exit(0);
}
