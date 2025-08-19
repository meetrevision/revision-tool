import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:revitool/core/miscellaneous/miscellaneous_service.dart';
import 'package:revitool/utils.dart';

class MiscellaneousCommand extends Command<String> {
  static const tag = "Miscellaneous";
  final _miscService = MiscellaneousService();

  @override
  String get description => '[$tag] Manage system miscellaneous settings';

  @override
  String get name => 'misc';

  MiscellaneousCommand() {
    argParser.addCommand('hibernate')
      ..addFlag('enable', negatable: false, help: 'Enable hibernation')
      ..addFlag('disable', negatable: false, help: 'Disable hibernation');

    argParser.addCommand('fast-startup')
      ..addFlag('enable', negatable: false, help: 'Enable fast startup')
      ..addFlag('disable', negatable: false, help: 'Disable fast startup');
  }

  @override
  FutureOr<String>? run() async {
    final command = argResults?.command;
    if (command == null) {
      stderr.writeln('$tag No command specified');
      exit(1);
    }

    switch (command.name) {
      case 'hibernate':
        await _handleHibernate(command);
        break;
      case 'fast-startup':
        await _handleFastStartup(command);
        break;
      default:
        stderr.writeln('$tag Unknown command: ${command.name}');
        exit(1);
    }
    exit(0);
  }

  Future<void> _handleHibernate(ArgResults command) async {
    if (command['enable']) {
      await _miscService.enableHibernation();
      logger.i('$name: Hibernation enabled');
    } else if (command['disable']) {
      await _miscService.disableHibernation();
      logger.i('$name: Hibernation disabled');
    }
  }

  Future<void> _handleFastStartup(ArgResults command) async {
    if (command['enable']) {
      _miscService.enableFastStartup();
      logger.i('$name: Fast Startup enabled');
    } else if (command['disable']) {
      _miscService.disableFastStartup();
      logger.i('$name: Fast Startup disabled');
    }
  }
}
