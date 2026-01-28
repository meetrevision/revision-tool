import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../../core/services/win_registry_service.dart';
import '../../../utils.dart';

class PlaybookPatchesCommand extends Command<String> {

  PlaybookPatchesCommand() {
    argParser.addCommand('apply');
  }
  static const tag = 'Playbook Patches';

  @override
  String get description {
    return '[$tag] A command to apply micro patches to the ReviOS system';
  }

  @override
  String get name => 'playbook-patches';

  @override
  FutureOr<String>? run() async {
    switch (argResults?.command?.name) {
      case 'apply':
        await applyPatches();
      default:
        logger.e('$name: Unknown command "${argResults?.command?.name}"');
        exit(1);
    }
    exit(0);
  }

  Future<void> applyPatches() async {
    logger.i('$name: Applying patches...');
    // Disable WebView2 spawning from SearchHost
    // https://www.reddit.com/r/WindowsHelp/comments/1lfu325/comment/n2nk50h
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\8\1694661260',
      'EnabledState',
      1,
    );
  }
}
