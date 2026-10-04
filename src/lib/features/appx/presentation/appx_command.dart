import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../utils.dart';
import '../domain/appx_exceptions.dart';
import '../domain/appx_service.dart';
import '../domain/entities/appx_package.dart';
import 'appx_providers.dart';

/// Exit codes for the `appx` CLI command.
const int appxExitBridgeUnavailable = 55;
const int appxExitUsage = 64;
const int appxExitNoMatch = 66;
const int appxExitRefused = 69;
const int appxExitBridgeFailed = 71;

/// Validated `appx` command invocation.
sealed class AppxRequest();

/// Request to list installed or provisioned packages.
final class AppxListRequest({
  final IList<String> prefixes = const .empty(),
  final IList<String> exclude = const .empty(),
  final bool provisioned = false,
}) extends AppxRequest;

final class AppxUsersRequest({
  required final IList<String> prefixes,
  final IList<String> exclude = const .empty(),
}) extends AppxRequest;

final class AppxRemoveRequest({
  required final IList<String> prefixes,
  final IList<String> exclude = const .empty(),
  required final bool allUsers,
  required final bool preserveRoaming,
  final bool scheduleStartup = true,
}) extends AppxRequest;

/// Configures arguments and flags for the `appx` command on [parser].
void configureAppxParser(ArgParser parser) {
  parser.addFlag('list', help: 'Lists installed AppX packages');
  parser.addFlag('provisioned', help: 'Lists packages provisioned machine-wide (with --list)');
  parser.addMultiOption(
    'match',
    valueHelp: 'prefix',
    help: 'Only packages whose name starts with these (with --list)',
  );
  parser.addMultiOption(
    'users',
    valueHelp: 'A,B',
    help: 'Lists the users that have these packages',
  );
  parser.addMultiOption('remove', valueHelp: 'A,B', help: 'Removes these packages');
  parser.addMultiOption(
    'exclude',
    abbr: 'e',
    valueHelp: 'pattern',
    help: 'Excludes packages matching these names or patterns',
  );
  parser.addFlag('all-users', help: 'Removes for every user instead of the caller (with --remove)');
  parser.addFlag(
    'preserve-roaming',
    help: 'Keeps roaming user data (with --remove, not with --all-users)',
  );
  parser.addFlag(
    'schedule-startup',
    defaultsTo: true,
    help: 'Schedules failed removals on next boot via RunOnce (with --remove)',
  );
}

/// Parses command-line arguments into an [AppxRequest].
///
/// Throws a [UsageException] when argument combinations are invalid.
AppxRequest parseAppxRequest(ArgResults? argResults, String usage) {
  Never fail(String message) => throw UsageException('appx: $message', usage);

  IList<String> need(String option, String what) {
    final List<String>? raw = argResults?.multiOption(option);
    final IList<String> cleaned = _clean(raw);
    if (cleaned.isEmpty && (raw?.isNotEmpty ?? false)) {
      fail('--$option needs at least one $what');
    }
    return cleaned;
  }

  final bool list = argResults?.flag('list') ?? false;
  final bool provisioned = argResults?.flag('provisioned') ?? false;
  final bool allUsers = argResults?.flag('all-users') ?? false;
  final bool preserveRoaming = argResults?.flag('preserve-roaming') ?? false;
  final bool scheduleStartup = argResults?.flag('schedule-startup') ?? true;

  final IList<String> match = need('match', 'package name prefix');
  final IList<String> users = need('users', 'package name');
  final IList<String> remove = need('remove', 'package name');
  final IList<String> exclude = _clean(argResults?.multiOption('exclude'));

  final int actions = [list, users.isNotEmpty, remove.isNotEmpty].where((a) => a).length;
  if (actions > 1) fail('only one of --list, --users, --remove');
  if (match.isNotEmpty && !list) fail('--match needs --list');
  if (provisioned && (users.isNotEmpty || remove.isNotEmpty)) {
    fail('--provisioned needs --list');
  }
  if ((allUsers || preserveRoaming) && remove.isEmpty) {
    fail('--all-users and --preserve-roaming need --remove');
  }
  if (allUsers && preserveRoaming) {
    fail('--all-users cannot be combined with --preserve-roaming');
  }

  if (users.isNotEmpty) return AppxUsersRequest(prefixes: users, exclude: exclude);
  if (remove.isNotEmpty) {
    return AppxRemoveRequest(
      prefixes: remove,
      exclude: exclude,
      allUsers: allUsers,
      preserveRoaming: preserveRoaming,
      scheduleStartup: scheduleStartup,
    );
  }
  return AppxListRequest(prefixes: match, exclude: exclude, provisioned: provisioned);
}

// Strips whitespace and filters empty values from multi-options.
IList<String> _clean(List<String>? raw) =>
    (raw ?? const <String>[]).map((s) => s.trim()).where((s) => s.isNotEmpty).toIList();

/// Maps [error] to a process exit code.
int appxExitCode(AppException error) => switch (appxCause(error)) {
  AppxBridgeUnavailableException() => appxExitBridgeUnavailable,
  AppxRemovalRefusedException() => appxExitRefused,
  AppxEnumerationException() => appxExitBridgeFailed,
  _ => 1,
};

/// Command to query, remove, and deprovision AppX packages.
final class AppxCommand({required final ProviderContainer container}) extends Command<void> {
  this {
    configureAppxParser(argParser);
  }

  @override
  String get description => '[AppX] List and remove AppX packages';

  @override
  String get name => 'appx';

