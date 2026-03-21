import 'dart:io';

import 'package:args/command_runner.dart';

import 'core/services/win_registry_service.dart';
import 'features/ms_store/ms_store_command.dart';
import 'features/tweaks/tweaks_command.dart';
import 'features/winsxs/win_package_command.dart';
import 'utils.dart';

Future<void> main(List<String> args) async {
  if (!WinRegistryService.isSupported && !Directory(ameTemp).existsSync()) {
    logger.i('Unsupported build detected. Please apply ReviOS on your system');
    exit(55);
  }

  if (args.isEmpty) {
    final guiPath =
        "${mainPath.substring(0, mainPath.lastIndexOf(r"\"))}\\revitoolw.exe";
    if (File(guiPath).existsSync()) {
      await Process.start('revitoolw', []);
      exit(0);
    }
    exit(1);
  }
  const tag = 'cli_main:';

  logger.i('$tag Revision Tool CLI is starting');

  final runner =
      CommandRunner<void>(
          'revitool',
          "Revision Tool CLI v${const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}",
        )
        ..addCommand(MSStoreCommand())
        ..addCommand(TweaksCommand())
        ..addCommand(WindowsPackageCommand());
  await runner.run(args);
  exit(0);
}
