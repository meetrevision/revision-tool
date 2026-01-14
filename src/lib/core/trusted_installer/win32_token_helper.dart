// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Low-level Win32 API wrapper for TrustedInstaller token operations.
///
/// This class provides helper methods for:
/// - Service Control Manager operations
/// - Process and token manipulation
/// - Token duplication and impersonation
class Win32TokenHelper {
  static final _advapi32 = DynamicLibrary.open('advapi32.dll');

  static final _duplicateTokenEx = _advapi32
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, Pointer, Int32, Int32, Pointer<IntPtr>),
        int Function(int, int, Pointer, int, int, Pointer<IntPtr>)
      >('DuplicateTokenEx');

  static final _impersonateLoggedOnUser = _advapi32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'ImpersonateLoggedOnUser',
      );

  static final _revertToSelf = _advapi32
      .lookupFunction<Int32 Function(), int Function()>('RevertToSelf');

  static final _lookupPrivilegeValue = _advapi32
      .lookupFunction<
        Int32 Function(
          Pointer<Utf16> lpSystemName,
          Pointer<Utf16> lpName,
          Pointer<LUID> lpLuid,
        ),
        int Function(
          Pointer<Utf16> lpSystemName,
          Pointer<Utf16> lpName,
          Pointer<LUID> lpLuid,
        )
      >('LookupPrivilegeValueW');

  static final _adjustTokenPrivileges = _advapi32
      .lookupFunction<
        Int32 Function(
          IntPtr tokenHandle,
          Int32 disableAllPrivileges,
          Pointer privilegesPtr,
          Uint32 bufferLength,
          Pointer previousState,
          Pointer returnLength,
        ),
        int Function(
          int tokenHandle,
          int disableAllPrivileges,
          Pointer privilegesPtr,
          int bufferLength,
          Pointer previousState,
          Pointer returnLength,
        )
      >('AdjustTokenPrivileges');

  // CreateProcessWithTokenW - simpler alternative to CreateProcessAsUserW
  static final _createProcessWithToken = _advapi32
      .lookupFunction<
        Int32 Function(
          IntPtr hToken,
          Uint32 dwLogonFlags,
          Pointer<Utf16> lpApplicationName,
          Pointer<Utf16> lpCommandLine,
          Uint32 dwCreationFlags,
          Pointer lpEnvironment,
          Pointer<Utf16> lpCurrentDirectory,
          Pointer<STARTUPINFO> lpStartupInfo,
          Pointer<PROCESS_INFORMATION> lpProcessInformation,
        ),
        int Function(
          int hToken,
          int dwLogonFlags,
          Pointer<Utf16> lpApplicationName,
          Pointer<Utf16> lpCommandLine,
          int dwCreationFlags,
          Pointer lpEnvironment,
          Pointer<Utf16> lpCurrentDirectory,
          Pointer<STARTUPINFO> lpStartupInfo,
          Pointer<PROCESS_INFORMATION> lpProcessInformation,
        )
      >('CreateProcessWithTokenW');

  // Service Control Manager Access Rights
  static const int SC_MANAGER_CONNECT = 0x0001;

  // Service Access Rights
  static const int SERVICE_QUERY_STATUS = 0x0004;
  static const int SERVICE_START = 0x0010;

  // Service State
  static const int SERVICE_STOPPED = 0x00000001;
  static const int SERVICE_START_PENDING = 0x00000002;
  static const int SERVICE_RUNNING = 0x00000004;

  // Process Access Rights
  static const int PROCESS_QUERY_INFORMATION = 0x0400;

  // Token Access Rights
  static const int TOKEN_DUPLICATE = 0x0002;
  static const int TOKEN_ALL_ACCESS = 0xF01FF;

  // CreateProcessWithToken flags
  static const int LOGON_WITH_PROFILE = 0x00000001;
  static const int CREATE_UNICODE_ENVIRONMENT = 0x00000400;

  // Privilege names
  static const String SE_DEBUG_NAME = 'SeDebugPrivilege';

  // Privilege attributes
  static const int SE_PRIVILEGE_ENABLED = 0x00000002;

  // Error codes
  static const int ERROR_NOT_ALL_ASSIGNED = 1300;

  // Security Impersonation Level (for SECURITY_IMPERSONATION_LEVEL enum)
  static const int SecurityImpersonation = 2;

  // Token Types (for TOKEN_TYPE enum)
  static const int TokenImpersonation = 2;

  /// Enables SeDebugPrivilege for the current process.
  static bool enableDebugPrivilege() {
    final tokenHandle = calloc<HANDLE>();
    final luidDebug = calloc<LUID>();
    final debugNamePtr = SE_DEBUG_NAME.toNativeUtf16();

    try {
      if (OpenProcessToken(
            GetCurrentProcess(),
            TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
            tokenHandle,
          ) ==
          0) {
        return false;
      }

      if (_lookupPrivilegeValue(nullptr, debugNamePtr, luidDebug) == 0) {
        CloseHandle(tokenHandle.value);
        return false;
      }

      const tkpSize = 16; // TOKEN_PRIVILEGES with 1 privilege
      final tkp = calloc<Uint8>(tkpSize);

      try {
        tkp.cast<Uint32>().value = 1; // PrivilegeCount
        final luidPtr = (tkp + 4).cast<LUID>();
        luidPtr.ref.LowPart = luidDebug.ref.LowPart;
        luidPtr.ref.HighPart = luidDebug.ref.HighPart;
        (tkp + 12).cast<Uint32>().value = SE_PRIVILEGE_ENABLED;

        final result = _adjustTokenPrivileges(
          tokenHandle.value,
          0,
          tkp.cast(),
          tkpSize,
          nullptr,
          nullptr,
        );
        CloseHandle(tokenHandle.value);

        if (result == 0) return false;
        final lastError = GetLastError();
        return lastError == 0 || lastError == ERROR_NOT_ALL_ASSIGNED;
      } finally {
        calloc.free(tkp);
      }
    } finally {
      calloc.free(tokenHandle);
      calloc.free(luidDebug);
      calloc.free(debugNamePtr);
    }
  }

  /// Opens the Service Control Manager with specified access rights.
  static int openServiceControlManager({
    String? machineName,
    String? databaseName,
    int desiredAccess = SC_MANAGER_CONNECT,
  }) {
    final machine = machineName?.toNativeUtf16() ?? nullptr;
    final database = databaseName?.toNativeUtf16() ?? nullptr;

    try {
      return OpenSCManager(machine, database, desiredAccess);
    } finally {
      if (machine != nullptr) calloc.free(machine);
      if (database != nullptr) calloc.free(database);
    }
  }

  /// Opens a service with specified access rights.
  static int openService(int scManager, String serviceName, int desiredAccess) {
    final namePtr = serviceName.toNativeUtf16();
    try {
      return OpenService(scManager, namePtr, desiredAccess);
    } finally {
      calloc.free(namePtr);
    }
  }

  /// Starts a service.
  static bool startService(int service) {
    return StartService(service, 0, nullptr) != 0;
  }

  /// Queries service status and returns process ID if running.
  static int? getServiceProcessId(int service) {
    final statusPtr = calloc<SERVICE_STATUS_PROCESS>();
    final bytesNeeded = calloc<DWORD>();

    try {
      if (QueryServiceStatusEx(
            service,
            SC_STATUS_PROCESS_INFO,
            statusPtr.cast(),
            sizeOf<SERVICE_STATUS_PROCESS>(),
            bytesNeeded,
          ) ==
          0) {
        return null;
      }
      return statusPtr.ref.dwCurrentState == SERVICE_RUNNING
          ? statusPtr.ref.dwProcessId
          : null;
    } finally {
      calloc.free(statusPtr);
      calloc.free(bytesNeeded);
    }
  }

  /// Gets the current state of a service.
  static int getServiceState(int service) {
    final statusPtr = calloc<SERVICE_STATUS_PROCESS>();
    final bytesNeeded = calloc<DWORD>();

    try {
      if (QueryServiceStatusEx(
            service,
            SC_STATUS_PROCESS_INFO,
            statusPtr.cast(),
            sizeOf<SERVICE_STATUS_PROCESS>(),
            bytesNeeded,
          ) ==
          0) {
        return SERVICE_STOPPED;
      }
      return statusPtr.ref.dwCurrentState;
    } finally {
      calloc.free(statusPtr);
      calloc.free(bytesNeeded);
    }
  }

  /// Opens a process with specified access rights.
  static int openProcess(int processId, int desiredAccess) {
    return OpenProcess(desiredAccess, FALSE, processId);
  }

  /// Finds a process by name (e.g., "lsass.exe") and returns its PID.
  static Future<int?> findProcessByName(String processName) async {
    try {
      final result = await Process.run('tasklist', [
        '/FI',
        'IMAGENAME eq $processName',
        '/FO',
        'CSV',
        '/NH',
      ]);
      if (result.exitCode != 0) return null;

      final output = result.stdout.toString().trim();
      if (output.isEmpty || output.toLowerCase().contains('no tasks')) {
        return null;
      }

      final parts = output.split(',');
      return parts.length >= 2
          ? int.tryParse(parts[1].replaceAll('"', '').trim())
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Opens a process token with specified access rights.
  static int? openProcessToken(int processHandle, int desiredAccess) {
    final tokenPtr = calloc<HANDLE>();
    try {
      final result = OpenProcessToken(processHandle, desiredAccess, tokenPtr);
      if (result == 0) {
        return null;
      }
      return tokenPtr.value;
    } finally {
      calloc.free(tokenPtr);
    }
  }

  /// Duplicates a token for impersonation.
  static int? duplicateToken(
    int existingToken,
    int desiredAccess,
    int impersonationLevel,
    int tokenType,
  ) {
    final newTokenPtr = calloc<HANDLE>();
    try {
      return _duplicateTokenEx(
                existingToken,
                desiredAccess,
                nullptr,
                impersonationLevel,
                tokenType,
                newTokenPtr,
              ) ==
              0
          ? null
          : newTokenPtr.value;
    } finally {
      calloc.free(newTokenPtr);
    }
  }

  /// Impersonates a logged-on user using their token.
  static bool impersonateLoggedOnUser(int token) =>
      _impersonateLoggedOnUser(token) != 0;

  /// Reverts the current thread to its original security context.
  static bool revertToSelf() => _revertToSelf() != 0;

  /// Closes a handle.
  static bool closeHandle(int handle) => CloseHandle(handle) != 0;

  /// Closes a service handle.
  static bool closeServiceHandle(int handle) => CloseServiceHandle(handle) != 0;

  /// Gets the last Win32 error code.
  static int getLastError() => GetLastError();

  /// Checks if a handle is valid (non-zero and not INVALID_HANDLE_VALUE).
  static bool isValidHandle(int handle) =>
      handle != 0 && handle != INVALID_HANDLE_VALUE;

  /// Executes a command with the specified token using CreateProcessWithTokenW.
  /// Returns a map with exitCode, stdout, and stderr.
  static Future<Map<String, dynamic>> executeAsToken(
    int token,
    String command,
    List<String> args,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempDir = Platform.environment['TEMP'] ?? r'C:\Windows\Temp';
    final stdoutFile = '$tempDir\\ti_stdout_$timestamp.tmp';
    final stderrFile = '$tempDir\\ti_stderr_$timestamp.tmp';

    try {
      final fullCommand = args.isEmpty ? command : '$command ${args.join(' ')}';
      final commandLine =
          'cmd.exe /c $fullCommand > "$stdoutFile" 2> "$stderrFile"';
      final commandLinePtr = commandLine.toNativeUtf16();
      final startupInfo = calloc<STARTUPINFO>();
      final processInfo = calloc<PROCESS_INFORMATION>();

      try {
        startupInfo.ref
          ..cb = sizeOf<STARTUPINFO>()
          ..dwFlags = STARTF_USESHOWWINDOW
          ..wShowWindow = SW_HIDE;

        if (_createProcessWithToken(
              token,
              LOGON_WITH_PROFILE,
              nullptr,
              commandLinePtr,
              CREATE_UNICODE_ENVIRONMENT,
              nullptr,
              nullptr,
              startupInfo,
              processInfo,
            ) ==
            0) {
          throw Exception(
            'CreateProcessWithTokenW failed (Error: ${GetLastError()})',
          );
        }

        WaitForSingleObject(processInfo.ref.hProcess, INFINITE);

        final exitCodePtr = calloc<DWORD>();
        int exitCode;
        try {
          GetExitCodeProcess(processInfo.ref.hProcess, exitCodePtr);
          exitCode = exitCodePtr.value;
        } finally {
          calloc.free(exitCodePtr);
        }

        await Future.delayed(const Duration(milliseconds: 50));

        String stdout = '';
        String stderr = '';

        try {
          final stdoutFileObj = File(stdoutFile);
          stdout = await stdoutFileObj.exists()
              ? await stdoutFileObj.readAsString()
              : '(stdout file not found)';
        } catch (e) {
          stdout = '(error reading stdout: $e)';
        }

        try {
          final stderrFileObj = File(stderrFile);
          if (await stderrFileObj.exists()) {
            stderr = await stderrFileObj.readAsString();
          }
        } catch (e) {
          stderr = '(error reading stderr: $e)';
        }

        return {'exitCode': exitCode, 'stdout': stdout, 'stderr': stderr};
      } finally {
        if (processInfo.ref.hProcess != 0) {
          CloseHandle(processInfo.ref.hProcess);
        }
        if (processInfo.ref.hThread != 0) CloseHandle(processInfo.ref.hThread);
        calloc.free(commandLinePtr);
        calloc.free(startupInfo);
        calloc.free(processInfo);
      }
    } finally {
      try {
        final f = File(stdoutFile);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      try {
        final f = File(stderrFile);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}
