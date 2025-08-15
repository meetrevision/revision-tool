import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:revitool/core/miscellaneous/miscellaneous_service.dart';

class MiscellaneousCommand extends Command<String> {
  static const tag = "[Miscellaneous]";
  final _miscService = MiscellaneousService();

  @override
  String get description => '[$tag] Manage system miscellaneous settings';

  @override
  String get name => 'misc';

  MiscellaneousCommand() {
    argParser.addCommand('hibernate')
      ..addFlag('enable', negatable: false, help: 'Enable hibernation')
      ..addFlag('disable', negatable: false, help: 'Disable hibernation')
      ..addFlag('status', negatable: false, help: 'Show hibernation status');

    argParser.addCommand('fast-startup')
      ..addFlag('enable', negatable: false, help: 'Enable fast startup')
      ..addFlag('disable', negatable: false, help: 'Disable fast startup')
      ..addFlag('status', negatable: false, help: 'Show fast startup status');
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
    if (command['status']) {
      final status = _miscService.statusHibernation;
      stdout.writeln('$tag Hibernation is ${status ? "enabled" : "disabled"}');
      return;
    }

    if (command['enable']) {
      stdout.writeln('$tag Enabling hibernation...');
      await _miscService.enableHibernation();
      stdout.writeln('$tag Hibernation enabled');
    } else if (command['disable']) {
      stdout.writeln('$tag Disabling hibernation...');
      await _miscService.disableHibernation();
      stdout.writeln('$tag Hibernation disabled');
    }
  }

  Future<void> _handleFastStartup(ArgResults command) async {
    if (command['status']) {
      final status = _miscService.statusFastStartup;
      stdout.writeln('$tag Fast Startup is ${status ? "enabled" : "disabled"}');
      return;
    }

    if (command['enable']) {
      stdout.writeln('$tag Enabling Fast Startup...');
      _miscService.enableFastStartup();
      stdout.writeln('$tag Fast Startup enabled');
    } else if (command['disable']) {
      stdout.writeln('$tag Disabling Fast Startup...');
      _miscService.disableFastStartup();
      stdout.writeln('$tag Fast Startup disabled');
    }
  }
}
