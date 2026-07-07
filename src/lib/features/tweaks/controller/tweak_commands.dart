import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../inventory/tweak_inventory.dart';
import 'tweak_controller.dart';

final class ProfileCommand extends Command<void> {
  ProfileCommand(this._profiles) {
    addSubcommand(_ProfileListCommand());
    addSubcommand(_ProfileApplyCommand(_profiles));
    addSubcommand(_ProfileStatusCommand(_profiles.tweaks));
    addSubcommand(_ProfileRollbackCommand(_profiles));
  }

  final ProfileController _profiles;

  @override
  String get name => 'profile';

  @override
  String get description => 'Apply and inspect optimization profiles';
}

final class TweakCommand extends Command<void> {
  TweakCommand(this._controller) {
    addSubcommand(_TweakListCommand(_controller));
    addSubcommand(_TweakEnableCommand(_controller));
    addSubcommand(_TweakDisableCommand(_controller));
    addSubcommand(_TweakVerifyCommand(_controller));
    addSubcommand(_TweakRollbackCommand(_controller));
  }

  final TweakController _controller;

  @override
  String get name => 'tweak';

  @override
  String get description => 'Apply, verify, and rollback individual tweaks';
}

final class ReportCommand extends Command<void> {
  ReportCommand(this._rollback) {
    argParser
      ..addFlag('last', help: 'Show the last tweak controller report.')
      ..addFlag('json', help: 'Emit JSON output.');
  }

  final RollbackManager _rollback;

  @override
  String get name => 'report';

  @override
  String get description => 'Show tweak controller reports';

  @override
  void run() {
    final ProfileReport? report = _rollback.latestReport();
    if (report == null) {
      _write(argResults?['json'] == true, <String, Object?>{
        'error': 'No tweak controller report is available.',
      });
      return;
    }

    _write(argResults?['json'] == true, report.toJson());
  }
}

final class _ProfileListCommand extends Command<void> {
  @override
  String get name => 'list';

  @override
  String get description => 'List available optimization profiles';

  @override
  void run() {
    for (final OptimizationProfile profile in OptimizationProfile.values) {
      stdout.writeln('${profile.name}\t${profile.displayName}');
    }
  }
}

final class _ProfileApplyCommand extends Command<void> {
  _ProfileApplyCommand(this._profiles) {
    argParser
      ..addFlag('dry-run', help: 'Plan the profile without applying tweaks.')
      ..addFlag('yes', abbr: 'y', help: 'Confirm non-interactive execution.')
      ..addFlag(
        'include-dangerous',
        help: 'Allow dangerous tweaks when paired with --yes.',
      )
      ..addFlag(
        'ignore-overrides',
        help: 'Apply profile tweaks even when manual overrides exist.',
      )
      ..addFlag('json', help: 'Emit JSON output.');
  }

  final ProfileController _profiles;

  @override
  String get name => 'apply';

  @override
  String get description => 'Apply an optimization profile';

  @override
  Future<void> run() async {
    final OptimizationProfile profile = _parseProfile(
      _positional(this, 'profile'),
      usage,
    );
    final ProfileReport report = await _profiles.apply(
      profile,
      ProfileApplyOptions(
        dryRun: argResults!['dry-run'] as bool,
        includeDangerous: argResults!['include-dangerous'] as bool,
        assumeYes: argResults!['yes'] as bool,
        ignoreOverrides: argResults!['ignore-overrides'] as bool,
      ),
    );

    _write(argResults!['json'] as bool, report.toJson());
  }
}

final class _ProfileStatusCommand extends Command<void> {
  _ProfileStatusCommand(this._controller) {
    argParser.addFlag('json', help: 'Emit JSON output.');
  }

  final TweakController _controller;

  @override
  String get name => 'status';

  @override
  String get description => 'Show current tweak status';

  @override
  Future<void> run() async {
    final results = <TweakResult>[];
    for (final TweakDefinition tweak in _controller.tweaks) {
      results.add(await _controller.status(tweak.id));
    }

    final payload = <String, Object?>{
      'results': results.map((TweakResult result) => result.toJson()).toList(),
    };
    _write(argResults!['json'] as bool, payload);
  }
}

