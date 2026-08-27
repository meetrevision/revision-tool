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
class Win32TokenHelper() {
  static final _advapi32 = DynamicLibrary.open('advapi32.dll');

  static final int Function(int, int, Pointer<NativeType>, int, int, Pointer<IntPtr>)
  _duplicateTokenEx = _advapi32
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, Pointer, Int32, Int32, Pointer<IntPtr>),
        int Function(int, int, Pointer, int, int, Pointer<IntPtr>)
      >('DuplicateTokenEx');

  static final int Function(int) _impersonateLoggedOnUser = _advapi32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('ImpersonateLoggedOnUser');

  static final int Function() _revertToSelf = _advapi32
      .lookupFunction<Int32 Function(), int Function()>('RevertToSelf');

  static final int Function(
    Pointer<Utf16> lpSystemName,
    Pointer<Utf16> lpName,
    Pointer<LUID> lpLuid,
  )
  _lookupPrivilegeValue = _advapi32
      .lookupFunction<
        Int32 Function(Pointer<Utf16> lpSystemName, Pointer<Utf16> lpName, Pointer<LUID> lpLuid),
        int Function(Pointer<Utf16> lpSystemName, Pointer<Utf16> lpName, Pointer<LUID> lpLuid)
      >('LookupPrivilegeValueW');

  static final int Function(
    int tokenHandle,
    int disableAllPrivileges,
    Pointer<NativeType> privilegesPtr,
    int bufferLength,
    Pointer<NativeType> previousState,
    Pointer<NativeType> returnLength,
  )
  _adjustTokenPrivileges = _advapi32
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

  static final int Function(
    int hToken,
    int dwLogonFlags,
    Pointer<Utf16> lpApplicationName,
    Pointer<Utf16> lpCommandLine,
    int dwCreationFlags,
    Pointer<NativeType> lpEnvironment,
    Pointer<Utf16> lpCurrentDirectory,
    Pointer<STARTUPINFO> lpStartupInfo,
    Pointer<PROCESS_INFORMATION> lpProcessInformation,
  )
  _createProcessWithToken = _advapi32
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
  static bool enableDebugPrivilege() => using((arena) {
    final Pointer<Pointer> tokenHandlePtr = arena.allocate<Pointer>(sizeOf<Pointer>());
    final Pointer<LUID> luidDebug = arena.allocate<LUID>(sizeOf<LUID>());
    final Pointer<Utf16> debugNamePtr = SE_DEBUG_NAME.toNativeUtf16(allocator: arena);

    final Win32Result<bool> result = OpenProcessToken(
      HANDLE(GetCurrentProcess()),
      TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
      tokenHandlePtr,
    );
    if (!result.value) {
      return false;
    }

    if (_lookupPrivilegeValue(nullptr, debugNamePtr, luidDebug) == 0) {
      CloseHandle(HANDLE(tokenHandlePtr.value));
      return false;
    }

    const tkpSize = 16; // TOKEN_PRIVILEGES with 1 privilege
    final Pointer<Uint8> tkp = arena.allocate<Uint8>(tkpSize);

    tkp.cast<Uint32>().value = 1; // PrivilegeCount
    final Pointer<LUID> luidPtr = (tkp + 4).cast<LUID>();
    luidPtr.ref.LowPart = luidDebug.ref.LowPart;
    luidPtr.ref.HighPart = luidDebug.ref.HighPart;
    (tkp + 12).cast<Uint32>().value = SE_PRIVILEGE_ENABLED;

    final int adjustResult = _adjustTokenPrivileges(
      tokenHandlePtr.value.address,
      0,
      tkp.cast(),
      tkpSize,
      nullptr,
      nullptr,
    );
    CloseHandle(HANDLE(tokenHandlePtr.value));

    if (adjustResult == 0) return false;
    final int lastError = GetLastError();
    return lastError == 0 || lastError == ERROR_NOT_ALL_ASSIGNED;
  });

  /// Opens the Service Control Manager with specified access rights.
  static SC_HANDLE openServiceControlManager({
    String? machineName,
    String? databaseName,
    int desiredAccess = SC_MANAGER_CONNECT,
  }) => using((arena) {
    final Pointer<Utf16> machine = machineName?.toNativeUtf16(allocator: arena) ?? nullptr;
    final Pointer<Utf16> database = databaseName?.toNativeUtf16(allocator: arena) ?? nullptr;

    return OpenSCManager(
      machine != nullptr ? PCWSTR(machine) : null,
      database != nullptr ? PCWSTR(database) : null,
      desiredAccess,
    ).value;
  });

  /// Opens a service with specified access rights.
  static SC_HANDLE openService(SC_HANDLE scManager, String serviceName, int desiredAccess) =>
      using((arena) {
        final Pointer<Utf16> namePtr = serviceName.toNativeUtf16(allocator: arena);
        return OpenService(scManager, PCWSTR(namePtr), desiredAccess).value;
      });

  /// Starts a service.
  static bool startService(SC_HANDLE service) {
    return StartService(service, 0, nullptr).value;
  }

  /// Queries service status and returns process ID if running.
  static int? getServiceProcessId(SC_HANDLE service) => using((arena) {
    final Pointer<SERVICE_STATUS_PROCESS> statusPtr = arena.allocate<SERVICE_STATUS_PROCESS>(
      sizeOf<SERVICE_STATUS_PROCESS>(),
    );
    final Pointer<Uint32> bytesNeeded = arena.allocate<Uint32>(sizeOf<Uint32>());

    final Win32Result<bool> result = QueryServiceStatusEx(
      service,
      SC_STATUS_PROCESS_INFO,
      statusPtr.cast<Uint8>(),
      sizeOf<SERVICE_STATUS_PROCESS>(),
      bytesNeeded,
    );
    if (!result.value) {
      return null;
    }
    return statusPtr.ref.dwCurrentState == SERVICE_RUNNING ? statusPtr.ref.dwProcessId : null;
  });

  /// Gets the current state of a service.
  static int getServiceState(SC_HANDLE service) => using((arena) {
    final Pointer<SERVICE_STATUS_PROCESS> statusPtr = arena.allocate<SERVICE_STATUS_PROCESS>(
      sizeOf<SERVICE_STATUS_PROCESS>(),
    );
    final Pointer<Uint32> bytesNeeded = arena.allocate<Uint32>(sizeOf<Uint32>());

    final Win32Result<bool> result = QueryServiceStatusEx(
      service,
      SC_STATUS_PROCESS_INFO,
      statusPtr.cast<Uint8>(),
      sizeOf<SERVICE_STATUS_PROCESS>(),
      bytesNeeded,
    );
    if (!result.value) {
      return SERVICE_STOPPED;
    }
    return statusPtr.ref.dwCurrentState;
  });

  /// Opens a process with specified access rights.
  static HANDLE openProcess(int processId, int desiredAccess) {
    return OpenProcess(PROCESS_ACCESS_RIGHTS(desiredAccess), false, processId).value;
  }

  /// Finds a process by name (e.g., "lsass.exe") and returns its PID.
  static Future<int?> findProcessByName(String processName) async {
    try {
      final ProcessResult result = await Process.run('tasklist', [
        '/FI',
        'IMAGENAME eq $processName',
        '/FO',
        'CSV',
        '/NH',
      ]);
      if (result.exitCode != 0) return null;

      final String output = result.stdout.toString().trim();
      if (output.isEmpty || output.toLowerCase().contains('no tasks')) {
        return null;
      }

      final List<String> parts = output.split(',');
      return parts.length >= 2 ? int.tryParse(parts[1].replaceAll('"', '').trim()) : null;
    } catch (e) {
      return null;
    }
  }

  /// Opens a process token with specified access rights.
  static HANDLE? openProcessToken(HANDLE processHandle, int desiredAccess) => using((arena) {
    final Pointer<Pointer> tokenPtr = arena.allocate<Pointer>(sizeOf<Pointer>());
    final Win32Result<bool> result = OpenProcessToken(
      processHandle,
      TOKEN_ACCESS_MASK(desiredAccess),
      tokenPtr,
    );
    if (!result.value) {
      return null;
    }
    return HANDLE(tokenPtr.value);
  });

  /// Duplicates a token for impersonation.
  static HANDLE? duplicateToken(
    HANDLE existingToken,
    int desiredAccess,
    int impersonationLevel,
    int tokenType,
  ) {
    return using((arena) {
      final Pointer<IntPtr> newTokenPtr = arena.allocate<IntPtr>(sizeOf<IntPtr>());
      return _duplicateTokenEx(
                existingToken.address,
                desiredAccess,
                nullptr,
                impersonationLevel,
                tokenType,
                newTokenPtr,
              ) ==
              0
          ? null
          : HANDLE(Pointer.fromAddress(newTokenPtr.value));
    });
  }

  /// Impersonates a logged-on user using their token.
  static bool impersonateLoggedOnUser(HANDLE token) => _impersonateLoggedOnUser(token.address) != 0;

  /// Reverts the current thread to its original security context.
  static bool revertToSelf() => _revertToSelf() != 0;

  /// Closes a handle.
  static void closeHandle(HANDLE handle) => CloseHandle(handle);

  /// Closes a service handle.
  static void closeServiceHandle(SC_HANDLE handle) => CloseServiceHandle(handle);

  /// Gets the last Win32 error code.
  static int getLastError() => GetLastError();

  /// Checks if a handle is valid (non-zero and not INVALID_HANDLE_VALUE).
  static bool isValidHandle(Pointer handle) =>
      handle != Pointer.fromAddress(-1) && handle != Pointer.fromAddress(0);

  /// Executes a command with the specified token using CreateProcessWithTokenW.
  /// Returns a map with exitCode, stdout, and stderr.
  static Future<Map<String, dynamic>> executeAsToken(
    HANDLE token,
    String command,
    List<String> args,
  ) async {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String tempDir = Platform.environment['TEMP'] ?? r'C:\Windows\Temp';
    final stdoutFile = '$tempDir\\ti_stdout_$timestamp.tmp';
    final stderrFile = '$tempDir\\ti_stderr_$timestamp.tmp';

    try {
      return await using((arena) async {
        final fullCommand = args.isEmpty ? command : '$command ${args.join(' ')}';
        final commandLine = 'cmd.exe /c $fullCommand > "$stdoutFile" 2> "$stderrFile"';
        final Pointer<Utf16> commandLinePtr = commandLine.toNativeUtf16(allocator: arena);
        final Pointer<STARTUPINFO> startupInfo = arena.allocate<STARTUPINFO>(sizeOf<STARTUPINFO>());
        final Pointer<PROCESS_INFORMATION> processInfo = arena.allocate<PROCESS_INFORMATION>(
          sizeOf<PROCESS_INFORMATION>(),
        );

        startupInfo.ref
          ..cb = sizeOf<STARTUPINFO>()
          ..dwFlags = STARTF_USESHOWWINDOW
          ..wShowWindow = SW_HIDE;

        if (_createProcessWithToken(
              token.address,
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
          throw Exception('CreateProcessWithTokenW failed (Error: ${GetLastError()})');
        }

        WaitForSingleObject(processInfo.ref.hProcess, INFINITE);

        final Pointer<DWORD> exitCodePtr = arena.allocate<DWORD>(sizeOf<DWORD>());
        GetExitCodeProcess(processInfo.ref.hProcess, exitCodePtr);
        final int exitCode = exitCodePtr.value;

        await Future<void>.delayed(const Duration(milliseconds: 50));

        var stdout = '';
        var stderr = '';

        try {
          final stdoutFileObj = File(stdoutFile);
          stdout = stdoutFileObj.existsSync()
              ? await stdoutFileObj.readAsString()
              : '(stdout file not found)';
        } catch (e) {
          stdout = '(error reading stdout: $e)';
        }

        try {
          final stderrFileObj = File(stderrFile);
          if (stderrFileObj.existsSync()) {
            stderr = await stderrFileObj.readAsString();
          }
        } catch (e) {
          stderr = '(error reading stderr: $e)';
        }

        if (processInfo.ref.hProcess.isValid) {
          CloseHandle(processInfo.ref.hProcess);
        }
        if (processInfo.ref.hThread.isValid) CloseHandle(processInfo.ref.hThread);

        return {'exitCode': exitCode, 'stdout': stdout, 'stderr': stderr};
      });
    } finally {
      try {
        final f = File(stdoutFile);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
      try {
        final f = File(stderrFile);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
  }
}
