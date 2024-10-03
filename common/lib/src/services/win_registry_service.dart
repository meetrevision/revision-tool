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
      ).getValueAsInt(value);
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
      ).getValueAsString(value);
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
      ).getValue(value)!.data as Uint8List;
    } catch (_) {
      // w('Error reading binary $value from $path');
      return null;
    }
  }

  static Future<void> writeDword(
      RegistryKey key, String path, String name, int value) async {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var dword = RegistryValue(name, RegistryValueType.int32, value);

    try {
      subKey.createValue(dword);
      logger.i('Added $name with $value to $path');
    } catch (e) {
      logger.w('Error writing $name - $e');
    }
  }

  static void writeString(
      RegistryKey key, String path, String name, String value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var string = RegistryValue(name, RegistryValueType.string, value);

    try {
      subKey.createValue(string);
      logger.i('Added $name with $value to $path');
    } catch (e) {
      logger.w('Error writing $name - $e');
    }
  }

  static void writeStringMultiSZ(
      RegistryKey key, String path, String name, String value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var string = RegistryValue(name, RegistryValueType.stringArray, value);

    try {
      subKey.createValue(string);
      logger.i('Added $name with $value to $path');
    } catch (e) {
      logger.w('Error writing $name - $e');
    }
  }

  static void writeBinary(
      RegistryKey key, String path, String name, List<int> value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var bin = RegistryValue(name, RegistryValueType.binary, value);
    try {
      subKey.createValue(bin);
    } catch (e) {
      logger.w('Error writing $name - $e');
    }
  }

  static void deleteValue(RegistryKey key, String path, String name) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    try {
      subKey.deleteValue(name);
      logger.i('Deleted $name from $path');
    } catch (_) {
      logger.w('Error deleting $name from $path');
    }
  }

  static void deleteKey(RegistryKey key, String path) {
    final regKey = key;
    var regPath = path;
    try {
      regKey.deleteKey(regPath);
      logger.i('Deleted $path');
    } catch (e) {
      logger.w('Error deleting $path');
    }
  }

  static void createKey(RegistryKey key, String path) {
    final regKey = key;
    var regPath = path;
    try {
      regKey.createKey(regPath);
      logger.i('Created $path');
    } catch (_) {
      logger.w('Error creating $path');
    }
  }
}
