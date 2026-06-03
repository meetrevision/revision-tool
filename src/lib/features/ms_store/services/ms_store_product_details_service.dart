import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../models/product_details/product_details.dart';
import '../ms_store_endpoints.dart';

/// Service for fetching MS Store product details by ID.
class MSStoreProductDetailsService {
  const MSStoreProductDetailsService(this._api);

  final ApiClient _api;

  static final _options = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'content-type': 'application/json;charset=utf-8',
      'accept': 'application/json',
    },
  );

  /// Fetches product details for the given product ID.
  Future<Result<ProductDetails>> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) async {
    final Result<Response<dynamic>> result = await _api.get(
      MSStoreEndpoints.productDetails(
        productId: productId,
        market: market,
        locale: locale,
      ),
      options: _options,
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode != 200) {
          return Result<ProductDetails>.failure(
            HttpStatusException(
              response.statusCode ?? 500,
              'Failed to fetch product details',
              responseBody: response.data,
            ),
          );
        }

        return Result<ProductDetails>.success(
          ProductDetails.fromJson(response.data as Map<String, dynamic>),
        );
      },
      failure: Result<ProductDetails>.failure,
    );
  }
}
