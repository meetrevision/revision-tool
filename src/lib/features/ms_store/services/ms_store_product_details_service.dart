import 'package:dio/dio.dart';

import '../../../core/services/network_service.dart';
import '../models/product_details/product_details.dart';

/// Service for fetching MS Store product details by ID.
class MSStoreProductDetailsService {
  const MSStoreProductDetailsService(this._networkService);

  final NetworkService _networkService;

  static const _detailsAPI =
      'https://apps.microsoft.com/api/ProductsDetails/GetProductDetailsById';

  static final _options = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'content-type': 'application/json;charset=utf-8',
      'accept': 'application/json',
    },
  );

  /// Fetches product details for the given product ID.
  Future<ProductDetails> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) async {
    final Response<dynamic> response = await _networkService.get(
      '$_detailsAPI/$productId?gl=$market&hl=$locale',
      options: _options,
    );

    if (response.statusCode == 200) {
      return ProductDetails.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception(
      'Failed to fetch product details (Status: ${response.statusCode})',
    );
  }
}
