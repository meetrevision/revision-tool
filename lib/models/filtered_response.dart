import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'products_list.dart';
part 'filtered_response.freezed.dart';
part 'filtered_response.g.dart';

@freezed
class FilteredResponse with _$FilteredResponse {
  const factory FilteredResponse({
    List<ProductsList>? productsList,
  }) = _FilteredResponse;

  factory FilteredResponse.fromJson(Map<String, Object?> json) =>
      _$FilteredResponseFromJson(json);
}
