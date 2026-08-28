import 'package:riverpod/riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/package_info.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/entities/search_product.dart';
import '../../domain/entities/store_enums.dart';
import '../cache/store_cache.dart';
import '../datasources/fe3_delivery_client.dart';
import '../datasources/store_catalog_client.dart';
import '../datasources/store_edge_client.dart';
import '../models/uwp/product_dto.dart';
import '../models/uwp/uwp_package.dart';
import '../models/win32/win32_manifest_dto.dart';
import '../services/uwp_xml_parser.dart';

final uwpStoreRepositoryProvider = Provider<StoreRepository>((ref) {
  return UwpStoreRepository(
    catalog: ref.read(storeCatalogClientProvider),
    edge: ref.read(storeEdgeClientProvider),
    fe3: ref.read(fe3DeliveryClientProvider),
    cache: ref.read(storeCacheProvider),
  );
});

final win32StoreRepositoryProvider = Provider<StoreRepository>((ref) {
  return Win32StoreRepository(
    catalog: ref.read(storeCatalogClientProvider),
    edge: ref.read(storeEdgeClientProvider),
    cache: ref.read(storeCacheProvider),
    xmlParser: ref.read(storeUwpXmlParserProvider),
  );
});

String _packageKey(String productId, StoreRing ring) {
  return '$productId-${ring.value}';
}

// Thin repository. Delegates HTTP to clients, does only mapping + cache.
// Search and details use catalog client. Packages use edge + fe3 clients.
abstract base class const StoreRepository() {
  Future<List<SearchProduct>> searchProducts(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'all',
    String category = 'all',
    String subscription = 'all',
  });

  Future<ProductDetails> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  });

  Future<Set<PackageInfo>> getPackages({required String productId, required StoreRing ring});

  Future<String> getPackageDownloadUrl({
    required PackageInfo package,
    required StoreRing ring,
  }) async {
    if (package.uri.isNotEmpty) return package.uri;
    throw UnimplementedError('getPackageDownloadUrl must be implemented by subclasses');
  }
}

// UWP packages need FE3. Steps: getCategory -> WuCategoryId -> fe3 syncUpdates -> map to PackageInfo.
// Cache by productId+ring with expiry from ProductDto.
final class const UwpStoreRepository({
  required final StoreCatalogClient catalog,
  required final StoreEdgeClient edge,
  required final Fe3DeliveryClient fe3,
  required final StoreCache cache,
}) extends StoreRepository {
  @override
  Future<List<SearchProduct>> searchProducts(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'all',
    String category = 'all',
    String subscription = 'all',
  }) => catalog.search(
    query,
    market: market,
    locale: locale,
    mediaType: mediaType,
    age: age,
    price: price,
    category: category,
    subscription: subscription,
  );

  @override
  Future<ProductDetails> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) => catalog.getDetails(productId, market: market, locale: locale);

  @override
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required StoreRing ring,
    String market = 'US',
    String locale = 'en-us',
    String deviceFamily = 'Windows.Desktop',
  }) async {
    final String cacheKey = _packageKey(productId, ring);
    final Set<PackageInfo>? cached = cache.getPackages(cacheKey);
    if (cached != null) return cached;

    final ProductDto product = await edge.getProductCategory(
      productId,
      market: market,
      locale: locale,
      deviceFamily: deviceFamily,
    );

    final DateTime? expiryUtc = product.expiryUtc;
    final List<Skus> skus = product.payload?.skus ?? const [];
    String? categoryId = skus
        .where((s) => s.skuType == .full)
        .map((s) => s.fulfillmentData?.wuCategoryId)
        .firstWhere((id) => id != null && id.isNotEmpty, orElse: () => null);
    categoryId ??= skus
        .map((s) => s.fulfillmentData?.wuCategoryId)
        .firstWhere((id) => id != null && id.isNotEmpty, orElse: () => null);
    if (categoryId == null || expiryUtc == null) {
      throw UnexpectedNetworkException(
        cause: Exception('Product $productId is not a UWP app or missing fulfillment data'),
      );
    }

    final UwpPackageResponse uwpRes = await fe3.syncUpdates(
      categoryId: categoryId,
      ring: ring.value,
    );

    final Set<PackageInfo> packages = uwpRes.updates
        .expand(
          (u) => u.xml.fileModel.map(
            (f) => PackageInfo(
              id: u.id,
              isDependency: u.xml.extendedProperties?.isAppxFramework ?? false,
              uri: '',
              arch: u.arch ?? 'neutral',
              fileModel: f.copyWith(fileName: u.xml.packageMoniker ?? f.fileName ?? ''),
              updateIdentity: u.xml.updateIdentity,
            ),
          ),
        )
        .toSet();

    cache.putPackages(cacheKey, packages, expiryUtc);
    return packages;
  }

  @override
  Future<String> getPackageDownloadUrl({
    required PackageInfo package,
    required StoreRing ring,
  }) async {
    if (package.uri.isNotEmpty) return package.uri;
    if (package.updateIdentity == null) return '';

    final String id = package.updateIdentity!.id;
    final String rev = package.updateIdentity!.revisionNumber;

    // Use SHA1 for FE3 lookup.
    return fe3.getDownloadUrl(
      updateId: id,
      revision: rev,
      ring: ring.value,
      digest: package.correlationDigest,
    );
  }

  static void clearSession() => Fe3DeliveryClient.clearSession();
}

// Win32 packages come from details installer or fallback manifest.
final class const Win32StoreRepository({
  required final StoreCatalogClient catalog,
  required final StoreEdgeClient edge,
  required final StoreCache cache,
  required final UwpXmlParser _xmlParser,
}) extends StoreRepository {
  @override
  Future<List<SearchProduct>> searchProducts(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'all',
    String category = 'all',
    String subscription = 'all',
  }) => catalog.search(
    query,
    market: market,
    locale: locale,
    mediaType: mediaType,
    age: age,
    price: price,
    category: category,
    subscription: subscription,
  );

  @override
  Future<ProductDetails> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) => catalog.getDetails(productId, market: market, locale: locale);

  @override
  Future<Set<PackageInfo>> getPackages({required String productId, required StoreRing ring}) async {
    final String cacheKey = _packageKey(productId, ring);
    final Set<PackageInfo>? cached = cache.getPackages(cacheKey);
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

    cache.putPackages(
      _packageKey(productId, ring),
      packages,
      .now().add(const Duration(minutes: 2)),
    );
    return packages;
  }

  Future<Set<PackageInfo>> _getPackagesFromManifest(String productId) async {
    final Win32ManifestDto manifest = await edge.getPackageManifest(productId);
    final seen = <String>{};
    final result = <PackageInfo>{};

    if (manifest.data == null || manifest.data!.versions.isEmpty) {
      throw UnexpectedNetworkException(
        cause: Exception('Product $productId is not a Win32 app or missing manifest data'),
      );
    }

    for (final Versions v in manifest.data!.versions) {
      for (final Installers i in v.installers) {
        final String? url = i.installerUrl;
        if (url == null || seen.contains(url)) continue;
        final String fileType = (i.installerType ?? url.substring(url.lastIndexOf('.') + 1))
            .toLowerCase();
        if (!{'exe', 'msi'}.contains(fileType)) continue;
        seen.add(url);
        final String? locale = i.installerLocale;
        final String urlFileName = url.split('/').last;
        result.add(
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
        );
      }
    }
    return result;
  }
}
