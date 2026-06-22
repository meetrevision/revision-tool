import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/compute.dart';
import '../../core/error/app_exception.dart';
import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import 'data/store_cache.dart';
import 'models/package_info.dart';
import 'models/product_details/product_details.dart';
import 'models/search/ms_store_search_dto.dart';
import 'models/search/search_product.dart';
import 'models/uwp/product_dto.dart';
import 'models/uwp/uwp_package.dart';
import 'models/win32/win32_manifest_dto.dart';
import 'ms_store_endpoints.dart';
import 'services/uwp_xml_parser.dart';
import 'store_enums.dart';

final uwpStoreRepositoryProvider = Provider<StoreRepository>((ref) {
  return UwpStoreRepository(
    api: ref.read(apiClientProvider),
    cache: ref.read(storeCacheProvider),
    xmlParser: ref.read(storeUwpXmlParserProvider),
  );
});

final win32StoreRepositoryProvider = Provider<StoreRepository>((ref) {
  return Win32StoreRepository(
    api: ref.read(apiClientProvider),
    cache: ref.read(storeCacheProvider),
    xmlParser: ref.read(storeUwpXmlParserProvider),
  );
});

String _packageKey(String productId, StoreRing ring) {
  return '$productId-${ring.value}';
}

/// Abstract repository for MS Store data fetching, with separate implementations for UWP and Win32 apps due to differences in API endpoints and response formats.
abstract base class StoreRepository {
  const StoreRepository({required this._api, required this._cache});

  final ApiClient _api;
  final StoreCache _cache;

  Future<List<SearchProduct>> searchProducts(
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
        .then(
          (result) => result.when(success: (r) => r, failure: (e) => throw e),
        );

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to search the product',
        responseBody: response.data,
      );
    }

    final responseData = MsStoreSearchDto.fromJson(
      response.data as Map<String, dynamic>,
    );
    return [
      ...(responseData.highlightedList ?? []),
      ...(responseData.productsList ?? []),
    ];
  }

  Future<ProductDetails> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) async {
    final cacheKey = '$productId-$market-$locale';
    final ProductDetails? cached = _cache.getDetails(cacheKey);
    if (cached != null) return cached;

    final Response<dynamic> response = await _api
        .get<void>(
          MSStoreEndpoints.productDetails(
            productId: productId,
            market: market,
            locale: locale,
          ),
        )
        .then((result) {
          return result.when(success: (r) => r, failure: (e) => throw e);
        });

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to fetch product details',
        responseBody: response.data,
      );
    }

    final details = ProductDetails.fromJson(
      response.data as Map<String, dynamic>,
    );

    _cache.putDetails(cacheKey, details);
    return details;
  }

  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required StoreRing ring,
  });

  Future<String> getPackageDownloadUrl({
    required PackageInfo package,
    required StoreRing ring,
  }) async {
    // Win32 packages from the .productDetails endpoint sometimes contain the download URL, so return it if available
    if (package.uri.isNotEmpty) return package.uri;

    throw UnimplementedError(
      'getPackageDownloadUrl must be implemented by subclasses',
    );
  }
}

final class UwpStoreRepository extends StoreRepository {
  const UwpStoreRepository({
    required super.api,
    required super.cache,
    required this._xmlParser,
  });

  final UwpXmlParser _xmlParser;

  static String? _cookie;

  static final _soapOptions = Options(
    headers: const {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'Accept': '*/*',
      'Content-Type': 'application/soap+xml',
    },
  );

