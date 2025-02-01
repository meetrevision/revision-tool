import 'dart:typed_data';

import 'package:common/src/utils.dart';
import 'package:win32_registry/win32_registry.dart';

class WinRegistryService {
  const WinRegistryService._private();

  static int get buildNumber => _buildNumber;
  static final int _buildNumber = int.parse(WinRegistryService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
      'CurrentBuildNumber')!);

  static bool get isW11 => _w11;
  static final bool _w11 = buildNumber > 19045;

  static final String cpuArch = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
          'PROCESSOR_ARCHITECTURE')!
      .toLowerCase();

  static bool get isSupported {
    return _validate() ||
        readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
                'EditionSubVersion') ==
            'ReviOS' ||
        readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
                'EditionSubManufacturer') ==
            'MeetRevision';
  }

  static bool _validate() {
    final key = Registry.openPath(RegistryHive.localMachine,
        path:
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages');

    try {
      return key.subkeyNames
          .lastWhere((element) => element.startsWith("Revision-ReviOS"))
          .isNotEmpty;
    } catch (e) {
      logger.w('Error validating ReviOS');
      return false;
    }
  }

  static void hidePageVisibilitySettings(String pageName) {
    final currentValue = readString(
        RegistryHive.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility');

    if (currentValue == null || currentValue.isEmpty) {
      writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
          "hide:$pageName");
      return;
    }
    if (!currentValue.contains(pageName)) {
      writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
          currentValue.endsWith(";") || currentValue.endsWith(":")
              ? "$currentValue$pageName;"
              : "$currentValue;$pageName;");
      return;
    }
  }

  static Iterable<String> getUserServices(String subkey) {
    return Registry.openPath(RegistryHive.localMachine,
            path: r'SYSTEM\ControlSet001\Services')
        .subkeyNames
        .where((final e) => e.startsWith(subkey));
  }

  static String? get themeModeReg => WinRegistryService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'ThemeMode');

  static bool get themeTransparencyEffect =>
      WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
          'EnableTransparency') ==
      1;

  static int? readInt(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(
        hive,
        path: path,
      ).getIntValue(value);
    } catch (_) {
      // w('Error reading $value from ${hive.name} $path');
      return null;
    }
  }

  static String? readString(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(
        hive,
        path: path,
      ).getStringValue(value);
    } catch (_) {
      // w('Error reading $value from ${hive.name} $path');
      return null;
    }
  }

  static Uint8List? readBinary(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(
        hive,
        path: path,
      ).getBinaryValue(value);
    } catch (_) {
      // w('Error reading binary $value from $path');
      return null;
    }
  }

  static Future<void> writeRegistryValue(
      RegistryKey key, String path, String name, dynamic value) async {
    try {
      final registryValue = switch (value) {
        final int v => RegistryValue.int32(name, v),
        final String v => RegistryValue.string(name, v),
        final List<String> v => RegistryValue.stringArray(name, v),
        // final List<int> v => RegistryValue.binary(name, Uint8List.fromList(v)),
        final Uint8List v => RegistryValue.binary(name, v),
        final _ =>
          throw ArgumentError('Unsupported type: ${value.runtimeType}'),
      };
      key.createKey(path).createValue(registryValue);
      logger.i('Added $name: $value to $path');
    } catch (e) {
      logger.w('Error writing $name - $e');
    }
  }

  static void deleteValue(RegistryKey key, String path, String name) {
    try {
      key.createKey(path).deleteValue(name);
      logger.i('Deleted $name from $path');
    } catch (_) {
      logger.w('Error deleting $name from $path');
    }
  }

  static void deleteKey(RegistryKey key, String path) {
    try {
      key.deleteKey(path);
      logger.i('Deleted $path');
    } catch (e) {
      logger.w('Error deleting $path');
    }
  }

  static void createKey(RegistryKey key, String path) {
    try {
      key.createKey(path);
      logger.i('Created $path');
    } catch (_) {
      logger.w('Error creating $path');
    }
  }
}
