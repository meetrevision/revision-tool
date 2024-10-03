// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
part 'non_uwp_response_dto.freezed.dart';
part 'non_uwp_response_dto.g.dart';

@freezed
class MSStoreNonUWPResponseDTO with _$MSStoreNonUWPResponseDTO {
  const factory MSStoreNonUWPResponseDTO({
    @JsonKey(name: "Data") Data? data,
  }) = _MSStoreNonUWPResponseDTO;

  factory MSStoreNonUWPResponseDTO.fromJson(Map<String, Object?> json) =>
      _$MSStoreNonUWPResponseDTOFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "PackageIdentifier") String? packageIdentifier,
    @JsonKey(name: "Versions") List<Versions>? versions,
  }) = _Data;

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);
}

@freezed
class Versions with _$Versions {
  const factory Versions({
    @JsonKey(name: "PackageVersion") String? packageVersion,
    @JsonKey(name: "DefaultLocale") DefaultLocale? defaultLocale,
    @JsonKey(name: "Installers") List<Installers>? installers,
  }) = _Versions;

  factory Versions.fromJson(Map<String, Object?> json) =>
      _$VersionsFromJson(json);
}

@freezed
class DefaultLocale with _$DefaultLocale {
  const factory DefaultLocale({
    @JsonKey(name: 'PackageName') String? packageName,
  }) = _DefaultLocale;

  factory DefaultLocale.fromJson(Map<String, Object?> json) =>
      _$DefaultLocaleFromJson(json);
}

@freezed
class Installers with _$Installers {
  const factory Installers({
    @JsonKey(name: "InstallerSha256") String? installerSha256,
    @JsonKey(name: "InstallerUrl") String? installerUrl,
    @JsonKey(name: "InstallerLocale") String? installerLocale,
    @JsonKey(name: "MinimumOSVersion") String? minimumOSVersion,
    @JsonKey(name: "InstallerSwitches") InstallerSwitches? installerSwitches,
    @JsonKey(name: "Architecture") String? architecture,
    @JsonKey(name: "InstallerType") String? installerType,
  }) = _Installers;

  factory Installers.fromJson(Map<String, Object?> json) =>
      _$InstallersFromJson(json);
}

@freezed
class InstallerSwitches with _$InstallerSwitches {
  const factory InstallerSwitches({
    @JsonKey(name: "Silent") String? silent,
  }) = _InstallerSwitches;

  factory InstallerSwitches.fromJson(Map<String, Object?> json) =>
      _$InstallerSwitchesFromJson(json);
}

// @freezed
// class Markets with _$Markets {
//   const factory Markets({
//     List<String>? allowedMarkets,
//   }) = _Markets;

//   factory Markets.fromJson(Map<String, Object?> json) =>
//       _$MarketsFromJson(json);
// }
