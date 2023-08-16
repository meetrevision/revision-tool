import 'package:win32_registry/win32_registry.dart';
import 'dart:typed_data';

class RegistryUtilsService {
  static final RegistryUtilsService _instance = RegistryUtilsService._private();

  factory RegistryUtilsService() {
    return _instance;
  }

  RegistryUtilsService._private();

  int? readInt(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(
        hive,
        path: path,
      ).getValueAsInt(value);
    } catch (_) {
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
      return null;
    }
  }

  Future<void> writeDword(
      RegistryKey key, String path, String name, int value) async {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var dword = RegistryValue(name, RegistryValueType.int32, value);

    subKey.createValue(dword);
  }

  void writeString(RegistryKey key, String path, String name, String value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var string = RegistryValue(name, RegistryValueType.string, value);

    subKey.createValue(string);
  }

  void writeStringMultiSZ(
      RegistryKey key, String path, String name, String value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var string = RegistryValue(name, RegistryValueType.stringArray, value);

    subKey.createValue(string);
  }

  void writeBinary(RegistryKey key, String path, String name, List<int> value) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    var bin = RegistryValue(name, RegistryValueType.binary, value);

    subKey.createValue(bin);
  }

  void deleteValue(RegistryKey key, String path, String name) {
    final regKey = key;
    var regPath = path;
    final subKey = regKey.createKey(regPath);

    try {
      subKey.deleteValue(name);
    } catch (_) {}
  }

  void deleteKey(RegistryKey key, String path) {
    final regKey = key;
    var regPath = path;
    try {
      regKey.deleteKey(regPath);
    } catch (_) {}
  }

  void createKey(RegistryKey key, String path) {
    final regKey = key;
    var regPath = path;
    try {
      regKey.createKey(regPath);
    } catch (_) {}
  }
}
