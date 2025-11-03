import 'dart:async';
import 'package:revitool/shared/trusted_installer/trusted_installer_exception.dart';
import 'package:revitool/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'win32_token_helper.dart';

part 'trusted_installer_service.g.dart';

class CommandResult {
  final int exitCode;
  final String output;
  final String error;

  const CommandResult({
    required this.exitCode,
    required this.output,
    required this.error,
  });

  @override
  String toString() =>
      'CommandResult(exitCode: $exitCode, output: $output, error: $error)';
}

/// Service for executing operations with TrustedInstaller privileges.
///
/// This service handles token impersonation to run operations that require
/// TrustedInstaller-level access, which is higher than Administrator.
abstract class TrustedInstallerService {
  /// Executes a callback with TrustedInstaller privileges.
  ///
  /// The callback will be executed with an impersonated TrustedInstaller token,
  /// allowing registry and system modifications that normally require TrustedInstaller.
  ///
  /// Example:
  /// ```dart
  /// await service.executeWithTrustedInstaller(() async {
  ///   // Registry operations here run with TrustedInstaller privileges
  ///   return await someRegistryOperation();
  /// });
  /// ```
  Future<T> executeWithTrustedInstaller<T>(Future<T> Function() callback);

  /// Executes a command with TrustedInstaller privileges.
  ///
  /// This properly creates a new process with the TrustedInstaller token,
  /// allowing shell commands that require TrustedInstaller privileges.
  ///
  /// Returns a [CommandResult] containing the exit code and output.
  ///
  /// Example:
  /// ```dart
  /// final result = await service.executeCommand('whoami', ['/all']);
  /// print('Exit code: ${result.exitCode}');
  /// print('Output: ${result.output}');
  /// ```
  Future<CommandResult> executeCommand(String command, List<String> args);

  /// Checks if TrustedInstaller service is available and can be used.
  bool isTrustedInstallerAvailable();
}

