// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/search_product.dart';

part 'search_dto.freezed.dart';
part 'search_dto.g.dart';

@freezed
sealed class MsStoreSearchDto with _$MsStoreSearchDto {
  const factory({
    @Default([]) List<SearchProductDto> highlightedList,
    @Default([]) List<SearchProductDto> productsList,
  }) = _MsStoreSearchDto;

  factory fromJson(Map<String, Object?> json) => _$MsStoreSearchDtoFromJson(json);
}

@freezed
sealed class SearchProductDto with _$SearchProductDto {
  const factory({
    @JsonKey(name: 'productId') String? productId,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'publisherName') String? publisherName,
    @JsonKey(name: 'displayPrice') String? displayPrice,
    @JsonKey(name: 'productFamilyName') String? productFamilyName,
    @JsonKey(name: 'iconUrl') String? iconUrl,
    @JsonKey(name: 'iconUrlBackground') String? iconUrlBackground,
    @JsonKey(name: 'previews') @Default([]) List<SearchPreviewDto> previews,
    @JsonKey(name: 'images') @Default([]) List<SearchPreviewDto> images,
  }) = _SearchProductDto;

  factory fromJson(Map<String, Object?> json) => _$SearchProductDtoFromJson(json);
}

extension SearchProductDtoX on SearchProductDto {
  SearchProduct toDomain() {
    final String id = (productId ?? '').trim().toUpperCase();
    final String posterFromPreviews = previews
        .map((p) => p.url ?? '')
        .firstWhere((u) => u.isNotEmpty, orElse: () => '');
    final String posterFromImages = images
        .map((p) => p.url ?? '')
        .firstWhere((u) => u.isNotEmpty, orElse: () => '');
    final posterUrl = posterFromPreviews.isNotEmpty ? posterFromPreviews : posterFromImages;

    final String bgFromPreviews = previews
        .map((p) => p.backgroundColor ?? '')
        .firstWhere((c) => c.isNotEmpty, orElse: () => '');
    final String posterBg = bgFromPreviews.isNotEmpty ? bgFromPreviews : (iconUrlBackground ?? '');

    return SearchProduct(
      id: id,
      title: (title ?? '').trim(),
      description: (description ?? '').trim(),
      publisherName: (publisherName ?? '').trim(),
      displayPrice: (displayPrice ?? '').trim(),
      productFamilyName: (productFamilyName ?? '').trim(),
      iconUrl: (iconUrl ?? '').trim(),
      posterUrl: posterUrl.trim(),
      posterBackgroundColor: posterBg.trim(),
    );
  }
}

@freezed
sealed class SearchPreviewDto with _$SearchPreviewDto {
  const factory({
    String? imageType,
    String? backgroundColor,
    String? foregroundColor,
    String? caption,
    String? imagePositionInfo,
    String? url,
    int? width,
    int? height,
  }) = _SearchPreviewDto;

  factory fromJson(Map<String, Object?> json) => _$SearchPreviewDtoFromJson(json);
}
