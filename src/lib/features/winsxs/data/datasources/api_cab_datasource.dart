import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_endpoints.dart';
import '../../domain/winsxs_exceptions.dart';
import '../models/release_model.dart';

/// Reads CAB package data from the GitHub release API. Throws on failure.
final class const ApiCabDataSource({required final ApiClient api}) {
  Future<ReleaseModel> fetchLatestRelease() async {
    final Response<Map<String, dynamic>> response = await api
        .get<Map<String, dynamic>>(
          NetworkEndpoints.githubLatestRelease(GitHubRepositoryEndpoint.cabPackages),
        )
        .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

    if (response.data case final json?) {
      return .fromJson(json);
    }
    throw WinSxSPackageDownloadException('Empty release response from GitHub');
  }

  Future<void> downloadFile({required String url, required String filePath}) => api
      .downloadFile(Uri.parse(url), filePath)
      .then((r) => r.when(success: (_) {}, failure: (e) => throw e));
}
