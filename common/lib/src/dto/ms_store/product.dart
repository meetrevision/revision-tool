// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    @JsonKey(name: "ExpiryUtc") DateTime? expiryUtc,
    @JsonKey(name: "Payload") Payload? payload,
  }) = _Product;

  factory Product.fromJson(Map<String, Object?> json) =>
      _$ProductFromJson(json);
}

@freezed
class Payload with _$Payload {
  const factory Payload({
    @JsonKey(name: "ProductId") String? productId,
    @JsonKey(name: "Title") String? title,
    @JsonKey(name: "Description") String? description,
    @JsonKey(name: "Skus") List<Skus>? skus,
    @JsonKey(name: "Platforms") List<String>? platforms,
    @JsonKey(name: "PermissionsRequired") List<String>? permissionsRequired,
    @JsonKey(name: "PackageAndDeviceCapabilities")
    List<String>? packageAndDeviceCapabilities,

    @JsonKey(name: "ContainsDownloadPackage") bool? containsDownloadPackage,
  }) = _Payload;

  factory Payload.fromJson(Map<String, Object?> json) =>
      _$PayloadFromJson(json);
}

enum SkuType {
  full(value: "full"),
  trial(value: "trial");

  const SkuType({required this.value});

  final String value;
}

@freezed
class Skus with _$Skus {
  const factory Skus({
    @JsonKey(name: "SkuId") String? skuId,
    @JsonKey(name: "Title") String? title,
    @JsonKey(name: "SkuType") SkuType? skuType,
    @JsonKey(name: "Price") double? price,
    @JsonKey(name: "DisplayPrice") String? displayPrice,
    @JsonKey(name: "FulfillmentData")
    @FulfillmentDataConverter()
    FulfillmentData? fulfillmentData,
  }) = _Skus;

  factory Skus.fromJson(Map<String, Object?> json) => _$SkusFromJson(json);
}

@freezed
class FulfillmentData with _$FulfillmentData {
  const factory FulfillmentData({
    @JsonKey(name: "ProductId") String? productId,
    @JsonKey(name: "WuBundleId") String? wuBundleId,
    @JsonKey(name: "WuCategoryId") String? wuCategoryId,
    @JsonKey(name: "PackageFamilyName") String? packageFamilyName,
    @JsonKey(name: "SkuId") String? skuId,
  }) = _FulfillmentData;

  factory FulfillmentData.fromJson(Map<String, Object?> json) =>
      _$FulfillmentDataFromJson(json);
}

class FulfillmentDataConverter
    implements JsonConverter<FulfillmentData, String> {
  const FulfillmentDataConverter();

  @override
  FulfillmentData fromJson(String data) {
    return FulfillmentData.fromJson(json.decode(data));
  }

  @override
  String toJson(FulfillmentData data) {
    return json.encode(data.toJson());
  }
}
