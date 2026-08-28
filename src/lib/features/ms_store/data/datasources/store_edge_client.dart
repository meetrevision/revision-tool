import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/compute.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/uwp/product_dto.dart';
import '../models/win32/win32_manifest_dto.dart';
import 'ms_store_endpoints.dart';

final storeEdgeClientProvider = Provider<StoreEdgeClient>((ref) {
  return StoreEdgeClient(api: ref.read(apiClientProvider));
});

final class const StoreEdgeClient({required final ApiClient _api}) {
  // Get category data for UWP product. Returns ProductDto with expiry and payload.
  Future<ProductDto> getProductCategory(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
    String deviceFamily = 'Windows.Desktop',
  }) async {
    final Result<Response<dynamic>> result = await _api.get<dynamic>(
      MSStoreEndpoints.category(
        productId: productId,
        market: market,
        locale: locale,
        deviceFamily: deviceFamily,
      ),
    );

    final Map<String, Object?> data = result.when(
      success: (r) {
        if (r.statusCode == 200) return r.data as Map<String, Object?>;
        throw HttpStatusException(
          r.statusCode ?? 500,
          'Failed to get category information for $productId',
          responseBody: r.data,
        );
      },
      failure: (e) => throw e,
    );

    // Heavy JSON parse, run in isolate.
    return compute(ProductDto.fromJson, data);
  }

  // Get package manifest for Win32 product. Used as fallback when details has no installer.
  Future<Win32ManifestDto> getPackageManifest(String productId, {String market = 'US'}) async {
    final Result<Response<dynamic>> result = await _api.get<dynamic>(
      MSStoreEndpoints.packageManifest(productId: productId, market: market),
    );

    final Response<dynamic> response = result.when(success: (r) => r, failure: (e) => throw e);

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to get package manifest for $productId',
        responseBody: response.data,
      );
    }

    return .fromJson(response.data as Map<String, Object?>);
  }
}
