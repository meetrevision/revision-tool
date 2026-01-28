import 'dart:typed_data';

import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../utils.dart';
import '../trusted_installer/trusted_installer_service.dart';

class WinRegistryService {
  const WinRegistryService._private();
  static const tag = 'await WinRegistryService';

  static int get buildNumber => _buildNumber;
  static final int _buildNumber = int.parse(
    WinRegistryService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
      'CurrentBuildNumber',
    )!,
  );

  static final RegistryKey currentUser = Registry.currentUser;
  static const defaultUser = 'DefaultUserHive';
  static const defaultUserHivePath = r'C:\Users\Default\NTUSER.DAT';

  static bool get isW11 => _w11;
  static final bool _w11 = buildNumber > 19045;

  static final String cpuArch = readString(
    RegistryHive.localMachine,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'PROCESSOR_ARCHITECTURE',
  )!.toLowerCase();

  static final String _cpuVendorIdentifier =
      (readString(
                RegistryHive.localMachine,
                r'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
                'VendorIdentifier',
              ) ??
              '')
          .toLowerCase();

  static bool get isIntelCpu => _cpuVendorIdentifier.contains('intel');
  static bool get isAmdCpu => _cpuVendorIdentifier.contains('amd');

  static bool get isSupported {
    return _validate() ||
        readString(
              RegistryHive.localMachine,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubVersion',
            ) ==
            'ReviOS' ||
        readString(
              RegistryHive.localMachine,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubManufacturer',
            ) ==
            'MeetRevision';
  }

  static bool _validate() {
    final RegistryKey key = Registry.openPath(
      RegistryHive.localMachine,
      path:
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages',
    );

    try {
      return key.subkeyNames
          .lastWhere((element) => element.startsWith('Revision-ReviOS'))
          .isNotEmpty;
    } catch (e) {
      logger.w('Error validating ReviOS');
      return false;
    } finally {
      key.close();
    }
  }

  static Future<void> hidePageVisibilitySettings(String pageName) async {
    final String? currentValue = readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
      'SettingsPageVisibility',
    );

    if (currentValue == null || currentValue.isEmpty) {
      await writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        'hide:$pageName',
      );
      return;
    }
    if (!currentValue.contains(pageName)) {
      await writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        currentValue.endsWith(';') || currentValue.endsWith(':')
            ? '$currentValue$pageName;'
            : '$currentValue;$pageName;',
      );
      return;
    }
  }

  static Future<void> unhidePageVisibilitySettings(String pageName) async {
    final String? currentValue = readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
      'SettingsPageVisibility',
    );

    if (currentValue == null || currentValue.isEmpty) return;

    if (currentValue.contains(pageName)) {
      String newValue = currentValue;

      if (currentValue == 'hide:$pageName') {
        await deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
        );
        return;
      } else if (currentValue.contains('$pageName;')) {
        newValue = newValue.replaceAll('$pageName;', '');
      } else if (currentValue.contains(';$pageName')) {
        newValue = newValue.replaceAll(';$pageName', '');
      }

      if (newValue == 'hide:' || newValue.isEmpty) {
        await deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
        );
      } else {
        await writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
          newValue,
        );
      }
    }
  }

  static Iterable<String> getUserServices(String subkey) {
    final RegistryKey key = Registry.openPath(
      RegistryHive.localMachine,
      path: r'SYSTEM\ControlSet001\Services',
    );
    try {
      return key.subkeyNames.where((final String e) => e.startsWith(subkey)).toList();
    } finally {
      key.close();
    }
  }

  static String? get themeModeReg => readString(
    RegistryHive.localMachine,
    r'SOFTWARE\Revision\Revision Tool',
    'ThemeMode',
  );

  static bool get themeTransparencyEffect =>
      readInt(
        RegistryHive.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        'EnableTransparency',
      ) ==
      1;

  static int? readInt(RegistryHive hive, String path, String value) {
    try {
      final RegistryKey key = Registry.openPath(hive, path: path);
      try {
        return key.getIntValue(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static String? readString(RegistryHive hive, String path, String value) {
    try {
      final RegistryKey key = Registry.openPath(hive, path: path);
      try {
        return key.getStringValue(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static List<String>? getStringArrayValue(
    RegistryHive hive,
    String path,
    String value,
  ) {
    try {
      final RegistryKey key = Registry.openPath(hive, path: path);
      try {
        return key.getStringArrayValue(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Uint8List? readBinary(RegistryHive hive, String path, String value) {
    try {
      final RegistryKey key = Registry.openPath(hive, path: path);
      try {
        return key.getBinaryValue(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeRegistryValue<T extends Object>(
    RegistryKey key,
    String path,
    String name,
    T value, {
    int retryCount = 0,
  }) async {
    final shouldClose = key != WinRegistryService.currentUser;

    try {
      final RegistryValue registryValue = switch (value) {
        final int v => RegistryValue.int32(name, v),
        final String v => RegistryValue.string(name, v),
        final List<String> v => RegistryValue.stringArray(name, v),

        // final List<int> v => RegistryValue.binary(name, Uint8List.fromList(v)),
        final Uint8List v => RegistryValue.binary(name, v),
        final _ => throw ArgumentError(
          '$tag(writeRegistryValue): Unsupported type: ${value.runtimeType}',
        ),
      };
      
      final RegistryKey subKey = key.createKey(path);
      try {
        subKey.createValue(registryValue);
      } finally {
        subKey.close();
      }
      logger.i('$tag(writeRegistryValue): $path\\$name = $value');

      if (key == WinRegistryService.currentUser) {
        await TrustedInstallerServiceImpl().executeCommand('reg', [
          'load',
          'HKU\\$defaultUser',
          defaultUserHivePath,
        ]);

        final RegistryKey reg = Registry.allUsers;
        try {
          final RegistryKey subKey = reg.createKey('$defaultUser\\$path');
          try {
            subKey.createValue(registryValue);
          } finally {
            subKey.close();
          }
          logger.i(
            '$tag(writeRegistryValue): $defaultUser\\$path\\$name = $value',
          );
        } finally {
          reg.close();
        }
      }
    } on WindowsException catch (e) {
      // 0x80070005 = ERROR_ACCESS_DENIED
      if (e.hr == -2147024891) {
        logger.w(
          '$tag(writeRegistryValue): Access denied (0x80070005), retrying with TrustedInstaller: $path\\$name',
        );
        try {
          if (retryCount > 0) {
            logger.e(
              '$tag(writeRegistryValue): Retry limit reached for TrustedInstaller: $path\\$name',
            );
            rethrow;
          }

          await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () async => writeRegistryValue<T>(
              key,
              path,
              name,
              value,
              retryCount: retryCount + 1,
            ),
          );
          return;
        } catch (tiError) {
          logger.e(
            '$tag(writeRegistryValue): Failed even with TrustedInstaller: $path\\$name',
            error: tiError,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      }
      logger.e(
        '$tag(writeRegistryValue): $path\\$name',
        error: e,
        stackTrace: StackTrace.current,
      );
    } catch (e) {
      logger.e(
        '$tag(writeRegistryValue): $path\\$name',
        error: e,
        stackTrace: StackTrace.current,
      );
    } finally {
      if (shouldClose) {
        key.close();
      }
    }
  }

  static Future<void> deleteValue(
    RegistryKey key,
    String path,
    String name, {
    int retryCount = 0,
  }) async {
    try {
      final RegistryKey subKey = key.createKey(path);
      try {
        subKey.deleteValue(name);
      } finally {
        subKey.close();
      }
      logger.i('$tag(deleteValue): $path\\$name');
    } on WindowsException catch (e) {
      // 0x80070005 = ERROR_ACCESS_DENIED
      if (e.hr == -2147024891) {
        logger.w(
          '$tag(deleteValue): Access denied (0x80070005), retrying with TrustedInstaller: $path\\$name',
        );
        try {
          if (retryCount > 0) {
            logger.e(
              '$tag(deleteValue): Retry limit reached for TrustedInstaller: $path\\$name',
            );
            rethrow;
          }

          await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () async =>
                deleteValue(key, path, name, retryCount: retryCount + 1),
          );
          return;
        } catch (tiError) {
          logger.e(
            '$tag(deleteValue): Failed even with TrustedInstaller: $path\\$name',
            error: tiError,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      }
      logger.e(
        '$tag(deleteValue): $path\\$name',
        error: e,
        stackTrace: StackTrace.current,
      );
    } catch (e) {
      logger.e(
        '$tag(deleteValue): $path\\$name',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  static Future<void> deleteKey(
    RegistryKey key,
    String path, {
    int retryCount = 0,
  }) async {
    try {
      key.deleteKey(path, recursive: true);
      logger.i('$tag(deleteKey): $path');
    } on WindowsException catch (e) {
      // 0x80070005 = ERROR_ACCESS_DENIED
      if (e.hr == -2147024891) {
        logger.w(
          '$tag(deleteKey): Access denied (0x80070005), retrying with TrustedInstaller: $path',
        );
        try {
          if (retryCount > 0) {
            logger.e(
              '$tag(deleteKey): Retry limit reached for TrustedInstaller: $path',
            );
            rethrow;
          }

          await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () async => deleteKey(key, path, retryCount: retryCount + 1),
          );
          return;
        } catch (tiError) {
          logger.e(
            '$tag(deleteKey): Failed even with TrustedInstaller: $path',
            error: tiError,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      }
      logger.e(
        '$tag(deleteKey): $path',
        error: e,
        stackTrace: StackTrace.current,
      );
    } catch (e) {
      logger.e(
        '$tag(deleteKey): $path',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  static void createKey(RegistryKey key, String path) {
    try {
      final RegistryKey subKey = key.createKey(path);
      subKey.close();
      logger.i('$tag(createKey): $path');
    } catch (e) {
      logger.e(
        '$tag(createKey): $path',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }
}
