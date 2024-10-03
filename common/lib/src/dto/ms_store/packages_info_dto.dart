import 'package:freezed_annotation/freezed_annotation.dart';
part 'packages_info_dto.freezed.dart';
part 'packages_info_dto.g.dart';

@freezed
class MSStorePackagesInfoDTO
    with _$MSStorePackagesInfoDTO
    implements Comparable<MSStorePackagesInfoDTO> {
  MSStorePackagesInfoDTO._();

  factory MSStorePackagesInfoDTO(
      String? name,
      String? extension,
      String? uri,
      String? revisionNumber,
      String? updateID,
      String? id,
      double? size,
      String? digest,
      DateTime? lastModified,
      int? originalIndex,
      String? commandLines) = _MSStorePackagesInfoDTO;

  factory MSStorePackagesInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$MSStorePackagesInfoDTOFromJson(json);

  @override
  int compareTo(MSStorePackagesInfoDTO other) {
    return name!.compareTo(other.name!);
  }
}
