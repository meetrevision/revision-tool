import 'package:freezed_annotation/freezed_annotation.dart';
part 'packages_info.freezed.dart';
part 'packages_info.g.dart';

@freezed
class PackagesInfo with _$PackagesInfo, Comparable<PackagesInfo> {
  PackagesInfo._();

  factory PackagesInfo(
      String? name,
      String? extension,
      String? uri,
      String? revisionNumber,
      String? updateID,
      String? id,
      double? size,
      String? digest,
      int? originalIndex,
      String? commandLines) = _PackagesInfo;

  factory PackagesInfo.fromJson(Map<String, dynamic> json) =>
      _$PackagesInfoFromJson(json);

  @override
  int compareTo(PackagesInfo other) {
    return name!.compareTo(other.name!);
  }
}
