import 'package:freezed_annotation/freezed_annotation.dart';
import 'update_response.dart';
part 'packages_info_dto.freezed.dart';
part 'packages_info_dto.g.dart';

@freezed
sealed class MSStorePackagesInfoDTO
    with _$MSStorePackagesInfoDTO
    implements Comparable<MSStorePackagesInfoDTO> {

  factory MSStorePackagesInfoDTO({
    required final String id,
    required final bool isDependency,
    required final String uri,
    required final String arch,
    final FileModel? fileModel,
    final UpdateIdentity? updateIdentity,
    final String? commandLines,
  }) = _MSStorePackagesInfoDTO;
  MSStorePackagesInfoDTO._();

  factory MSStorePackagesInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$MSStorePackagesInfoDTOFromJson(json);

  @override
  int compareTo(MSStorePackagesInfoDTO other) {
    return fileModel!.fileName!.compareTo(other.fileModel!.fileName!);
  }
}
