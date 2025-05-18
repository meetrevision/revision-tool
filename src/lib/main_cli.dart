import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:revitool/core/ms_store/ms_store_command.dart';
import 'package:revitool/core/miscellaneous/playbook_patches_command.dart';
import 'package:revitool/core/security/security_command.dart';
import 'package:revitool/core/winsxs/win_package_command.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';

Future<void> main(List<String> args) async {
  if (!WinRegistryService.isSupported && !Directory(ameTemp).existsSync()) {
    logger.i('Unsupported build detected. Please apply ReviOS on your system');
    exit(55);
  }

  if (args.isEmpty) {
    final guiPath =
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\revitoolw.exe";
    if (File(guiPath).existsSync()) {
      await Process.start('revitoolw', []);
      exit(0);
    }
    exit(1);
  }

  logger.i('Revision Tool CLI is starting');

  final runner =
      CommandRunner<String>(
          "revitool",
          "Revision Tool CLI v${const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0')}",
        )
        ..addCommand(MSStoreCommand())
        ..addCommand(SecurityCommand())
        ..addCommand(WindowsPackageCommand())
        ..addCommand(PlaybookPatchesCommand());
  await runner.run(args);
  exit(0);
}
