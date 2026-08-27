import 'package:freezed_annotation/freezed_annotation.dart';

part 'uwp_package.freezed.dart';
part 'uwp_package.g.dart';

@freezed
sealed class UwpPackageResponse with _$UwpPackageResponse {
  const factory({required Set<UpdateModel> updates}) = _UwpPackageResponse;

  factory fromJson(Map<String, Object?> json) =>
      _$UwpPackageResponseFromJson(json);
}

@freezed
sealed class UpdateModel with _$UpdateModel {
  const factory({required String id, required ElementXml xml, String? arch}) =
      _UpdateModel;

  factory fromJson(Map<String, Object?> json) => _$UpdateModelFromJson(json);
}

@freezed
sealed class ElementXml with _$ElementXml {
  const factory({
    UpdateIdentity? updateIdentity,
    String? packageMoniker,
    ExtendedProperties? extendedProperties,
    required Set<FileModel> fileModel,
  }) = _ElementXml;

  factory fromJson(Map<String, Object?> json) => _$ElementXmlFromJson(json);
}

@freezed
sealed class UpdateIdentity with _$UpdateIdentity {
  const factory({required String id, required String revisionNumber}) =
      _UpdateIdentity;

  factory fromJson(Map<String, Object?> json) => _$UpdateIdentityFromJson(json);
}

@freezed
sealed class ExtendedProperties with _$ExtendedProperties {
  const factory({
    String? contentType,
    bool? isAppxFramework,
    DateTime? creationDate,
    String? packageIdentityName,
  }) = _ExtendedProperties;

  factory fromJson(Map<String, Object?> json) =>
      _$ExtendedPropertiesFromJson(json);
}

@freezed
sealed class FileModel with _$FileModel {
  const factory({
    String? fileName,
    String? fileType,
    String? packageFullName,
    String? digest,
    String? digestAlgorithm,
    String? additionalDigest,
    String? additionalDigestAlgorithm,
    int? size,
    DateTime? modifiedDate,
  }) = _FileModel;

  factory fromJson(Map<String, Object?> json) => _$FileModelFromJson(json);
}

extension FileModelDigestX on FileModel {
  String? get verificationDigest => additionalDigest ?? digest;

  String? get verificationDigestAlgorithm => additionalDigestAlgorithm ?? digestAlgorithm;
}
