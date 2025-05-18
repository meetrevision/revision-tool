import 'dart:core';
import 'dart:ffi';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:win32_registry/win32_registry.dart';

final String mainPath = Platform.resolvedExecutable;
final String directoryExe =
    Directory(
      "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals",
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
    'en_US';

final ameTemp = path.join(
  Directory.systemTemp.path,
  'AME',
  'Playbooks',
  'Revision-ReviOS',
);

final tempReviPath = path.join(
  Directory.systemTemp.path,
  'Revision-Tool',
  'Logs',
);

final logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    colors: false,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
  output: AdvancedFileOutput(overrideExisting: true, path: tempReviPath),
);

typedef IsRunningCFunc = Int32 Function(Pointer<Utf16>);
typedef IsRunningCDart = int Function(Pointer<Utf16>);

bool isProcessRunning(String name) {
  final dllPath =
      const bool.fromEnvironment("dart.vm.product")
          ? path.join(
            mainPath.substring(0, mainPath.lastIndexOf("\\")),
            'process_checker.dll',
          )
          : path.join(
            path.current.substring(0, path.current.lastIndexOf('\\')),
            'native_utils\\process_checker.dll',
          ); // for dev purposes

  if (!File(dllPath).existsSync()) {
    logger.e('DLL not found: $dllPath');
    return false;
  }

  final dylib = DynamicLibrary.open(dllPath);

  final isRunningC = dylib.lookupFunction<IsRunningCFunc, IsRunningCDart>(
    'IsRunningC',
  );

  final processName = name.toNativeUtf16();
  final result = isRunningC(processName);
  calloc.free(processName);

  return result == 0;
}
