import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'models/package_info.dart';
import 'models/product_details/product_details.dart';
import 'models/search/search_product.dart';
import 'models/uwp/uwp_package.dart';
import 'ms_store_enums.dart';
import 'services/ms_store_installer_service.dart';
import 'services/ms_store_product_details_service.dart';
import 'services/ms_store_search_service.dart';
import 'services/package_file_service.dart';
import 'services/uwp_api_service.dart';
import 'services/uwp_xml_parser.dart';
import 'services/win32_service.dart';

abstract class MSStoreRepository {
  Future<List<SearchProduct>> searchProducts(String query);
  Future<ProductDetails> getProductDetails(
    String productId, {
    String market,
    String locale,
  });
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required MSStoreRing ring,
    ProductDetails? cachedDetails,
  });
  Future<void> downloadPackages({
    required String productId,
    required MSStoreRing ring,
    required List<PackageInfo> packages,
    required void Function(String fileName, double progress) onProgress,
    required CancelToken cancelToken,
  });
  Future<List<ProcessResult>> installPackages({
    required String productId,
    required MSStoreRing ring,
  });
  Future<void> cleanup();
}

class _PackageCacheEntry {
  const _PackageCacheEntry({required this.packages, required this.expiryDate});
  final Set<PackageInfo> packages;
  final DateTime expiryDate;
  bool get isExpired => DateTime.now().isAfter(expiryDate);
}

class MSStoreRepositoryImpl implements MSStoreRepository {
  MSStoreRepositoryImpl({
    required UwpApiService uwpService,
    required MSStoreSearchService searchService,
    required MSStoreProductDetailsService detailsService,
    required UwpXmlParser xmlParser,
    required PackageFileService fileService,
    required MSStoreInstallerService installerService,
    required Win32Service win32PackageService,
  }) : _uwpService = uwpService,
       _searchService = searchService,
       _detailsService = detailsService,
       _xmlParser = xmlParser,
       _fileService = fileService,
       _installerService = installerService,
       _win32PackageService = win32PackageService;

  final UwpApiService _uwpService;
  final MSStoreSearchService _searchService;
  final MSStoreProductDetailsService _detailsService;
  final UwpXmlParser _xmlParser;
  final PackageFileService _fileService;
  final MSStoreInstallerService _installerService;
  final Win32Service _win32PackageService;

  static final Map<String, _PackageCacheEntry> _cache = {};
  static String? _cookie;

