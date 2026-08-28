import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/uwp/uwp_package.dart';

part 'package_info.freezed.dart';

@freezed
sealed class const PackageInfo._() with _$PackageInfo implements Comparable<PackageInfo> {
  const factory({
    required String id,
    required bool isDependency,
    required String uri,
    required String arch,
    FileModel? fileModel,
    UpdateIdentity? updateIdentity,
    String? commandLines,
  }) = _PackageInfo;

  @override
  int compareTo(PackageInfo other) {
    final String a = fileModel?.fileName ?? id;
    final String b = other.fileModel?.fileName ?? other.id;
    return a.compareTo(b);
  }
}

extension PackageInfoX on PackageInfo {
  // Name shown in progress and file name.
  // Prefer packageFullName (e.g. SpotifyAB.SpotifyMusic_1.298.301.0_x64__...)
  // else fileName (e.g. 4ebe08fc...appx).
  String get progressName => fileModel?.packageFullName ?? fileModel?.fileName ?? id;
  String get downloadName => fileModel?.packageFullName ?? fileModel?.fileName ?? 'package_$id';
  String get fileExt => fileModel?.fileType ?? 'appx';

  int get expectedBytes => fileModel?.size ?? 0;

  // Hash for file verification on disk. Prefer SHA256.
  // Store returns SHA1 as Digest and SHA256 as AdditionalDigest.
  // Verify with SHA256 if present, else SHA1.
  String? get digest => fileModel?.verificationDigest;
  String? get algorithm => fileModel?.verificationDigestAlgorithm;

  // Hash for FE3 download URL lookup. Use raw SHA1 Digest.
  // FE3 FileLocation uses SHA1, not SHA256. Using SHA256 fails to match and falls back to first URL by accident.
  // So keep separate getter for correlation.
  String? get correlationDigest => fileModel?.digest;
  String? get correlationAlgorithm => fileModel?.digestAlgorithm;

  bool get hasDigest => (digest?.isNotEmpty ?? false) && (algorithm?.isNotEmpty ?? false);
}
