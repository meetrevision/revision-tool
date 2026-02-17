// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_product.freezed.dart';
part 'search_product.g.dart';

@freezed
sealed class SearchProduct with _$SearchProduct {
  const factory SearchProduct({
    @JsonKey(name: 'productId') String? productId,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'publisherName') String? publisherName,
    @JsonKey(name: 'displayPrice') String? displayPrice,
    @JsonKey(name: 'strikethroughPrice') String? strikethroughPrice,
    @JsonKey(name: 'productFamilyName') String? productFamilyName,
    @JsonKey(name: 'typeTag') String? typeTag,
    @JsonKey(name: 'iconUrl') String? iconUrl,
    @JsonKey(name: 'previews') List<SearchProductPreviews>? previews,
  }) = _SearchProduct;

  factory SearchProduct.fromJson(Map<String, Object?> json) =>
      _$SearchProductFromJson(json);
}

@freezed
abstract class SearchProductPreviews with _$SearchProductPreviews {
  const factory SearchProductPreviews({
    String? imageType,
    String? backgroundColor,
    String? foregroundColor,
    String? caption,
    String? imagePositionInfo,
    String? url,
    int? width,
    int? height,
  }) = _SearchProductPreviews;

  factory SearchProductPreviews.fromJson(Map<String, Object?> json) =>
      _$SearchProductPreviewsFromJson(json);
}
