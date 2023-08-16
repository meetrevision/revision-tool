import 'dart:io';

import 'package:dio/dio.dart';

class Network {
  static final Network _instance = Network._private();

  static final _dio = Dio();
  static final _options = Options(
    headers: {
      "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
      "content-type": "application/json;charset=utf-8",
      "accept": "application/json",
    },
  );

  factory Network() {
    return _instance;
  }

  Network._private();

  static Future<Map<String, dynamic>> getJSON(String url) async {
    var response = await _dio.get(url, options: _options);

    final responseJson = Map<String, dynamic>.from(response.data);

    if (response.statusCode == 200) {
      return responseJson;
    } else {
      throw Exception('Failed to load');
    }
  }

  static Future downloadNewVersion(String url, String path) async {
    await _dio.download(
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
