import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:revitool/utils.dart';

class PlaybookPatchesCommand extends Command<String> {
  static const tag = "Playbook Patches";

  @override
  String get description {
    return '[$tag] A command to apply micro patches to the ReviOS system';
  }

  @override
  String get name => 'playbook-patches';

  PlaybookPatchesCommand() {
    argParser.addCommand('apply');
  }

  @override
  FutureOr<String>? run() async {
    switch (argResults?.command?.name) {
      case 'apply':
        await applyPatches();
        break;
      default:
        logger.e('$name: Unknown command "${argResults?.command?.name}"');
        exit(1);
    }
    exit(0);
  }

  Future<void> applyPatches() async {}
}
