import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:revitool/services/registry_utils_service.dart';
import 'package:revitool/services/updates_service.dart';
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

  Future<void> applyPatches() async {
    // remove 'OneDrive' from explorer TODO: Remove this section after a new PB is released
    RegistryUtilsService.writeDword(
        Registry.classesRoot,
        r'CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}',
        'System.IsPinnedToNameSpaceTree',
        0);

    // After July 2024 Windows updates, modifying 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' seems to crash the process of applying playbook
    _updatesService.enablePauseUpdatesWU();
  }
}
