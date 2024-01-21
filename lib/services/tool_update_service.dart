import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ToolUpdateService {
  static final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;

  static final _dio = Dio();
  static final _options = Options(
    headers: {
      "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0",
      "content-type": "application/json;charset=utf-8",
      "accept": "application/json",
    },
  );

  static const _githubAPI =
      "https://api.github.com/repos/meetrevision/revision-tool/releases/latest";

  static final _tempDir = Directory.systemTemp;
  static final _packageInfo = PackageInfo.fromPlatform();

  static const _instance = ToolUpdateService._private();
  factory ToolUpdateService() {
    return _instance;
  }
  const ToolUpdateService._private();

  Future<void> fetchData() async {
    if (_data.isNotEmpty) {
      _data.clear();
    }

    final response = await _dio.get(_githubAPI, options: _options);

    final responseJson = Map<String, dynamic>.from(response.data);
    _data.addAll(responseJson);
  }

  Future<int> get getCurrentVersion async => int.parse(
      await _packageInfo.then((value) => value.version.replaceAll(".", "")));

  int get getLatestVersion {
    if (_data.isEmpty) {
      e("The fetched API data variable is empty");
      return -1;
    }
    return int.parse(_data["tag_name"].toString().replaceAll(".", ""));
  }

  Future<void> downloadNewVersion() async {
    final path = "${_tempDir.path}\\RevisionTool-Setup.exe";
    final download = await _dio.download(
      data["assets"][0]["browser_download_url"],
      path,
    );
    v("New Revision Tool download status: ${download.statusMessage}");
  }

  Future<void> installUpdate() async {
    final path = "${_tempDir.path}\\RevisionTool-Setup.exe";
    await Process.start(
      path,
      ['/VERYSILENT', '/RESTARTAPPLICATIONS', r'/TASKS="desktopicon"'],
    );

    await File(path).delete();
  }
}