final class _ProfileRollbackCommand extends Command<void> {
  _ProfileRollbackCommand(this._profiles) {
    argParser
      ..addFlag('last', help: 'Rollback the last profile report.')
      ..addOption('application', help: 'Rollback a specific application id.')
      ..addFlag('json', help: 'Emit JSON output.');
  }

  final ProfileController _profiles;

  @override
  String get name => 'rollback';

  @override
  String get description => 'Rollback a profile application';

  @override
  Future<void> run() async {
    final last = argResults!['last'] as bool;
    final applicationId = argResults!['application'] as String?;
    if (last && applicationId != null) {
      _write(argResults!['json'] as bool, <String, Object?>{
        'error': 'Use either --last or --application, not both.',
      });
      return;
    }

    final ProfileReport? report = applicationId == null
        ? await _profiles.rollbackLast()
        : await _profiles.rollbackApplication(applicationId);
    if (report == null) {
      _write(argResults!['json'] as bool, <String, Object?>{
        'error': applicationId == null
            ? 'No report is available to rollback.'
            : 'No report is available for application id $applicationId.',
      });
      return;
    }

    _write(argResults!['json'] as bool, report.toJson());
  }
}

final class _TweakListCommand extends Command<void> {
  _TweakListCommand(this._controller) {
    argParser
      ..addOption('profile', help: 'Filter by profile name.')
      ..addOption('category', help: 'Filter by category name.')
      ..addOption('risk', help: 'Filter by risk name.')
      ..addFlag('json', help: 'Emit JSON output.');
  }

  final TweakController _controller;

  @override
  String get name => 'list';

  @override
  String get description => 'List known tweaks';

  @override
  void run() {
    final OptimizationProfile? profile = _optionalProfile(
      argResults!['profile'] as String?,
      usage,
    );
    final TweakCategory? category = _optionalCategory(
      argResults!['category'] as String?,
      usage,
    );
    final TweakRisk? risk = _optionalRisk(
      argResults!['risk'] as String?,
      usage,
    );

    final List<TweakDefinition> tweaks = _controller.tweaks
        .where(
          (TweakDefinition tweak) =>
              (profile == null || tweak.profiles.contains(profile)) &&
              (category == null || tweak.category == category) &&
              (risk == null || tweak.risk == risk),
        )
        .toList(growable: false);

    final List<Map<String, Object?>> payload = tweaks
        .map(_tweakToJson)
        .toList(growable: false);
    if (argResults!['json'] as bool) {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    for (final tweak in tweaks) {
      stdout.writeln(
        '${tweak.id}\t${tweak.risk.name}\t${tweak.category.name}\t${tweak.name}',
      );
    }
  }
}

final class _TweakEnableCommand extends Command<void> {
  _TweakEnableCommand(this._controller) {
    argParser
      ..addFlag('dry-run', help: 'Plan the tweak without applying it.')
      ..addFlag('yes', abbr: 'y', help: 'Confirm non-interactive execution.')
      ..addFlag(
        'include-dangerous',
        help: 'Allow dangerous tweaks when paired with --yes.',
      )
      ..addFlag('json', help: 'Emit JSON output.');
  }

  final TweakController _controller;

  @override
  String get name => 'enable';

  @override
  String get description => 'Enable an optimization tweak';

  @override
  Future<void> run() async {
    final TweakResult result = await _controller.enable(
      _positional(this, 'id'),
      TweakExecutionOptions(
        dryRun: argResults!['dry-run'] as bool,
        includeDangerous: argResults!['include-dangerous'] as bool,
        assumeYes: argResults!['yes'] as bool,
      ),
    );
    _write(argResults!['json'] as bool, result.toJson());
  }
}

final class _TweakDisableCommand extends Command<void> {
  _TweakDisableCommand(this._controller) {
    argParser
      ..addFlag('dry-run', help: 'Plan the rollback without applying it.')
      ..addFlag('json', help: 'Emit JSON output.');
  }

