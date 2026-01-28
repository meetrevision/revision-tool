import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils.dart';

class ToolUpdateService {
  factory ToolUpdateService() {
    return _instance;
  }
  const ToolUpdateService._private();
  static final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;

  static final _dio = Dio();
  static final _options = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'content-type': 'application/json;charset=utf-8',
      'accept': 'application/json',
    },
  );

  static const _githubAPI =
      'https://api.github.com/repos/meetrevision/revision-tool/releases/latest';

  static final Directory _tempDir = Directory.systemTemp;

  static const _instance = ToolUpdateService._private();

  Future<void> fetchData() async {
    if (_data.isNotEmpty) {
      _data.clear();
    }

    final Response<dynamic> response = await _dio.get(
      _githubAPI,
      options: _options,
    );

    final responseJson = Map<String, dynamic>.from(
      response.data as Map<String, dynamic>,
    );
    _data.addAll(responseJson);
  }

  int get getCurrentVersion {
    const appVersion = String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '1.0.0',
    );

    return int.parse(appVersion.replaceAll('.', ''));
  }

  int get getLatestVersion {
    if (_data.isEmpty) {
      logger.e('The fetched API data variable is empty');
      return -1;
    }
    return int.parse(_data['tag_name'].toString().replaceAll('.', ''));
  }

  Future<void> downloadNewVersion() async {
    final path = '${_tempDir.path}\\RevisionTool-Setup.exe';
    final assetList = List<Map<String, dynamic>>.from(
      _data['assets'] as List<dynamic>,
    );
    final Response<dynamic> download = await _dio.download(
      assetList.first['browser_download_url'] as String,
      path,
    );
    logger.i('New Revision Tool download status: ${download.statusMessage}');
  }

  Future<void> installUpdate() async {
    final path = '${_tempDir.path}\\RevisionTool-Setup.exe';
    await Process.start(path, [
      '/VERYSILENT',
      '/RESTARTAPPLICATIONS',
      r'/TASKS="desktopicon"',
    ]);

    await File(path).delete();
  }
}
