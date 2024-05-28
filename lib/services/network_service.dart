import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

enum ApiEndpoints {
  revisionTool(api: 'meetrevision/revision-tool'),
  cabPackages(api: 'meetrevision/packages');

  const ApiEndpoints({
    required this.api,
  });

  final String api;
}

class NetworkService {
  static final _dio = Dio();

  NetworkService() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
  }

  Future<Map<String, dynamic>> getGHLatestRelease(ApiEndpoints endpoint) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/${endpoint.api}/releases/latest',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
          'Failed to connect to the GitHub API.\n\nPlease ensure you have an active internet connection and try again.');
    }
  }

  Future<Response<dynamic>> downloadFile(
      String url, String downloadPath) async {
    try {
      final response = await _dio.download(
        url,
        downloadPath,
      );
      stdout.writeln('Downloaded $url - ${response.statusCode}');
      return response;
    } catch (e) {
      throw Exception(
          'Failed to download.\n\nPlease ensure you have an active internet connection and try again.');
    }
  }
}