  @override
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required StoreRing ring,
    String market = 'US',
    String locale = 'en-us',
    String deviceFamily = 'Windows.Desktop',
  }) async {
    final String cacheKey = _packageKey(productId, ring);
    final Set<PackageInfo>? cached = _cache.getPackages(cacheKey);
    if (cached != null) return cached;

    if (_cookie == null) {
      final String cookieTemplate = await _xmlParser.getTemplate('cookie');
      await _getCookie(cookieTemplate);
    }

    final Result<Response<dynamic>> categoryResponse = await _api.get<dynamic>(
      MSStoreEndpoints.category(
        productId: productId,
        market: market,
        locale: locale,
        deviceFamily: deviceFamily,
      ),
    );

    final ProductDto product = await compute(
      ProductDto.fromJson,
      categoryResponse.when(
        success: (r) {
          if (r.statusCode == 200) return r.data as Map<String, dynamic>;
          throw HttpStatusException(
            r.statusCode ?? 500,
            'Failed to get category information for $productId',
            responseBody: r.data,
          );
        },
        failure: (e) => throw e,
      ),
    );

    final DateTime? expiryUtc = product.expiryUtc;
    final String? categoryId = (product.payload?.skus ?? [])
        .where((s) => s.skuType == .full)
        .map((s) => s.fulfillmentData?.wuCategoryId)
        .firstWhere((id) => id != null, orElse: () => null);
    if (categoryId == null || expiryUtc == null) {
      throw UnexpectedNetworkException(
        cause: Exception(
          'Product $productId is not a UWP app or missing fulfillment data',
        ),
      );
    }

    final String pkgBody = (await _xmlParser.getTemplate('wu'))
        .replaceAll('{1}', _cookie!)
        .replaceAll('{2}', categoryId)
        .replaceAll('{3}', ring.value);
    final Result<Response<dynamic>> pkgResult = await _api.post(
      MSStoreEndpoints.fe3Delivery(),
      data: pkgBody,
      options: _soapOptions,
    );
    final String xmlString = pkgResult
        .when(
          success: (r) {
            if (r.statusCode == 200) return r.data.toString();
            throw HttpStatusException(
              r.statusCode ?? 500,
              'Failed to get package information for $productId',
              responseBody: r.data,
            );
          },
          failure: (e) => throw e,
        )
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    final UwpPackageResponse uwpRes = await compute(
      UwpXmlParser.parsePackageListXml,
      xmlString,
    );

    final Set<PackageInfo> packages = uwpRes.updates
        .expand(
          (u) => u.xml.fileModel.map(
            (f) => PackageInfo(
              id: u.id,
              isDependency: u.xml.extendedProperties?.isAppxFramework ?? false,
              uri: '',
              arch: u.arch ?? 'neutral',
              fileModel: f.copyWith(
                fileName: u.xml.packageMoniker ?? f.fileName ?? '',
              ),
              updateIdentity: u.xml.updateIdentity,
            ),
          ),
        )
        .toSet();

    _cache.putPackages(cacheKey, packages, expiryUtc);
    return packages;
  }

  @override
  Future<String> getPackageDownloadUrl({
    required PackageInfo package,
    required StoreRing ring,
  }) async {
    if (package.uri.isNotEmpty) return package.uri;
    if (package.updateIdentity == null) return '';

    final UpdateIdentity identity = package.updateIdentity!;
    final String body = (await _xmlParser.getTemplate('url'))
        .replaceAll('{1}', identity.id)
        .replaceAll('{2}', identity.revisionNumber)
        .replaceAll('{3}', ring.value);

    final Response<dynamic> response = await _api
        .post<void>(
          MSStoreEndpoints.fe3Delivery(secured: true),
          data: body,
          options: _soapOptions,
        )
        .then(
          (result) => result.when(success: (r) => r, failure: (e) => throw e),
        );

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to get download URI for ${identity.id}',
        responseBody: response.data,
      );
    }

    return _xmlParser.parseDownloadUrl(
      response.data.toString(),
      package.fileModel?.digest,
    );
  }

  Future<String> _getCookie(String cookieTemplate) async {
    if (_cookie != null) return _cookie!;

    final Result<Response<dynamic>> result = await _api.post(
      MSStoreEndpoints.fe3Delivery(),
      data: cookieTemplate,
      options: _soapOptions,
    );

    final String response = result.when(
      success: (r) {
        if (r.statusCode == 200) return r.data.toString();
        throw HttpStatusException(
          r.statusCode ?? 500,
          'Failed to get a cookie',
        );
      },
      failure: (e) => throw e,
    );

    _cookie = _xmlParser.parseCookieResponse(response);

    return _cookie!;
  }

  static void clearSession() {
    _cookie = null;
  }
}