  final TweakController _controller;

  @override
  String get name => 'disable';

  @override
  String get description => 'Rollback an optimization tweak';

  @override
  Future<void> run() async {
    final TweakResult result = await _controller.disable(
      _positional(this, 'id'),
      TweakExecutionOptions(dryRun: argResults!['dry-run'] as bool),
    );
    _write(argResults!['json'] as bool, result.toJson());
  }
}

final class _TweakVerifyCommand extends Command<void> {
  _TweakVerifyCommand(this._controller) {
    argParser.addFlag('json', help: 'Emit JSON output.');
  }

  final TweakController _controller;

  @override
  String get name => 'verify';

  @override
  String get description => 'Verify an optimization tweak';

  @override
  Future<void> run() async {
    final TweakResult result = await _controller.verify(
      _positional(this, 'id'),
    );
    _write(argResults!['json'] as bool, result.toJson());
  }
}

final class _TweakRollbackCommand extends Command<void> {
  _TweakRollbackCommand(this._controller) {
    argParser.addFlag('json', help: 'Emit JSON output.');
  }

  final TweakController _controller;

  @override
  String get name => 'rollback';

  @override
  String get description => 'Rollback an optimization tweak';

  @override
  Future<void> run() async {
    final TweakResult result = await _controller.rollback(
      _positional(this, 'id'),
    );
    _write(argResults!['json'] as bool, result.toJson());
  }
}

String _positional(Command<void> command, String label) {
  final List<String> rest = command.argResults!.rest;
  if (rest.isEmpty) {
    throw UsageException('Missing <$label>.', command.usage);
  }
  return rest.first;
}

OptimizationProfile _parseProfile(String name, String usage) {
  final OptimizationProfile? profile = _optionalProfile(name, usage);
  if (profile == null) {
    throw UsageException(
      'Unknown profile "$name". Expected one of: ${OptimizationProfile.values.map((p) => p.name).join(', ')}.',
      usage,
    );
  }
  return profile;
}

OptimizationProfile? _optionalProfile(String? name, String usage) {
  if (name == null) return null;
  for (final OptimizationProfile profile in OptimizationProfile.values) {
    if (profile.name == name) return profile;
  }
  throw UsageException('Unknown profile "$name".', usage);
}

TweakCategory? _optionalCategory(String? name, String usage) {
  if (name == null) return null;
  for (final TweakCategory category in TweakCategory.values) {
    if (category.name == name) return category;
  }
  throw UsageException('Unknown category "$name".', usage);
}

TweakRisk? _optionalRisk(String? name, String usage) {
  if (name == null) return null;
  for (final TweakRisk risk in TweakRisk.values) {
    if (risk.name == name) return risk;
  }
  throw UsageException('Unknown risk "$name".', usage);
}

Map<String, Object?> _tweakToJson(TweakDefinition tweak) {
  return <String, Object?>{
    'id': tweak.id,
    'name': tweak.name,
    'category': tweak.category.name,
    'risk': tweak.risk.name,
    'profiles': tweak.profiles.map((OptimizationProfile p) => p.name).toList(),
    'reason': tweak.reason,
    'warnings': tweak.warnings,
  };
}

void _write(bool json, Map<String, Object?> payload) {
  if (json) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(payload));
    return;
  }

  if (payload['results'] case final List<Object?> results) {
    for (final item in results) {
      if (item is Map<String, Object?>) {
        stdout.writeln(_summaryLine(item));
      }
    }
    return;
  }

  stdout.writeln(_summaryLine(payload));
}

String _summaryLine(Map<String, Object?> item) {
  final Object id = item['id'] ?? item['applicationId'] ?? 'report';
  final Object state = item['state'] ?? item['profile'] ?? '';
  final Object reason = item['reason'] ?? item['error'] ?? '';
  return [
    id,
    state,
    reason,
  ].where((Object value) => value.toString().isNotEmpty).join('\t');
}
