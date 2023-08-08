import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';

import 'package:dio/dio.dart';
import 'package:win32_registry/win32_registry.dart';

const ListEquality eq = ListEquality();

final int buildNumber = int.parse(readRegistryString(
    RegistryHive.localMachine,
    r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
    'CurrentBuildNumber') as String);

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals")
    .path;

final bool w11 = buildNumber > 19045;
bool expBool = readRegistryInt(RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Experimental') ==
    1;
String? themeModeReg = readRegistryString(
    RegistryHive.localMachine, r'SOFTWARE\Revision\Revision Tool', 'ThemeMode');

String appLanguage = readRegistryString(
    RegistryHive.localMachine, r'SOFTWARE\Revision\Revision Tool', 'Language',) ?? 'en_US';

int? readRegistryInt(RegistryHive hive, String path, String value) {
  try {
    return Registry.openPath(
      hive,
      path: path,
    ).getValueAsInt(value);
  } catch (_) {
    return null;
  }
}

String? readRegistryString(RegistryHive hive, String path, String value) {
  try {
    return Registry.openPath(
      hive,
      path: path,
    ).getValueAsString(value);
  } catch (_) {
    return null;
  }
}

Uint8List? readRegistryBinary(RegistryHive hive, String path, String value) {
  try {
    return Registry.openPath(
      hive,
      path: path,
    ).getValue(value)!.data as Uint8List;
  } catch (_) {
    return null;
  }
}

Future<void> writeRegistryDword(
    RegistryKey key, String path, String name, int value) async {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var dword = RegistryValue(name, RegistryValueType.int32, value);

  subKey.createValue(dword);
}

void writeRegistryString(
    RegistryKey key, String path, String name, String value) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var string = RegistryValue(name, RegistryValueType.string, value);

  subKey.createValue(string);
}

void writeRegistryStringMultiSZ(
    RegistryKey key, String path, String name, String value) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var string = RegistryValue(name, RegistryValueType.stringArray, value);

  subKey.createValue(string);
}

void writeRegistryBinary(
    RegistryKey key, String path, String name, List<int> value) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  var bin = RegistryValue(name, RegistryValueType.binary, value);

  subKey.createValue(bin);
}

void deleteRegistry(RegistryKey key, String path, String name) {
  final regKey = key;
  var regPath = path;
  final subKey = regKey.createKey(regPath);

  try {
    subKey.deleteValue(name);
  } catch (_) {}
}

void deleteRegistryKey(RegistryKey key, String path) {
  final regKey = key;
  var regPath = path;
  try {
    regKey.deleteKey(regPath);
  } catch (_) {}
}

void createRegistryKey(RegistryKey key, String path) {
  final regKey = key;
  var regPath = path;
  try {
    regKey.createKey(regPath);
  } catch (_) {}
}

class Network {
  static Future<Map<String, dynamic>> getJSON(String url) async {
    var response = await Dio().get(
      url,
      options: Options(
        headers: {
          "user-agent":
              "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
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
    await Process.start(filePath,
        ['/VERYSILENT', '/RESTARTAPPLICATIONS', r'/TASKS="desktopicon"']);
    await File(filePath).delete();
  }
}
