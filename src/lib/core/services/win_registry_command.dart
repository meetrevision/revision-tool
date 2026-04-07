import 'dart:async';

import 'package:args/command_runner.dart';

import '../../core/services/win_registry_service.dart';
import '../../utils.dart';

// CLI generated but for some reason using `part '.g.dart'` has issues

abstract class _WinRegistryServiceCommandBase extends Command<void> {
  _WinRegistryServiceCommandBase(WinRegistryService service)
    : _service = service;

  final WinRegistryService _service;
}

final class WinRegistryServiceCliCommand
    extends _WinRegistryServiceCommandBase {
  WinRegistryServiceCliCommand(super.service) {
    addSubcommand(_ActionHidePageCommand(_service));
    addSubcommand(_ActionUnhidePageCommand(_service));
  }

  @override
  String get name {
    return 'registry';
  }

  @override
  String get description {
    return 'Windows registry utilities';
  }

  @override
  void run() {
    printUsage();
  }
}

class _ActionHidePageCommand extends _WinRegistryServiceCommandBase {
  _ActionHidePageCommand(super.service) {
    argParser.addOption(
      'value',
      mandatory: true,
      help: 'The value (type: String)',
    );
  }

  @override
  String get name {
    return 'hide-page';
  }

  @override
  String get description {
    return 'Run hide-page action';
  }

  @override
  Future<void> run() async {
    try {
      final valueStr = argResults!['value'] as String;
      final value = valueStr;
      await _service.hideSettingsPage(value);
      logger.i('hide-page completed for: $valueStr');
    } on Exception catch (e, st) {
      logger.e('Failed to run hide-page', error: e, stackTrace: st);
      throw UsageException(e.toString(), usage);
    }
  }
}

class _ActionUnhidePageCommand extends _WinRegistryServiceCommandBase {
  _ActionUnhidePageCommand(super.service) {
    argParser.addOption(
      'value',
      mandatory: true,
      help: 'The value (type: String)',
    );
  }

  @override
  String get name {
    return 'unhide-page';
  }

  @override
  String get description {
    return 'Run unhide-page action';
  }

  @override
  Future<void> run() async {
    try {
      final valueStr = argResults!['value'] as String;
      final value = valueStr;
      await _service.unhideSettingsPage(value);
      logger.i('unhide-page completed for: $valueStr');
    } on Exception catch (e, st) {
      logger.e('Failed to run unhide-page', error: e, stackTrace: st);
      throw UsageException(e.toString(), usage);
    }
  }
}
