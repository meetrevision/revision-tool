import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_response.freezed.dart';
part 'update_response.g.dart';

@freezed
class UpdateResponse with _$UpdateResponse {
  const factory UpdateResponse({required Set<UpdateModel> updates}) =
      _UpdateResponse;

  factory UpdateResponse.fromJson(Map<String, Object?> json) =>
      _$UpdateResponseFromJson(json);
}

@freezed
class UpdateModel with _$UpdateModel {
  const factory UpdateModel({
    required final String id,
    required final ElementXml xml,
    String? arch,
  }) = _UpdateModel;

  factory UpdateModel.fromJson(Map<String, Object?> json) =>
      _$UpdateModelFromJson(json);
}

@freezed
class ElementXml with _$ElementXml {
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
class UpdateIdentity with _$UpdateIdentity {
  const factory UpdateIdentity({
    required String id,
    required String revisionNumber,
  }) = _UpdateIdentity;

  factory UpdateIdentity.fromJson(Map<String, Object?> json) =>
      _$UpdateIdentityFromJson(json);
}

@freezed
class ExtendedProperties with _$ExtendedProperties {
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
class FileModel with _$FileModel {
  const factory FileModel({
    String? fileName,
    String? fileType, // custom
    String? packageFullName, //PackageFullName
    String? digest,
    String? digestAlgorithm,
    int? size,
    DateTime? modifiedDate,
  }) = _FileModel;

  factory FileModel.fromJson(Map<String, Object?> json) =>
      _$FileModelFromJson(json);
}
