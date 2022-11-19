import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

// returns the abolute path of the executable file of your app:
String mainPath = Platform.resolvedExecutable;

// nsudo path
Directory directoryExe = Directory("${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals");

// Experimental features
bool expBool = false;

int? readRegistryInt(RegistryHive hive, String path, String value) {
  return Registry.openPath(
    hive,
    path: path,
  ).getValueAsInt(value);
}

String? readRegistryString(RegistryHive hive, String path, String value) {
  return Registry.openPath(
    hive,
    path: path,
  ).getValueAsString(value);
}

void writeRegistryDword(RegistryKey key, String path, String name, int value) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var dword = RegistryValue(name, RegistryValueType.int32, value);

  subKey.createValue(dword);
}

void writeRegistryString(RegistryKey key, String path, String name, String value) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var string = RegistryValue(name, RegistryValueType.string, value);

  subKey.createValue(string);
}

void writeRegistryStringMultiSZ(RegistryKey key, String path, String name, String value) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var string = RegistryValue(name, RegistryValueType.stringArray, value);

  subKey.createValue(string);
}

void deleteRegistry(RegistryKey key, String path, String name) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  subKey.deleteValue(name);
}

void deleteRegistryKey(RegistryKey key, String path) {
  final regKey = key;
  var regPath = path;

  regKey.deleteKey(regPath);
}

void createRegistryKey(RegistryKey key, String path) {
  final regKey = key;
  var regPath = path;
  regKey.createKey(regPath);
}
