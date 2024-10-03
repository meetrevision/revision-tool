import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:common/common.dart';

import 'package:win32_registry/win32_registry.dart';

class PlaybookPatchesCommand extends Command<String> {
  static final _updatesService = UpdatesService();

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

  Future<void> applyPatches() async {}
}
