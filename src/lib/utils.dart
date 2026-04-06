import 'dart:core';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import 'core/services/win_registry_service.dart';

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
  "${mainPath.substring(0, mainPath.lastIndexOf(r"\"))}\\data\\flutter_assets\\additionals",
).path;

String systemLanguage =
    WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Control Panel\International',
      'LocaleName',
    ) ??
    'en_US';

String appLanguage =
    WinRegistryService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Language',
    ) ??
    'en';

final String ameTemp = path.join(
  Directory.systemTemp.path,
  'AME',
  'Playbooks',
  'Revision-ReviOS',
);

final String tempReviPath = path.join(
  Directory.systemTemp.path,
  'Revision-Tool',
  'Logs',
);

final logger = Logger(
  filter: ProductionFilter(),
  level: Level.debug,
  printer: SimplePrinter(printTime: true, colors: false),
  output: MultiOutput([
    AdvancedFileOutput(overrideExisting: true, path: tempReviPath),
    ConsoleOutput(),
  ]),
);

typedef IsRunningFunc = Int32 Function(Pointer<Utf16>);
typedef IsRunningDart = int Function(Pointer<Utf16>);

bool isProcessRunning(String name) {
  final String dllPath = const bool.fromEnvironment('dart.vm.product')
      ? path.join(
          mainPath.substring(0, mainPath.lastIndexOf(r'\')),
          'process_checker.dll',
        )
      : path.join(
          path.current.substring(0, path.current.lastIndexOf(r'\')),
          r'native_utils\process_checker.dll',
        ); // for dev purposes

  if (!File(dllPath).existsSync()) {
    logger.e('DLL not found: $dllPath');
    return false;
  }

  final dylib = DynamicLibrary.open(dllPath);

  final IsRunningDart isRunning = dylib
      .lookupFunction<IsRunningFunc, IsRunningDart>('IsRunning');

  final Pointer<Utf16> processName = name.toNativeUtf16();
  final int result = isRunning(processName);
  calloc.free(processName);

  return result == 1;
}

/// PowerShell helper for executing commands with faster startup time
Future<ProcessResult> runPSCommand(
  String command, {
  bool stdout = false,
  bool loggerInfoOutput = true,
  bool encodedCommand = false,
}) async {
  final args = <String>[
    '-NoProfile',
    '-NonInteractive',
    '-NoLogo',
    if (encodedCommand) ...[
      '-EncodedCommand',
      _toUtf16LeBase64(command),
    ] else ...[
      '-Command',
      command,
    ],
  ];
  final ProcessResult result = await Process.run(
    'powershell',
    args,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    logger.e(
      'ps_command',
      error: result.stderr,
      stackTrace: StackTrace.current,
    );
    throw ProcessException(
      'powershell',
      args,
      result.stderr.toString(),
      result.exitCode,
    );
  }
  if (loggerInfoOutput) {
    logger.i('ps_command: $command; ${stdout ? result.stdout : ''}');
  }

  return result;
}

String _toUtf16LeBase64(String value) {
  final units = Uint16List.fromList(value.codeUnits);
  return base64Encode(Uint8List.view(units.buffer));
}

final shell = Shell(commandVerbose: true);
