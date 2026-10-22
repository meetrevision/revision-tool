import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../../core/services/win_registry_service.dart';
import '../../utils.dart';

// CLI generated but for some reason using `part '.g.dart'` has issues

abstract class _WinRegistryServiceCommandBase(final WinRegistryService _service)
    extends Command<void>;

final class WinRegistryServiceCliCommand(super.service) extends _WinRegistryServiceCommandBase {
  this {
    addSubcommand(_ActionHidePageCommand(_service));
    addSubcommand(_ActionUnhidePageCommand(_service));
    addSubcommand(_FeatureCommand());
  }

  @override
  String get name => 'registry';

  @override
  String get description => 'Windows registry utilities';

  @override
  void run() => printUsage();

  static Set<int> parseFeatureIds(ArgResults? argResults, String usage) {
    final rawTokens = <String>[...?argResults?.multiOption('id'), ...?argResults?.rest];

    final ids = <int>{};
    for (final token in rawTokens) {
      for (final String part in token.split(',')) {
        final String trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final int? id = .tryParse(trimmed);
        if (id == null) {
          throw UsageException('Invalid Windows feature ID: $trimmed', usage);
        }
        ids.add(id);
      }
    }

    if (ids.isEmpty) {
      throw UsageException(
        'Provide at least one Windows feature ID via --id option or positional argument.',
        usage,
      );
    }

    return ids;
  }
}

final class _FeatureCommand() extends Command<void> {
  this {
    addSubcommand(_FeatureOverrideCommand(.enable));
    addSubcommand(_FeatureOverrideCommand(.disable));
    addSubcommand(_FeatureOverrideCommand(.reset));
  }

  @override
  String get name => 'feature';

  @override
  List<String> get aliases => const ['features'];

  @override
  String get description => 'Manage Windows feature overrides';

  @override
  void run() => printUsage();
}

enum _FeatureOverrideAction() {
  enable,
  disable,
  reset;

  String get description => switch (this) {
    .enable => 'Enable a Windows feature override',
    .disable => 'Disable a Windows feature override',
    .reset => 'Reset a Windows feature override to defaults',
  };

  String get pastTense => switch (this) {
    .enable => 'enabled',
    .disable => 'disabled',
    .reset => 'reset',
  };
}

final class _FeatureOverrideCommand(final _FeatureOverrideAction _action) extends Command<void> {
  this {
    argParser.addMultiOption(
      'id',
      abbr: 'i',
      help: 'Windows feature ID(s) (comma-separated or specified multiple times).',
    );
  }

  @override
  String get name => _action.name;

  @override
  String get description => _action.description;

  @override
  Future<void> run() async {
    final Set<int> featureIds = WinRegistryServiceCliCommand.parseFeatureIds(argResults, usage);

    try {
      await switch (_action) {
        .enable => WinRegistryService.enableFeatures(featureIds),
        .disable => WinRegistryService.disableFeatures(featureIds),
        .reset => WinRegistryService.resetFeatures(featureIds),
      };
      for (final featureId in featureIds) {
        logger.i('Windows feature $featureId ${_action.pastTense}');

      }
    } on Exception catch (e, st) {
      logger.e('Failed to ${_action.name} Windows features', error: e, stackTrace: st);
      throw UsageException(e.toString(), usage);
    }
  }
}

final class _ActionHidePageCommand(super.service) extends _WinRegistryServiceCommandBase {
  this {
    argParser.addOption('value', mandatory: true, help: 'The value (type: String)');
  }

  @override
  String get name => 'hide-page';

  @override
  String get description => 'Run hide-page action';

  @override
  Future<void> run() async {
    try {
      final valueStr = argResults!['value'] as String;
      await _service.hideSettingsPage(valueStr);
      logger.i('hide-page completed for: $valueStr');
    } on Exception catch (e, st) {
      logger.e('Failed to run hide-page', error: e, stackTrace: st);
      throw UsageException(e.toString(), usage);
    }
  }
}

final class _ActionUnhidePageCommand(super.service) extends _WinRegistryServiceCommandBase {
  this {
    argParser.addOption('value', mandatory: true, help: 'The value (type: String)');
  }

  @override
  String get name => 'unhide-page';

  @override
  String get description => 'Run unhide-page action';

  @override
  Future<void> run() async {
    try {
      final valueStr = argResults!['value'] as String;
      await _service.unhideSettingsPage(valueStr);
      logger.i('unhide-page completed for: $valueStr');
    } on Exception catch (e, st) {
      logger.e('Failed to run unhide-page', error: e, stackTrace: st);
      throw UsageException(e.toString(), usage);
    }
  }
}
