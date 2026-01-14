import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:revitool/utils.dart';

enum ApiEndpoints {
  revisionTool(api: 'meetrevision/revision-tool'),
  cabPackages(api: 'meetrevision/packages');

  const ApiEndpoints({required this.api});

  final String api;
}

class NetworkService {
  static const tag = 'NetworkService';
  final _dio = Dio();

  NetworkService() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
        HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
  }

  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      logger.i('$tag(get): $path');
      return await _dio.get(path, options: options, cancelToken: cancelToken);
    } on DioException catch (e) {
      logger.e(
        '$tag(get): Failed to connect to $path',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    final String path, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onReceiveProgress,
  }) async {
    try {
      logger.i('$tag(post): $path');
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      logger.e(
        '$tag(post): Failed to connect to $path',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGHLatestRelease(ApiEndpoints endpoint) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/${endpoint.api}/releases/latest',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e(
        '$tag(getGHLatestRelease): Failed to connect to the GitHub API; Please check your internet connection.',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  Future<Response<dynamic>> downloadFile(
    String url,
    String downloadPath,
  ) async {
    try {
      logger.i('$tag(downloadFile): Downloading $url to $downloadPath');
      final response = await _dio.download(url, downloadPath);
      logger.i('$tag(downloadFile): Download completed');
      return response;
    } on DioException catch (e) {
      logger.e(
        '$tag(downloadFile): Failed to download file from $url',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
}
