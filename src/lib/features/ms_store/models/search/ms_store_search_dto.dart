// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'search_product.dart';

part 'ms_store_search_dto.freezed.dart';
part 'ms_store_search_dto.g.dart';

@freezed
sealed class MsStoreSearchDto with _$MsStoreSearchDto {
  const factory MsStoreSearchDto({
    List<SearchProduct>? highlightedList,
    List<SearchProduct>? productsList,
  }) = _MsStoreSearchDto;

  factory MsStoreSearchDto.fromJson(Map<String, Object?> json) =>
      _$MsStoreSearchDtoFromJson(json);
}
