// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_dto.freezed.dart';
part 'product_dto.g.dart';

@freezed
sealed class ProductDto with _$ProductDto {
  const factory({
    @JsonKey(name: 'ExpiryUtc') DateTime? expiryUtc,
    @JsonKey(name: 'Payload') Payload? payload,
  }) = _ProductDto;

  factory fromJson(Map<String, Object?> json) => _$ProductDtoFromJson(json);
}

@freezed
sealed class Payload with _$Payload {
  const factory({
    // Keep only Skus. Other fields like Title, Platforms are not needed.
    // Skus hold the WuCategoryId needed for FE3 SyncUpdates.
    @JsonKey(name: 'Skus') @Default([]) List<Skus> skus,
  }) = _Payload;

  factory fromJson(Map<String, Object?> json) => _$PayloadFromJson(json);
}

// Some dependencies use trial or enterprise types (e.g. VCLibs 9NBLGGH3FRZM).
enum SkuType({required final String value}) {
  enterpriseonline(value: 'enterpriseonline'),
  enterpriseoffline(value: 'enterpriseoffline'),
  preinstall(value: 'preinstall'),
  full(value: 'full'),
  trial(value: 'trial');
}

@freezed
sealed class Skus with _$Skus {
  const factory({
    // Keep only skuType and fulfillmentData. Other sku fields not needed.
    @JsonKey(name: 'SkuType') SkuType? skuType,
    @JsonKey(name: 'FulfillmentData') @FulfillmentDataConverter() FulfillmentData? fulfillmentData,
  }) = _Skus;

  factory fromJson(Map<String, Object?> json) => _$SkusFromJson(json);
}

@freezed
sealed class FulfillmentData with _$FulfillmentData {
  const factory({
    // Only WuCategoryId is used to call FE3 SyncUpdates.
    // WuBundleId and PackageFamilyName are not needed.
    @JsonKey(name: 'WuCategoryId') String? wuCategoryId,
  }) = _FulfillmentData;

  factory fromJson(Map<String, Object?> json) => _$FulfillmentDataFromJson(json);
}

class const FulfillmentDataConverter() implements JsonConverter<FulfillmentData, String> {
  @override
  FulfillmentData fromJson(String data) {
    return FulfillmentData.fromJson(json.decode(data) as Map<String, Object?>);
  }

  @override
  String toJson(FulfillmentData data) {
    return json.encode(data.toJson());
  }
}
