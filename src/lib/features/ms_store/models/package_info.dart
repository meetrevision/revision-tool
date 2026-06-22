import 'package:freezed_annotation/freezed_annotation.dart';
import 'uwp/uwp_package.dart';

part 'package_info.freezed.dart';
part 'package_info.g.dart';

@freezed
sealed class PackageInfo with _$PackageInfo implements Comparable<PackageInfo> {
  factory PackageInfo({
    required final String id,
    required final bool isDependency,
    required final String uri,
    required final String arch,
    final FileModel? fileModel,
    final UpdateIdentity? updateIdentity,
    final String? commandLines,
  }) = _PackageInfo;
  const PackageInfo._();

  factory PackageInfo.fromJson(Map<String, dynamic> json) =>
      _$PackageInfoFromJson(json);

  @override
  int compareTo(PackageInfo other) {
    return fileModel!.fileName!.compareTo(other.fileModel!.fileName!);
  }
}

extension PackageInfoX on PackageInfo {
  String get progressName =>
      fileModel?.packageFullName ?? fileModel?.fileName ?? id;
  String get downloadName =>
      fileModel?.packageFullName ?? fileModel?.fileName ?? 'package_$id';
  String get fileExt => fileModel?.fileType ?? 'appx';

  int get expectedBytes => fileModel?.size ?? 0;
  String? get digest => fileModel?.verificationDigest;
  String? get algorithm => fileModel?.verificationDigestAlgorithm;

  bool get hasDigest =>
      (digest?.isNotEmpty ?? false) && (algorithm?.isNotEmpty ?? false);
}
