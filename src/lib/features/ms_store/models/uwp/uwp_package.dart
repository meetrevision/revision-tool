import 'package:freezed_annotation/freezed_annotation.dart';

part 'uwp_package.freezed.dart';
part 'uwp_package.g.dart';

@freezed
sealed class UwpPackageResponse with _$UwpPackageResponse {
  const factory UwpPackageResponse({required Set<UpdateModel> updates}) =
      _UwpPackageResponse;

  factory UwpPackageResponse.fromJson(Map<String, Object?> json) =>
      _$UwpPackageResponseFromJson(json);
}

@freezed
sealed class UpdateModel with _$UpdateModel {
  const factory UpdateModel({
    required final String id,
    required final ElementXml xml,
    String? arch,
  }) = _UpdateModel;

  factory UpdateModel.fromJson(Map<String, Object?> json) =>
      _$UpdateModelFromJson(json);
}

@freezed
sealed class ElementXml with _$ElementXml {
  const factory ElementXml({
    UpdateIdentity? updateIdentity,
    String? packageMoniker,
    ExtendedProperties? extendedProperties,
    required Set<FileModel> fileModel,
  }) = _ElementXml;

  factory ElementXml.fromJson(Map<String, Object?> json) =>
      _$ElementXmlFromJson(json);
}

@freezed
sealed class UpdateIdentity with _$UpdateIdentity {
  const factory UpdateIdentity({
    required String id,
    required String revisionNumber,
  }) = _UpdateIdentity;

  factory UpdateIdentity.fromJson(Map<String, Object?> json) =>
      _$UpdateIdentityFromJson(json);
}

@freezed
sealed class ExtendedProperties with _$ExtendedProperties {
  const factory ExtendedProperties({
    String? contentType,
    bool? isAppxFramework,
    DateTime? creationDate,
    String? packageIdentityName,
  }) = _ExtendedProperties;

  factory ExtendedProperties.fromJson(Map<String, Object?> json) =>
      _$ExtendedPropertiesFromJson(json);
}

@freezed
sealed class FileModel with _$FileModel {
  const factory FileModel({
    String? fileName,
    String? fileType,
    String? packageFullName,
    String? digest,
    String? digestAlgorithm,
    int? size,
    DateTime? modifiedDate,
  }) = _FileModel;

  factory FileModel.fromJson(Map<String, Object?> json) =>
      _$FileModelFromJson(json);
}