  @override
  Future<List<SearchProduct>> searchProducts(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'free',
    String category = 'all',
    String subscription = 'all',
  }) async {
    return _searchService.searchProducts(
      query,
      market: market,
      locale: locale,
      mediaType: mediaType,
      age: age,
      price: price,
      category: category,
      subscription: subscription,
    );
  }

  @override
  Future<ProductDetails> getProductDetails(
    String productId, {
    String market = 'US',
    String locale = 'en-us',
  }) async {
    return _detailsService.getProductDetails(
      productId,
      market: market,
      locale: locale,
    );
  }

  @override
  @override
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required MSStoreRing ring,
    ProductDetails? cachedDetails,
  }) async {
    final cacheKey = '$productId-${ring.value}';
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      return _cache[cacheKey]!.packages;
    }

    final MSStoreAppType? appType = .fromProductId(productId);
    if (appType == null) {
      throw Exception('Unknown app type for product ID: $productId');
    }

    Set<PackageInfo> packages;
    DateTime expiryDate;

    if (appType == .uwp) {
      final ({DateTime expiryUtc, Set<PackageInfo> packages}) result =
          await _getUwpPackages(productId, ring);
      packages = result.packages;
      expiryDate = result.expiryUtc;
    } else {
      packages = await _win32PackageService.getPackages(
        productId,
        cachedDetails,
      );
      expiryDate = DateTime.now().add(const Duration(minutes: 2));
    }

    _cache[cacheKey] = _PackageCacheEntry(
      packages: packages,
      expiryDate: expiryDate,
    );
    return packages;
  }

  Future<({Set<PackageInfo> packages, DateTime expiryUtc})> _getUwpPackages(
    String productId,
    MSStoreRing ring,
  ) async {
    // 1. Get Cookie (lazy)
    if (_cookie == null) {
      final String template = await _xmlParser.getTemplate('cookie');
      final String responseBody = await _uwpService.getCookie(template);
      _cookie = _xmlParser.parseCookieResponse(responseBody);
    }

    // 2. Get Category ID
    final (:String categoryId, :DateTime expiryUtc) = await _uwpService
        .getCategoryId(productId);

    // 3. Fetch File List XML
    final String wuTemplate = await _xmlParser.getTemplate('wu');
    final String xmlString = await _uwpService.fetchPackageListXml(
      categoryId: categoryId,
      cookie: _cookie!,
      ring: ring,
      wuTemplate: wuTemplate,
    );

    // 4. Parse Packages in isolate
    final UwpPackageResponse response = await compute(
      UwpXmlParser.parsePackageListXml,
      xmlString,
    );

    final pkgs = <PackageInfo>{};
    for (final UpdateModel update in response.updates) {
      for (final FileModel file in update.xml.fileModel) {
        final String preferredName =
            update.xml.packageMoniker ?? file.fileName ?? '';
        final FileModel updatedFile = file.copyWith(fileName: preferredName);

        pkgs.add(
          PackageInfo(
            id: update.id,
            isDependency:
                update.xml.extendedProperties?.isAppxFramework ?? false,
            uri: '', // URI is fetched sessionally during download
            arch: update.arch ?? 'neutral',
            fileModel: updatedFile,
            updateIdentity: update.xml.updateIdentity,
          ),
        );
      }
    }

    return (packages: pkgs, expiryUtc: expiryUtc);
  }

  @override
  Future<void> downloadPackages({
    required String productId,
    required MSStoreRing ring,
    required List<PackageInfo> packages,
    required void Function(String fileName, double progress) onProgress,
    required CancelToken cancelToken,
  }) async {
    if (packages.isEmpty) return;

    final String urlTemplate = await _xmlParser.getTemplate('url');
    final String tempDir = _fileService.getTempPath(productId, ring);

    await Future.wait(
      packages.map((pkg) async {
        if (cancelToken.isCancelled) return;

        String downloadUrl = pkg.uri;

        // UWP apps need sessiosn URL
        if (downloadUrl.isEmpty && pkg.updateIdentity != null) {
          try {
            final String responseBody = await _uwpService.getAppxDownloadUri(
              updateId: pkg.updateIdentity!.id,
              revision: pkg.updateIdentity!.revisionNumber,
              ring: ring,
              urlTemplate: urlTemplate,
            );
            downloadUrl = _xmlParser.parseDownloadUrl(
              responseBody,
              pkg.fileModel?.digest,
            );
          } catch (e) {
            if (cancelToken.isCancelled) return;
            rethrow;
          }
        }

        if (downloadUrl.isEmpty) return;

        final String fileName =
            pkg.fileModel?.packageFullName ??
            pkg.fileModel?.fileName ??
            'package_${pkg.id}';

        final String extension = pkg.fileModel?.fileType ?? 'appx';
        var fullPath = '$tempDir\\$fileName';

        if (!fileName.endsWith('.$extension')) {
          fullPath += '.$extension';
        }

        await _fileService.downloadPackage(
          downloadUrl,
          fullPath,
          isDependency: pkg.isDependency,
          cancelToken: cancelToken,
          onProgress: (count, total) {
            if (total > 0 && !cancelToken.isCancelled) {
              onProgress(fileName, count / total);
            }
          },
        );
      }),
    );
  }

  @override
  Future<List<ProcessResult>> installPackages({
    required String productId,
    required MSStoreRing ring,
  }) async {
    final MSStoreAppType? appType = MSStoreAppType.fromProductId(productId);
    if (appType == null) {
      throw Exception('Unknown app type for product ID: $productId');
    }

    final cacheKey = '$productId-${ring.value}';
    final Set<PackageInfo>? cachedPackages = _cache[cacheKey]?.packages;

    return _installerService.installPackages(
      productId: productId,
      ring: ring,
      appType: appType,
      cachedPackages: cachedPackages,
    );
  }

  @override
  Future<void> cleanup() async {
    await _fileService.cleanupDownloads();
    _cache.clear();
    _cookie = null;
  }
}