class TrustedInstallerServiceImpl implements TrustedInstallerService {
  static const String _serviceName = 'TrustedInstaller';
  static const int _maxRetries = 8;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);
  static const Duration _maxRetryDelay = Duration(milliseconds: 3000);

  // Cached state
  static int? _cachedSystemPid;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    logger.i('[TrustedInstaller] Initializing - caching system process PID');

    if (!Win32TokenHelper.enableDebugPrivilege()) {
      final error = Win32TokenHelper.getLastError();
      logger.e(
        '[TrustedInstaller] Failed to enable SeDebugPrivilege during init (Error: $error)',
      );
      throw TrustedInstallerException(
        'Failed to enable SeDebugPrivilege during initialization',
        error,
      );
    }

    _cachedSystemPid = await Win32TokenHelper.findProcessByName('winlogon.exe');
    _cachedSystemPid ??= await Win32TokenHelper.findProcessByName('lsass.exe');

    if (_cachedSystemPid == null || _cachedSystemPid == 0) {
      logger.e(
        '[TrustedInstaller] Failed to find winlogon.exe or lsass.exe during init',
      );
      throw TrustedInstallerException(
        'Failed to find system process during initialization',
      );
    }

    _initialized = true;
    logger.i(
      '[TrustedInstaller] Initialized successfully (System PID: $_cachedSystemPid)',
    );
  }

  @override
  Future<T> executeWithTrustedInstaller<T>(
    Future<T> Function() callback,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    int scManager = 0;
    int service = 0;
    int process = 0;
    int processToken = 0;
    int duplicatedToken = 0;
    int systemToken = 0;

    try {
      final systemPid = _cachedSystemPid!;

      final winlogonProcess = Win32TokenHelper.openProcess(
        systemPid,
        Win32TokenHelper.PROCESS_QUERY_INFORMATION,
      );

      if (!Win32TokenHelper.isValidHandle(winlogonProcess)) {
        final error = Win32TokenHelper.getLastError();
        logger.e(
          '[TrustedInstaller] Failed to open SYSTEM process (PID: $systemPid, Error: $error)',
        );
        throw TrustedInstallerException('Failed to open SYSTEM process', error);
      }

      try {
        systemToken =
            Win32TokenHelper.openProcessToken(
              winlogonProcess,
              Win32TokenHelper.TOKEN_DUPLICATE,
            ) ??
            0;

        if (!Win32TokenHelper.isValidHandle(systemToken)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to open SYSTEM token (Error: $error)',
          );
          throw TrustedInstallerException('Failed to open SYSTEM token', error);
        }

        final systemDupToken =
            Win32TokenHelper.duplicateToken(
              systemToken,
              Win32TokenHelper.TOKEN_ALL_ACCESS,
              Win32TokenHelper.SecurityImpersonation,
              Win32TokenHelper.TokenImpersonation,
            ) ??
            0;

        if (!Win32TokenHelper.isValidHandle(systemDupToken)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to duplicate SYSTEM token (Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to duplicate SYSTEM token',
            error,
          );
        }

        // Impersonate as SYSTEM
        if (!Win32TokenHelper.impersonateLoggedOnUser(systemDupToken)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to impersonate as SYSTEM (Error: $error)',
          );
          Win32TokenHelper.closeHandle(systemDupToken);
          throw TrustedInstallerException(
            'Failed to impersonate as SYSTEM',
            error,
          );
        }

        Win32TokenHelper.closeHandle(systemDupToken);

        scManager = Win32TokenHelper.openServiceControlManager(
          desiredAccess: Win32TokenHelper.SC_MANAGER_CONNECT,
        );

        if (!Win32TokenHelper.isValidHandle(scManager)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to open Service Control Manager (Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to open Service Control Manager',
            error,
          );
        }

        service = Win32TokenHelper.openService(
          scManager,
          _serviceName,
          Win32TokenHelper.SERVICE_QUERY_STATUS |
              Win32TokenHelper.SERVICE_START,
        );

        if (!Win32TokenHelper.isValidHandle(service)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to open TrustedInstaller service (Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to open TrustedInstaller service',
            error,
          );
        }

        final processId = await _ensureServiceRunning(service);
        if (processId == null || processId == 0) {
          logger.e(
            '[TrustedInstaller] Failed to start TrustedInstaller service or get process ID',
          );
          throw TrustedInstallerException(
            'Failed to start TrustedInstaller service or get process ID',
          );
        }

        process = Win32TokenHelper.openProcess(
          processId,
          Win32TokenHelper.PROCESS_QUERY_INFORMATION,
        );

        if (!Win32TokenHelper.isValidHandle(process)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to open TrustedInstaller process (PID: $processId, Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to open TrustedInstaller process (PID: $processId)',
            error,
          );
        }

        processToken =
            Win32TokenHelper.openProcessToken(
              process,
              Win32TokenHelper.TOKEN_DUPLICATE,
            ) ??
            0;

        if (!Win32TokenHelper.isValidHandle(processToken)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to open TrustedInstaller token (Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to open TrustedInstaller token',
            error,
          );
        }

        duplicatedToken =
            Win32TokenHelper.duplicateToken(
              processToken,
              Win32TokenHelper.TOKEN_ALL_ACCESS,
              Win32TokenHelper.SecurityImpersonation,
              Win32TokenHelper.TokenImpersonation,
            ) ??
            0;

        if (!Win32TokenHelper.isValidHandle(duplicatedToken)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to duplicate TrustedInstaller token (Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to duplicate TrustedInstaller token',
            error,
          );
        }

        Win32TokenHelper.revertToSelf();

        if (!Win32TokenHelper.impersonateLoggedOnUser(duplicatedToken)) {
          final error = Win32TokenHelper.getLastError();
          logger.e(
            '[TrustedInstaller] Failed to impersonate as TrustedInstaller (Error: $error)',
          );
          throw TrustedInstallerException(
            'Failed to impersonate as TrustedInstaller',
            error,
          );
        }

        final result = await callback();

        return result;
      } finally {
        Win32TokenHelper.closeHandle(winlogonProcess);
      }
    } catch (e, stackTrace) {
      logger.e(
        '[TrustedInstaller] Exception occurred: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      Win32TokenHelper.revertToSelf();

      if (Win32TokenHelper.isValidHandle(systemToken)) {
        Win32TokenHelper.closeHandle(systemToken);
      }
      if (Win32TokenHelper.isValidHandle(duplicatedToken)) {
        Win32TokenHelper.closeHandle(duplicatedToken);
      }
      if (Win32TokenHelper.isValidHandle(processToken)) {
        Win32TokenHelper.closeHandle(processToken);
      }
      if (Win32TokenHelper.isValidHandle(process)) {
        Win32TokenHelper.closeHandle(process);
      }
      if (Win32TokenHelper.isValidHandle(service)) {
        Win32TokenHelper.closeServiceHandle(service);
      }
      if (Win32TokenHelper.isValidHandle(scManager)) {
        Win32TokenHelper.closeServiceHandle(scManager);
      }
    }
  }

  @override
  Future<CommandResult> executeCommand(
    String command,
    List<String> args,
  ) async {
    logger.i(
      '[TrustedInstaller] Executing command: $command ${args.join(' ')}',
    );

    int? tiToken;

    try {
      await executeWithTrustedInstaller(() async {
        final service = Win32TokenHelper.openService(
          Win32TokenHelper.openServiceControlManager(
            desiredAccess: Win32TokenHelper.SC_MANAGER_CONNECT,
          ),
          _serviceName,
          Win32TokenHelper.SERVICE_QUERY_STATUS,
        );

        final tiPid = Win32TokenHelper.getServiceProcessId(service);
        Win32TokenHelper.closeHandle(service);

        if (tiPid == null || tiPid == 0) {
          throw TrustedInstallerException('Failed to get TrustedInstaller PID');
        }

        tiToken = _getPrimaryToken(tiPid);
      });

      if (tiToken == null) {
        throw TrustedInstallerException(
          'Failed to obtain TrustedInstaller token',
        );
      }

      final result = await Win32TokenHelper.executeAsToken(
        tiToken!,
        command,
        args,
      );

      logger.i(
        '[TrustedInstaller] Command completed: exit=${result['exitCode']}',
      );

      return CommandResult(
        exitCode: result['exitCode'] as int,
        output: result['stdout'] as String,
        error: result['stderr'] as String,
      );
    } catch (e, stackTrace) {
      logger.e(
        '[TrustedInstaller] Command failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      if (tiToken != null && Win32TokenHelper.isValidHandle(tiToken!)) {
        Win32TokenHelper.closeHandle(tiToken!);
      }
    }
  }

  /// Gets a PRIMARY token from a process ID for CreateProcessWithTokenW
  int? _getPrimaryToken(int processId) {
    final process = Win32TokenHelper.openProcess(
      processId,
      Win32TokenHelper.PROCESS_QUERY_INFORMATION,
    );
    if (!Win32TokenHelper.isValidHandle(process)) return null;

    try {
      final token = Win32TokenHelper.openProcessToken(
        process,
        Win32TokenHelper.TOKEN_DUPLICATE,
      );
      if (token == null) return null;

      try {
        return Win32TokenHelper.duplicateToken(
          token,
          Win32TokenHelper.TOKEN_ALL_ACCESS,
          Win32TokenHelper.SecurityImpersonation,
          1, // TokenPrimary
        );
      } finally {
        Win32TokenHelper.closeHandle(token);
      }
    } finally {
      Win32TokenHelper.closeHandle(process);
    }
  }

  /// Ensures TrustedInstaller service is running and returns its process ID.
  Future<int?> _ensureServiceRunning(int service) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      // Calculate exponential backoff delay
      final delayMs = (_initialRetryDelay.inMilliseconds * (1 << attempt))
          .clamp(0, _maxRetryDelay.inMilliseconds);
      final delay = Duration(milliseconds: delayMs);

      final state = Win32TokenHelper.getServiceState(service);

      if (state == Win32TokenHelper.SERVICE_RUNNING) {
        final pid = Win32TokenHelper.getServiceProcessId(service);

        if (pid != null && pid != 0) {
          return pid;
        }
        // PID is 0 or null, wait for the service to fully initialize
        // Use shorter delay since service is already running
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }

      if (state == Win32TokenHelper.SERVICE_START_PENDING) {
        await Future.delayed(delay);
        continue;
      }

      if (state == Win32TokenHelper.SERVICE_STOPPED) {
        if (Win32TokenHelper.startService(service)) {
          await Future.delayed(const Duration(milliseconds: 1000));
          continue;
        } else {
          final error = Win32TokenHelper.getLastError();
          // ERROR_SERVICE_ALREADY_RUNNING = 1056
          if (error == 1056) {
            await Future.delayed(const Duration(milliseconds: 300));
            continue;
          }
          await Future.delayed(delay);
        }
      }

      // Unknown state, wait before retrying
      await Future.delayed(delay);
    }

    // Final attempts to get process ID
    for (int i = 0; i < 3; i++) {
      final state = Win32TokenHelper.getServiceState(service);
      if (state == Win32TokenHelper.SERVICE_RUNNING) {
        final pid = Win32TokenHelper.getServiceProcessId(service);
        if (pid != null && pid != 0) {
          return pid;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return null;
  }

  @override
  bool isTrustedInstallerAvailable() {
    int scManager = 0;
    int service = 0;

    try {
      scManager = Win32TokenHelper.openServiceControlManager(
        desiredAccess: Win32TokenHelper.SC_MANAGER_CONNECT,
      );

      if (!Win32TokenHelper.isValidHandle(scManager)) {
        return false;
      }

      service = Win32TokenHelper.openService(
        scManager,
        _serviceName,
        Win32TokenHelper.SERVICE_QUERY_STATUS,
      );

      return Win32TokenHelper.isValidHandle(service);
    } finally {
      if (Win32TokenHelper.isValidHandle(service)) {
        Win32TokenHelper.closeServiceHandle(service);
      }
      if (Win32TokenHelper.isValidHandle(scManager)) {
        Win32TokenHelper.closeServiceHandle(scManager);
      }
    }
  }
}

@Riverpod(keepAlive: true)
TrustedInstallerService trustedInstallerService(Ref ref) {
  return TrustedInstallerServiceImpl();
}
