import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../models/uwp/product_dto.dart';
import '../ms_store_endpoints.dart';
import '../ms_store_enums.dart';

/// Service for UWP (AppX) specific MS Store API calls using FE3 delivery.
class UwpApiService {
  const UwpApiService(this._api);

  final ApiClient _api;

  static final _soapOptions = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'Accept': '*/*',
      'Content-Type': 'application/soap+xml',
    },
  );

  /// Fetches an encrypted cookie from FE3 delivery
  Future<Result<String>> getCookie(String cookieTemplate) async {
    final Result<Response<dynamic>> result = await _api.post(
      MSStoreEndpoints.fe3Delivery(),
      data: cookieTemplate,
      options: _soapOptions,
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode == 200) {
          return Result<String>.success(response.data.toString());
        }
        return Result<String>.failure(
          HttpStatusException(
            response.statusCode ?? 500,
            'Failed to get a cookie',
            responseBody: response.data,
          ),
        );
      },
      failure: Result<String>.failure,
    );
  }

  /// Gets the WU Category ID for a UWP product
  Future<Result<({String categoryId, DateTime expiryUtc})>> getCategoryId(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
    String deviceFamily = 'Windows.Desktop',
  }) async {
    final Result<Response<dynamic>> result = await _api.get(
      MSStoreEndpoints.category(
        productId: productId,
        market: market,
        locale: locale,
        deviceFamily: deviceFamily,
      ),
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode != 200) {
          return Result<({String categoryId, DateTime expiryUtc})>.failure(
            HttpStatusException(
              response.statusCode ?? 500,
              'Failed to get category ID for $productId',
              responseBody: response.data,
            ),
          );
        }

        final product = ProductDto.fromJson(
          response.data as Map<String, dynamic>,
        );
        final List<Skus> skus = product.payload?.skus ?? [];

        for (final sku in skus) {
          if (sku.skuType == .full) {
            final String? categoryId = sku.fulfillmentData?.wuCategoryId;
            final DateTime? expiryUtc = product.expiryUtc;
            if (categoryId != null && expiryUtc != null) {
              return Result<({String categoryId, DateTime expiryUtc})>.success((
                categoryId: categoryId,
                expiryUtc: expiryUtc,
              ));
            }
          }
        }
        return Result<({String categoryId, DateTime expiryUtc})>.failure(
          UnexpectedNetworkException(
            cause: Exception(
              'Product $productId is not a UWP app or missing fulfillment data',
            ),
          ),
        );
      },
      failure: Result<({String categoryId, DateTime expiryUtc})>.failure,
    );
  }

  /// Fetches the package list XML manifest
  Future<Result<String>> fetchPackageListXml({
    required String categoryId,
    required String cookie,
    required MSStoreRing ring,
    required String wuTemplate,
  }) async {
    final String body = wuTemplate
        .replaceAll('{1}', cookie)
        .replaceAll('{2}', categoryId)
        .replaceAll('{3}', ring.value);

    final Result<Response<dynamic>> result = await _api.post(
      MSStoreEndpoints.fe3Delivery(),
      data: body,
      options: _soapOptions,
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode == 200) {
          return Result<String>.success(
            response.data
                .toString()
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>'),
          );
        }
        return Result<String>.failure(
          HttpStatusException(
            response.statusCode ?? 500,
            'Failed to fetch package list XML',
            responseBody: response.data,
          ),
        );
      },
      failure: Result<String>.failure,
    );
  }

  /// Gets the download URL for a specific package
  Future<Result<String>> getAppxDownloadUri({
    required String updateId,
    required String revision,
    required MSStoreRing ring,
    required String urlTemplate,
  }) async {
    final String body = urlTemplate
        .replaceAll('{1}', updateId)
        .replaceAll('{2}', revision)
        .replaceAll('{3}', ring.value);

    final Result<Response<dynamic>> result = await _api.post(
      MSStoreEndpoints.fe3Delivery(secured: true),
      data: body,
      options: _soapOptions,
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode == 200) {
          return Result<String>.success(response.data.toString());
        }
        return Result<String>.failure(
          HttpStatusException(
            response.statusCode ?? 500,
            'Failed to get download URI for $updateId',
            responseBody: response.data,
          ),
        );
      },
      failure: Result<String>.failure,
    );
  }
}
