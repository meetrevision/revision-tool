import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'uwp_package.freezed.dart';
part 'uwp_package.g.dart';

@freezed
@immutable
sealed class const UwpPackageResponse._() with _$UwpPackageResponse {
  const factory({required ISet<UpdateModel> updates}) = _UwpPackageResponse;

  factory fromJson(Map<String, Object?> json) => _$UwpPackageResponseFromJson(json);

  // Custom == backs freezed's DeepCollectionEquality off (see `equal` in
  // freezed_annotation): ISet already compares by value with a cached-hash
  // O(1) mismatch fast path, so a deep walk would only be slower.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UwpPackageResponse && other.runtimeType == runtimeType && other.updates == updates;

  @override
  int get hashCode => Object.hash(runtimeType, updates);
}

@freezed
sealed class UpdateModel with _$UpdateModel {
  const factory({required String id, required ElementXml xml, String? arch}) = _UpdateModel;

  factory fromJson(Map<String, Object?> json) => _$UpdateModelFromJson(json);
}

@freezed
@immutable
sealed class const ElementXml._() with _$ElementXml {
  const factory({
    UpdateIdentity? updateIdentity,
    String? packageMoniker,
    ExtendedProperties? extendedProperties,
    required ISet<FileModel> fileModel,
  }) = _ElementXml;

  factory fromJson(Map<String, Object?> json) => _$ElementXmlFromJson(json);

  // Same as above: direct == keeps ISet's cached-hash fast path.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementXml &&
          other.runtimeType == runtimeType &&
          other.updateIdentity == updateIdentity &&
          other.packageMoniker == packageMoniker &&
          other.extendedProperties == extendedProperties &&
          other.fileModel == fileModel;

  @override
  int get hashCode =>
      Object.hash(runtimeType, updateIdentity, packageMoniker, extendedProperties, fileModel);
}

@freezed
sealed class UpdateIdentity with _$UpdateIdentity {
  const factory({required String id, required String revisionNumber}) = _UpdateIdentity;

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

  factory fromJson(Map<String, Object?> json) => _$ExtendedPropertiesFromJson(json);
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
