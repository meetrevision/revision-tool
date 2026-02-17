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
  PackageInfo._();

  factory PackageInfo.fromJson(Map<String, dynamic> json) =>
      _$PackageInfoFromJson(json);

  @override
  int compareTo(PackageInfo other) {
    return fileModel!.fileName!.compareTo(other.fileModel!.fileName!);
  }
}
