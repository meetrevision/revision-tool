export 'package:args/command_runner.dart';

export '../../utils.dart';

/// Marks an abstract service as a generated CLI command group.
///
/// The generator creates `XxxCliCommand` with this [name] and [description].
final class const CliCommand({required final String name, required final String description});

/// Marks a boolean status getter that has enable/disable companion methods.
///
/// Requires explicit [enable], [disable], and [status] method names (as strings).
/// Optional [enableForce] and [disableForce] for --force flag support.
///
/// Example:
/// ```dart
/// @CliToggle(
///   name: 'example',
///   status: 'statusExample',
///   enable: 'enableExample',
///   disable: 'disableExample',
/// )
/// bool get statusExample;
/// ```
final class const CliToggle({
  required final String name,
  required final String status,
  required final String enable,
  required final String disable,
  final String? enableForce,
  final String? disableForce,
});

/// Marks a getter that returns a value and has a setter method.
///
/// Generates a status command to get the value and a set command to modify it.
/// Requires explicit [status] and [set] method names (as strings).
///
/// Example:
/// ```dart
/// @CliValue(
///   name: 'rate-limit',
///   status: 'statusRateLimit',
///   set: 'setRateLimit',
/// )
/// int get statusRateLimit;
/// ```
final class const CliValue({
  required final String name,
  required final String status,
  final String? set,
});

/// Marks an action-only method that runs once and does not expose status.
///
/// Requires explicit [run] method name (as string).
///
/// Example:
/// ```dart
/// @CliAction(name: 'update-kgl', run: 'updateKGL')
/// Future<void> updateKGL();
/// ```
final class const CliAction({required final String name, required final String run});

/// Marks an enum-based command group.
///
/// Use [values] from your enum and optional [help] for `allowedHelp` labels.
final class const CliEnumSubCommand<T extends Enum>({
  required final String name,
  required final List<T> values,
  required final String status,
  final String? enableMethod,
  final String? disableMethod,
  final String? setMethod,
  final Map<String, String> help = const {},
});