final class Win32StoreRepository extends StoreRepository {
  const Win32StoreRepository({
    required super.api,
    required super.cache,
    required this._xmlParser,
  });

  final UwpXmlParser _xmlParser;

  /// ProductDetails for Win32 apps usually contains download metadata.
  /// If it is empty, fetching falls back to the Manifest API.
  @override
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required StoreRing ring,
  }) async {
    final String cacheKey = _packageKey(productId, ring);
    final Set<PackageInfo>? cached = _cache.getPackages(cacheKey);
    if (cached != null) return cached;

    var packages = <PackageInfo>{};
    try {
      final ProductDetails details = await getProductDetails(productId);
      packages = (details.installer?.architectures ?? {}).entries
          .where((e) => e.value.sourceUri?.isNotEmpty == true)
          .map((e) {
            final String url = e.value.sourceUri!;
            final String fileName = url.split('/').last;
            final int dot = fileName.lastIndexOf('.');
            return PackageInfo(
              id: productId,
              isDependency: false,
              uri: url,
              arch: e.key.toLowerCase(),
              fileModel: FileModel(
                fileName: fileName,
                fileType: dot == -1 ? 'exe' : fileName.substring(dot + 1),
                digest: e.value.hash?.toLowerCase(),
                digestAlgorithm: e.value.hash == null ? null : 'SHA256',
              ),
              commandLines: e.value.args?.replaceAll('"', ''),
            );
          })
          .toSet();
    } on Object {
      packages = <PackageInfo>{};
    }

    if (packages.isEmpty) {
      packages = await _getPackagesFromManifest(productId);
    }

    _cache.putPackages(
      _packageKey(productId, ring),
      packages,
      DateTime.now().add(const Duration(minutes: 2)),
    );
    return packages;
  }

  /// Fallback method to get packages for Win32 apps by fetching and parsing the package manifest, since the product details endpoint doesn't guarantee the presence of installer data for Win32 apps
  Future<Set<PackageInfo>> _getPackagesFromManifest(String productId) async {
    final Response<dynamic> manifestRes = await _api
        .get<dynamic>(
          MSStoreEndpoints.packageManifest(productId: productId, market: 'US'),
        )
        .then(
          (result) => result.when(success: (r) => r, failure: (e) => throw e),
        );

    if (manifestRes.statusCode != 200) {
      throw HttpStatusException(
        manifestRes.statusCode ?? 500,
        'Failed to get package manifest for $productId',
        responseBody: manifestRes.data,
      );
    }
    final manifest = Win32ManifestDto.fromJson(
      manifestRes.data as Map<String, dynamic>,
    );
    final seen = <String>{};
    return (manifest.data?.versions ?? [])
        .expand((v) => v.installers ?? const <Installers>[])
        .expand((i) {
          final String? url = i.installerUrl;
          if (url == null || seen.contains(url)) return const <PackageInfo>[];

          final String fileType =
              (i.installerType ?? url.substring(url.lastIndexOf('.') + 1))
                  .toLowerCase();
          if (!{'exe', 'msi'}.contains(fileType)) return const <PackageInfo>[];

          seen.add(url);
          final String? locale = i.installerLocale;
          final String urlFileName = url.split('/').last;

          return [
            PackageInfo(
              id: productId,
              isDependency: false,
              uri: url,
              arch: i.architecture ?? _xmlParser.extractArchitecture(url),
              fileModel: FileModel(
                fileName: locale == null ? urlFileName : '$locale-$urlFileName',
                fileType: fileType,
                digest: i.installerSha256?.toLowerCase(),
                digestAlgorithm: i.installerSha256 == null ? null : 'SHA256',
              ),
              commandLines: i.installerSwitches?.silent?.replaceAll('"', ''),
            ),
          ];
        })
        .toSet();
  }
}
