import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../../../utils.dart';
import 'utilities_service.dart';

class MiscellaneousCommand extends Command<String> {
  MiscellaneousCommand() {
    argParser.addCommand('hibernate')
      ..addFlag('enable', negatable: false, help: 'Enable hibernation')
      ..addFlag('disable', negatable: false, help: 'Disable hibernation');

    argParser.addCommand('fast-startup')
      ..addFlag('enable', negatable: false, help: 'Enable fast startup')
      ..addFlag('disable', negatable: false, help: 'Disable fast startup');
  }
  static const tag = 'Miscellaneous';
  @override
  String get description => '[$tag] Manage system miscellaneous settings';

  @override
  String get name => 'misc';

  @override
  FutureOr<String>? run() async {
    final ArgResults? command = argResults?.command;
    if (command == null) {
      stderr.writeln('$tag No command specified');
      exit(1);
    }

    switch (command.name) {
      case 'hibernate':
        await _handleHibernate(command);
      case 'fast-startup':
        await _handleFastStartup(command);
      default:
        stderr.writeln('$tag Unknown command: ${command.name}');
        exit(1);
    }
    exit(0);
  }

  Future<void> _handleHibernate(ArgResults command) async {
    if (command['enable'] as bool) {
      await const UtilitiesServiceImpl().enableHibernation();
      logger.i('$name: Hibernation enabled');
    } else if (command['disable'] as bool) {
      await const UtilitiesServiceImpl().disableHibernation();
      logger.i('$name: Hibernation disabled');
    }
  }

  Future<void> _handleFastStartup(ArgResults command) async {
    if (command['enable'] as bool) {
      await const UtilitiesServiceImpl().enableFastStartup();
      logger.i('$name: Fast Startup enabled');
    } else if (command['disable'] as bool) {
      await const UtilitiesServiceImpl().disableFastStartup();
      logger.i('$name: Fast Startup disabled');
    }
  }
}
