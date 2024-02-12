import 'package:mixin_logger/mixin_logger.dart';
import 'package:win32_registry/win32_registry.dart';
import 'dart:typed_data';

class RegistryUtilsService {
  static const _instance = RegistryUtilsService._private();
  factory RegistryUtilsService() {
    return _instance;
  }
  const RegistryUtilsService._private();

  int? readInt(RegistryHive hive, String path, String value) {
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

  String? readString(RegistryHive hive, String path, String value) {
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

  Uint8List? readBinary(RegistryHive hive, String path, String value) {
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

  Future<void> writeDword(
      RegistryKey key, String path, String name, int value) async {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var dword = RegistryValue(name, RegistryValueType.int32, value);

    try {
      subKey.createValue(dword);
      v('Added $name with $value to $path');
    } catch (e) {
      w('Error writing $name - $e');
    }
  }

  void writeString(RegistryKey key, String path, String name, String value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var string = RegistryValue(name, RegistryValueType.string, value);

    try {
      subKey.createValue(string);
      v('Added $name with $value to $path');
    } catch (e) {
      w('Error writing $name - $e');
    }
  }

  void writeStringMultiSZ(
      RegistryKey key, String path, String name, String value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var string = RegistryValue(name, RegistryValueType.stringArray, value);

    try {
      subKey.createValue(string);
      v('Added $name with $value to $path');
    } catch (e) {
      w('Error writing $name - $e');
    }
  }

  void writeBinary(RegistryKey key, String path, String name, List<int> value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var bin = RegistryValue(name, RegistryValueType.binary, value);
    try {
      subKey.createValue(bin);
    } catch (e) {
      w('Error writing $name - $e');
    }
  }

  void deleteValue(RegistryKey key, String path, String name) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    try {
      subKey.deleteValue(name);
      v('Deleted $name from $path');
    } catch (_) {
      w('Error deleting $name from $path');
    }
  }

  void deleteKey(RegistryKey key, String path) {
    final regKey = key;
    var regPath = path;
    try {
      regKey.deleteKey(regPath);
      v('Deleted $path');
    } catch (_) {
      w('Error deleting $path');
    }
  }

  void createKey(RegistryKey key, String path) {
    final regKey = key;
    var regPath = path;
    try {
      regKey.createKey(regPath);
      v('Created $path');
    } catch (_) {
      w('Error creating $path');
    }
  }
}
