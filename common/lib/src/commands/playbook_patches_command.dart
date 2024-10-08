import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:common/src/services/miscellaneous_service.dart';

class PlaybookPatchesCommand extends Command<String> {
  static final _miscellaneousService = MiscellaneousService();

  static const tag = "[Playbook Patches]";

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
        stdout.writeln('''
Something went wrong. Please try again.
''');
        exit(1);
    }
    exit(0);
  }

  Future<void> applyPatches() async {
    await _miscellaneousService.updateKGL();
  }
}
