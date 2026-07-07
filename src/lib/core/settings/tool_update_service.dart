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

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
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
  static const _installerAssetName = 'RevisionTool-Setup.exe';
  static const _versionSegmentCount = 3;
  static const _versionSegmentWidth = 1000;

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

    return versionComparableValue(appVersion);
  }

  int get getLatestVersion {
    if (_data.isEmpty) {
      logger.e('The fetched API data variable is empty');
      return -1;
    }
    return versionComparableValue(_data['tag_name'].toString());
  }

  String get installerAssetDownloadUrl {
    final Map<String, dynamic> asset = _installerAsset;
    return asset['browser_download_url'] as String;
  }

  Future<void> downloadNewVersion() async {
    final path = '${_tempDir.path}\\RevisionTool-Setup.exe';
    final Response<dynamic> download = await _dio.download(
      installerAssetDownloadUrl,
      path,
    );
    logger.i('New Revision Tool download status: ${download.statusMessage}');
  }

  Future<void> installUpdate() async {
    final installerPath = '${_tempDir.path}\\RevisionTool-Setup.exe';
    final String appPath = Platform.resolvedExecutable;
    final scriptPath = '${_tempDir.path}\\revitool_update.cmd';

    File(scriptPath).writeAsStringSync(
      '@echo off\r\n'
      '"$installerPath" /VERYSILENT /TASKS="desktopicon"\r\n'
      'start "" "$appPath"\r\n',
    );

    await Process.start(scriptPath, [], mode: ProcessStartMode.detached);
    exit(0);
  }

  static int versionComparableValue(String version) {
    final String normalizedVersion = version.trim().replaceFirst(
      RegExp('^[vV]'),
      '',
    );
    final String coreVersion = normalizedVersion.split(RegExp(r'[-+]')).first;
    final List<String> segments = coreVersion.split('.');
    var comparableValue = 0;

    for (var index = 0; index < _versionSegmentCount; index++) {
      final String segment = index < segments.length ? segments[index] : '0';
      final int segmentValue = int.parse(segment.isEmpty ? '0' : segment);
      if (segmentValue >= _versionSegmentWidth) {
        throw FormatException('Version segment is too large', version);
      }
      comparableValue =
          (comparableValue * _versionSegmentWidth) + segmentValue;
    }

    return comparableValue;
  }

  Map<String, dynamic> get _installerAsset {
    final assetList = List<Map<String, dynamic>>.from(
      _data['assets'] as List<dynamic>,
    );

    for (final asset in assetList) {
      if (_isInstallerAsset(asset)) {
        return asset;
      }
    }

    throw StateError('No Revision Tool installer asset found in release data');
  }

  static bool _isInstallerAsset(Map<String, dynamic> asset) {
    final String name = (asset['name'] as String? ?? '').toLowerCase();
    final downloadUrl = asset['browser_download_url'] as String?;

    return downloadUrl != null &&
        downloadUrl.isNotEmpty &&
        (name == _installerAssetName.toLowerCase() ||
            (name.endsWith('.exe') &&
                name.contains('revisiontool') &&
                name.contains('setup')));
  }
}
