import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
part 'products_list.g.dart';
part 'products_list.freezed.dart';

@freezed
class ProductsList with _$ProductsList {
  const factory ProductsList({
    String? productId,
    String? title,
    String? description,
    String? publisherName,
    // double? averageRating,
    String? ratingCount,
    // int? price,
    String? displayPrice,
    String? strikethroughPrice,
    String? productFamilyName,
    String? typeTag,
    String? iconUrl,
  }) = _ProductsList;

  factory ProductsList.fromJson(Map<String, Object?> json) =>
      _$ProductsListFromJson(json);
}
