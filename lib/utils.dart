import 'dart:io';

import 'package:dio/dio.dart';
import 'package:win32_registry/win32_registry.dart';

String mainPath = Platform.resolvedExecutable;
String directoryExe = Directory("${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals").path;

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

class Network {
  static Future<Map<String, dynamic>> getJSON(String url) async {
    var response = await Dio().get(
      url,
      options: Options(
        headers: {
          "user-agent": "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
          "content-type": "application/json;charset=utf-8",
          "accept": "application/json",
        },
      ),
    );

    final responseJson = Map<String, dynamic>.from(response.data);

    if (response.statusCode == 200) {
      return responseJson;
    } else {
      throw Exception('Failed to load');
    }
  }

  static Future downloadNewVersion(String url, String path) async {
    await Dio().download(
      url,
      "$path\\RevisionTool-Setup.exe",
    );
    await openExeFile("$path\\RevisionTool-Setup.exe");
  }

  static Future<void> openExeFile(String filePath) async {
    await Process.start(filePath, ['/VERYSILENT', r'/TASKS="desktopicon"']);
    await File(filePath).delete();
  }
}
