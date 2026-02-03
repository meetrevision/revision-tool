import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_product.freezed.dart';
part 'search_product.g.dart';

@freezed
sealed class SearchProduct with _$SearchProduct {
  const factory SearchProduct({
    String? productId,
    String? title,
    String? description,
    String? publisherName,
    String? displayPrice,
    String? strikethroughPrice,
    String? productFamilyName,
    String? typeTag,
    String? iconUrl,
  }) = _SearchProduct;

  factory SearchProduct.fromJson(Map<String, Object?> json) =>
      _$SearchProductFromJson(json);
}
