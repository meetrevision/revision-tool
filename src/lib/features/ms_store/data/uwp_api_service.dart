import 'package:dio/dio.dart';
import '../../../core/services/network_service.dart';
import '../models/uwp/product_dto.dart';
import '../ms_store_enums.dart';

/// Service for UWP (AppX) specific MS Store API calls using FE3 delivery.
class UwpApiService {
  UwpApiService(this._networkService);

  final NetworkService _networkService;

  static const _fe3Delivery =
      'https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx';
  static const _storeAPI = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0';

  static final _soapOptions = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'Accept': '*/*',
      'Content-Type': 'application/soap+xml',
    },
  );

  /// Fetches an encrypted cookie from FE3 delivery
  Future<String> getCookie(String cookieTemplate) async {
    final Response<dynamic> response = await _networkService.post(
      _fe3Delivery,
      data: cookieTemplate,
      options: _soapOptions,
    );

    if (response.statusCode == 200) {
      return response.data.toString();
    }
    throw Exception('Failed to get a cookie (Status: ${response.statusCode})');
  }

  /// Gets the WU Category ID for a UWP product
  Future<({String categoryId, DateTime expiryUtc})> getCategoryId(
    String productId,
  ) async {
    final Response<dynamic> response = await _networkService.get(
      '$_storeAPI/products/$productId?market=US&locale=en-us&deviceFamily=Windows.Desktop',
    );

    if (response.statusCode == 200) {
      final product = ProductDto.fromJson(
        response.data as Map<String, dynamic>,
      );
      final List<Skus> skus = product.payload?.skus ?? [];

      for (final sku in skus) {
        if (sku.skuType == .full) {
          final String? categoryId = sku.fulfillmentData?.wuCategoryId;
          final DateTime? expiryUtc = product.expiryUtc;
          if (categoryId != null && expiryUtc != null) {
            return (categoryId: categoryId, expiryUtc: expiryUtc);
          }
        }
      }
      throw Exception(
        'Product $productId is not a UWP app or missing fulfillment data',
      );
    }
    throw Exception(
      'Failed to get category ID for $productId (Status: ${response.statusCode})',
    );
  }

  /// Fetches the package list XML manifest
  Future<String> fetchPackageListXml({
    required String categoryId,
    required String cookie,
    required MSStoreRing ring,
    required String wuTemplate,
  }) async {
    final String body = wuTemplate
        .replaceAll('{1}', cookie)
        .replaceAll('{2}', categoryId)
        .replaceAll('{3}', ring.value);

    final Response<dynamic> response = await _networkService.post(
      _fe3Delivery,
      data: body,
      options: _soapOptions,
    );

    if (response.statusCode == 200) {
      return response.data
          .toString()
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
    }
    throw Exception(
      'Failed to fetch package list XML (Status: ${response.statusCode})',
    );
  }

  /// Gets the download URL for a specific package
  Future<String> getAppxDownloadUri({
    required String updateId,
    required String revision,
    required MSStoreRing ring,
    required String urlTemplate,
  }) async {
    final String body = urlTemplate
        .replaceAll('{1}', updateId)
        .replaceAll('{2}', revision)
        .replaceAll('{3}', ring.value);

    final Response<dynamic> response = await _networkService.post(
      '$_fe3Delivery/secured',
      data: body,
      options: _soapOptions,
    );

    if (response.statusCode == 200) {
      return response.data.toString();
    }
    throw Exception(
      'Failed to get download URI for $updateId (Status: ${response.statusCode})',
    );
  }
}
