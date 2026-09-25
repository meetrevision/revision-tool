import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../domain/entities/win_package.dart';
import 'release_asset_model.dart';

/// Mirrors the GitHub release API response for the CAB packages repository.
final class const ReleaseModel({
  required final String tagName,
  required final IList<ReleaseAssetModel> assets,
}) {
  factory fromJson(Map<String, dynamic> json) {
    if (json case {'tag_name': final String tagName, 'assets': final List<dynamic> rawAssets}) {
      return .new(
        tagName: tagName,
        assets: rawAssets
            .map((e) => ReleaseAssetModel.fromJson(e as Map<String, dynamic>))
            .toIList(),
      );
    }
    throw FormatException('Could not deserialize ReleaseModel, json=$json');
  }

  WinPackageRelease toDomain() {
    return .new(tagName: tagName, assets: assets.map((a) => a.toDomain()).toIList());
  }
}