  @override
  FutureOr<void> run() async {
    final AppxRequest request;
    try {
      request = parseAppxRequest(argResults, usage);
    } on UsageException catch (e) {
      logger.e(e.message);
      exit(appxExitUsage);
    }

    final AppxService service = container.read(appxServiceProvider);
    try {
      await switch (request) {
        AppxListRequest(:final prefixes, :final exclude, :final provisioned) => _list(
          service,
          prefixes,
          exclude: exclude,
          provisioned: provisioned,
        ),
        AppxUsersRequest(:final prefixes, :final exclude) => _users(
          service,
          prefixes,
          exclude: exclude,
        ),
        AppxRemoveRequest(
          :final prefixes,
          :final exclude,
          :final allUsers,
          :final preserveRoaming,
          :final scheduleStartup,
        ) =>
          _remove(
            service,
            prefixes,
            exclude: exclude,
            allUsers: allUsers,
            preserveRoaming: preserveRoaming,
            scheduleStartup: scheduleStartup,
          ),
      };
    } on AppException catch (error) {
      logger.e('$name: ${error.message}');
      exit(appxExitCode(error));
    } on Object catch (error, stackTrace) {
      logger.e('$name: Operation failed', error: error, stackTrace: stackTrace);
      exit(1);
    }
    exit(0);
  }

  Future<void> _list(
    AppxService service,
    IList<String> prefixes, {
    required IList<String> exclude,
    required bool provisioned,
  }) async {
    final IList<AppxPackage> packages = await _unwrap(
      provisioned ? service.listProvisionedPackages() : service.listPackages(),
    );
    final IList<AppxPackage> matched = _filterPackages(packages, prefixes, exclude: exclude);
    if (matched.isEmpty && prefixes.isNotEmpty) {
      logger.e('$name: No package matched ${prefixes.join(', ')}');
      exit(appxExitNoMatch);
    }
    _warnUnmatched(packages, prefixes);
    for (final package in matched) {
      stdout.writeln(package.fullName);
    }
  }

  Future<void> _users(
    AppxService service,
    IList<String> prefixes, {
    required IList<String> exclude,
  }) async {
    final IList<AppxPackage> packages = await _resolve(service, prefixes, exclude: exclude);
    for (final package in packages) {
      stdout.writeln(package.fullName);
      final IList<AppxPackageUser> users = await _unwrap(
        service.findUsers(fullName: package.fullName),
      );
      for (final user in users) {
        stdout.writeln('  ${user.sid}  ${user.installState}');
      }
    }
  }

  Future<void> _remove(
    AppxService service,
    IList<String> prefixes, {
    required IList<String> exclude,
    required bool allUsers,
    required bool preserveRoaming,
    required bool scheduleStartup,
  }) async {
    final IList<AppxPackage> packages = await _resolve(service, prefixes, exclude: exclude);
    for (final package in packages) {
      stdout.writeln('Removing ${package.fullName}...');
    }
    final Result<IList<AppxRemovalResult>> result = await service.removePackages(
      prefixes: packages.map((p) => p.fullName).toSet(),
      allUsers: allUsers,
      preserveRoaming: preserveRoaming,
      scheduleOnStartup: scheduleStartup,
    );
    result.when(
      success: (removed) {
        for (final res in removed) {
          stdout.writeln('Removed ${res.identifier}');
        }
      },
      failure: (error) {
        logger.e('$name: Failed to remove: ${error.message}');
        exit(appxExitRefused);
      },
    );
  }

  /// Full names matching [prefixes], excluding any matching [exclude].
  Future<IList<AppxPackage>> _resolve(
    AppxService service,
    IList<String> prefixes, {
    IList<String> exclude = const .empty(),
  }) async {
    final IList<AppxPackage> installed = await _unwrap(service.listPackages());
    final IList<AppxPackage> matched = _filterPackages(installed, prefixes, exclude: exclude);
    if (matched.isEmpty) {
      logger.e('$name: No installed package matched ${prefixes.join(', ')}');
      exit(appxExitNoMatch);
    }
    _warnUnmatched(installed, prefixes);
    return matched;
  }

  void _warnUnmatched(IList<AppxPackage> installed, IList<String> prefixes) {
    for (final prefix in prefixes) {
      if (_filterPackages(installed, [prefix].toIList()).isEmpty) {
        logger.w('$name: No installed package matched $prefix');
      }
    }
  }

  static bool _matchesPattern(String fullName, String pattern) {
    final String cleanPattern = pattern.replaceAll('*', '').trim().toLowerCase();
    if (cleanPattern.isEmpty) return true;
    final String bare = appxBareName(fullName).toLowerCase();
    final String full = fullName.toLowerCase();
    return bare.contains(cleanPattern) || full.contains(cleanPattern);
  }

  /// Filters [packages] matching any of [prefixes] and none of [exclude].
  static IList<AppxPackage> _filterPackages(
    IList<AppxPackage> packages,
    IList<String> prefixes, {
    IList<String> exclude = const .empty(),
  }) {
    return packages.where((p) {
      final bool matchesQuery =
          prefixes.isEmpty || prefixes.any((pat) => _matchesPattern(p.fullName, pat));
      if (!matchesQuery) return false;
      final bool isExcluded =
          exclude.isNotEmpty && exclude.any((ex) => _matchesPattern(p.fullName, ex));
      return !isExcluded;
    }).toIList();
  }

  static Future<T> _unwrap<T>(Future<Result<T>> result) async =>
      (await result).when(success: (T value) => value, failure: (AppException e) => throw e);
}
