import '../../domain/entities/win_package.dart';

/// Mirrors one entry of the `assets` array in the GitHub release API response.
final class const ReleaseAssetModel({
  required final String name,
  required final String browserDownloadUrl,
}) {
  factory fromJson(Map<String, dynamic> json) {
    if (json case {
      'name': final String name,
      'browser_download_url': final String browserDownloadUrl,
    }) {
      return .new(name: name, browserDownloadUrl: browserDownloadUrl);
    }
    throw FormatException('Could not deserialize ReleaseAssetModel, json=$json');
  }

  CabAsset toDomain() {
    return .new(name: name, downloadUrl: browserDownloadUrl);
  }
}
