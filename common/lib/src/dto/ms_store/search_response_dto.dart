import 'package:freezed_annotation/freezed_annotation.dart';
part 'search_response_dto.freezed.dart';
part 'search_response_dto.g.dart';

@freezed
class MSStoreSearchResponseDTO with _$MSStoreSearchResponseDTO {
  const factory MSStoreSearchResponseDTO({
    List<ProductsList>? highlightedList,
    List<ProductsList>? productsList,
  }) = _MSStoreSearchResponseDTO;

  factory MSStoreSearchResponseDTO.fromJson(Map<String, Object?> json) =>
      _$MSStoreSearchResponseDTOFromJson(json);
}

@freezed
class ProductsList with _$ProductsList {
  const factory ProductsList({
    String? productId,
    String? title,
    String? description,
    String? publisherName,
    // double? averageRating,
    // String? ratingCount,
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
