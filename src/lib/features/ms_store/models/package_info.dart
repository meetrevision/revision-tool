import 'package:freezed_annotation/freezed_annotation.dart';

import 'uwp/uwp_package.dart';

part 'package_info.freezed.dart';
part 'package_info.g.dart';

@freezed
sealed class const PackageInfo._() with _$PackageInfo implements Comparable<PackageInfo> {
  factory({
    required String id,
    required bool isDependency,
    required String uri,
    required String arch,
    FileModel? fileModel,
    UpdateIdentity? updateIdentity,
    String? commandLines,
  }) = _PackageInfo;

  factory fromJson(Map<String, dynamic> json) => _$PackageInfoFromJson(json);

  @override
  int compareTo(PackageInfo other) {
    return fileModel!.fileName!.compareTo(other.fileModel!.fileName!);
  }
}

extension PackageInfoX on PackageInfo {
  String get progressName => fileModel?.packageFullName ?? fileModel?.fileName ?? id;
  String get downloadName => fileModel?.packageFullName ?? fileModel?.fileName ?? 'package_$id';
  String get fileExt => fileModel?.fileType ?? 'appx';

  int get expectedBytes => fileModel?.size ?? 0;
  String? get digest => fileModel?.verificationDigest;
  String? get algorithm => fileModel?.verificationDigestAlgorithm;

  bool get hasDigest => (digest?.isNotEmpty ?? false) && (algorithm?.isNotEmpty ?? false);
}
