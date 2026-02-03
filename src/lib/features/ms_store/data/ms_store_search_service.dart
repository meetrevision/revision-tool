import 'package:dio/dio.dart';
import '../../../core/services/network_service.dart';
import '../models/search/ms_store_search_dto.dart';
import '../models/search/search_product.dart';

/// Service for searching products across the MS Store.
class MSStoreSearchService {
  MSStoreSearchService(this._networkService);

  final NetworkService _networkService;
  static const _searchAPI = 'https://apps.microsoft.com/api/products/search';

  static final _options = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'content-type': 'application/json;charset=utf-8',
      'accept': 'application/json',
    },
  );

  /// Searches for products matching the query.
  /// Returns a combined list of highlighted and regular products.
  Future<List<SearchProduct>> searchProducts(String query) async {
    final Response<dynamic> response = await _networkService.get(
      '$_searchAPI?gl=US&hl=en-us&query=$query&mediaType=all&age=all&price=all&category=all&subscription=all',
      options: _options,
    );

    if (response.statusCode == 200) {
      final responseData = MsStoreSearchDto.fromJson(
        response.data as Map<String, dynamic>,
      );
      return [
        ...(responseData.highlightedList ?? []),
        ...(responseData.productsList ?? []),
      ];
    }
    throw Exception(
      'Failed to search the product (Status: ${response.statusCode})',
    );
  }
}
