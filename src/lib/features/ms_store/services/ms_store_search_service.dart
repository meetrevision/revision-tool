import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../models/search/ms_store_search_dto.dart';
import '../models/search/search_product.dart';
import '../ms_store_endpoints.dart';

/// Service for searching products across the MS Store.
class MSStoreSearchService {
  const MSStoreSearchService(this._api);

  final ApiClient _api;

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
  Future<Result<List<SearchProduct>>> searchProducts(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'free',
    String category = 'all',
    String subscription = 'all',
  }) async {
    final Result<Response<dynamic>> result = await _api.get(
      MSStoreEndpoints.search(
        query: query,
        market: market,
        locale: locale,
        mediaType: mediaType,
        age: age,
        price: price,
        category: category,
        subscription: subscription,
      ),
      options: _options,
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode != 200) {
          return Result<List<SearchProduct>>.failure(
            HttpStatusException(
              response.statusCode ?? 500,
              'Failed to search the product',
              responseBody: response.data,
            ),
          );
        }

        final responseData = MsStoreSearchDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Result<List<SearchProduct>>.success([
          ...(responseData.highlightedList ?? []),
          ...(responseData.productsList ?? []),
        ]);
      },
      failure: Result<List<SearchProduct>>.failure,
    );
  }
}
