// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'win32_manifest_dto.freezed.dart';
part 'win32_manifest_dto.g.dart';

@freezed
sealed class Win32ManifestDto with _$Win32ManifestDto {
  const factory Win32ManifestDto({@JsonKey(name: 'Data') Data? data}) =
      _Win32ManifestDto;

  factory Win32ManifestDto.fromJson(Map<String, Object?> json) =>
      _$Win32ManifestDtoFromJson(json);
}

@freezed
sealed class Data with _$Data {
  const factory Data({
    @JsonKey(name: 'PackageIdentifier') String? packageIdentifier,
    @JsonKey(name: 'Versions') List<Versions>? versions,
  }) = _Data;

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);
}

@freezed
sealed class Versions with _$Versions {
  const factory Versions({
    @JsonKey(name: 'PackageVersion') String? packageVersion,
    @JsonKey(name: 'DefaultLocale') DefaultLocale? defaultLocale,
    @JsonKey(name: 'Installers') List<Installers>? installers,
  }) = _Versions;

  factory Versions.fromJson(Map<String, Object?> json) =>
      _$VersionsFromJson(json);
}

@freezed
sealed class DefaultLocale with _$DefaultLocale {
  const factory DefaultLocale({
    @JsonKey(name: 'PackageName') String? packageName,
  }) = _DefaultLocale;

  factory DefaultLocale.fromJson(Map<String, Object?> json) =>
      _$DefaultLocaleFromJson(json);
}

@freezed
sealed class Installers with _$Installers {
  const factory Installers({
    @JsonKey(name: 'InstallerSha256') String? installerSha256,
    @JsonKey(name: 'InstallerUrl') String? installerUrl,
    @JsonKey(name: 'InstallerLocale') String? installerLocale,
    @JsonKey(name: 'MinimumOSVersion') String? minimumOSVersion,
    @JsonKey(name: 'InstallerSwitches') InstallerSwitches? installerSwitches,
    @JsonKey(name: 'Architecture') String? architecture,
    @JsonKey(name: 'InstallerType') String? installerType,
  }) = _Installers;

  factory Installers.fromJson(Map<String, Object?> json) =>
      _$InstallersFromJson(json);
}

@freezed
sealed class InstallerSwitches with _$InstallerSwitches {
  const factory InstallerSwitches({@JsonKey(name: 'Silent') String? silent}) =
      _InstallerSwitches;

  factory InstallerSwitches.fromJson(Map<String, Object?> json) =>
      _$InstallerSwitchesFromJson(json);
}
