import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/entities/search_product.dart';
import '../cache/store_cache.dart';
import '../models/product_details_dto.dart';
import '../models/search_dto.dart';
import 'ms_store_endpoints.dart';

// Client for apps.microsoft.com catalog API.
// Handles search and product details. Both return domain entities.
// Data layer, no business logic.

final storeCatalogClientProvider = Provider<StoreCatalogClient>((ref) {
  return StoreCatalogClient(api: ref.read(apiClientProvider), cache: ref.read(storeCacheProvider));
});

class const StoreCatalogClient({required final ApiClient _api, required final StoreCache _cache}) {
  // Search for products. API returns highlighted + products list.
  // Filter out items without id. Free filter is in StoreService.
  Future<List<SearchProduct>> search(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'all',
    String category = 'all',
    String subscription = 'all',
  }) async {
    final Response<dynamic> response = await _api
        .get<dynamic>(
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
        )
        .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to search the product',
        responseBody: response.data,
      );
    }

    final dto = MsStoreSearchDto.fromJson(response.data as Map<String, Object?>);
    final List<SearchProductDto> raw = [...dto.highlightedList, ...dto.productsList];
    return raw
        .map<SearchProduct>((d) => d.toDomain())
        .where((e) => e.id.isNotEmpty)
        .toList(growable: false);
  }

  // Get product details by id. Uses cache if present.
  // DTO mirrors API, domain entity is clean.
  Future<ProductDetails> getDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) async {
    final cacheKey = '$productId-$market-$locale';
    final ProductDetails? cached = _cache.getDetails(cacheKey);
    if (cached != null) return cached;

    final Response<dynamic> response = await _api
        .get<dynamic>(
          MSStoreEndpoints.productDetails(productId: productId, market: market, locale: locale),
        )
        .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to fetch product details',
        responseBody: response.data,
      );
    }

    final dto = ProductDetailsDto.fromJson(response.data as Map<String, Object?>);
    final ProductDetails details = dto.toDomain();
    _cache.putDetails(cacheKey, details);
    return details;
  }
}
