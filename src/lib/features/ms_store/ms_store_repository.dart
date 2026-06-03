// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/compute.dart';
import '../../core/error/app_exception.dart';
import '../../core/error/result.dart';
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
  Future<Result<List<SearchProduct>>> searchProducts(String query);
  Future<Result<ProductDetails>> getProductDetails(
    String productId, {
    String market,
    String locale,
  });
  Future<Result<Set<PackageInfo>>> getPackages({
    required String productId,
    required MSStoreRing ring,
    ProductDetails? cachedDetails,
  });
  Future<Result<void>> downloadPackages({
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
  Future<Result<List<SearchProduct>>> searchProducts(
    String query, {
    String market = 'US',
    String locale = 'en-us',
    String mediaType = 'all',
    String age = 'all',
    String price = 'all',
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
  Future<Result<ProductDetails>> getProductDetails(
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
  Future<Result<Set<PackageInfo>>> getPackages({
    required String productId,
    required MSStoreRing ring,
    ProductDetails? cachedDetails,
  }) async {
    final cacheKey = '$productId-${ring.value}';
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      return Result<Set<PackageInfo>>.success(_cache[cacheKey]!.packages);
    }

    final MSStoreAppType? appType = .fromProductId(productId);
    if (appType == null) {
      return Result<Set<PackageInfo>>.failure(
        UnexpectedNetworkException(
          cause: Exception('Unknown app type for product ID: $productId'),
        ),
      );
    }

    final Set<PackageInfo> packages;
    DateTime expiryDate;

    if (appType == .uwp) {
      final Result<({DateTime expiryUtc, Set<PackageInfo> packages})> result =
          await _getUwpPackages(productId, ring);
      switch (result) {
        case Success(value: final value):
          packages = value.packages;
          expiryDate = value.expiryUtc;
        case Failure(exception: final exception):
          return Result<Set<PackageInfo>>.failure(exception);
      }
    } else {
      final Result<Set<PackageInfo>> result = await _win32PackageService
          .getPackages(productId, cachedDetails);
      switch (result) {
        case Success(value: final value):
          packages = value;
          expiryDate = DateTime.now().add(const Duration(minutes: 2));
        case Failure():
          return result;
      }
    }

    _cache[cacheKey] = _PackageCacheEntry(
      packages: packages,
      expiryDate: expiryDate,
    );
    return Result<Set<PackageInfo>>.success(packages);
  }

  Future<Result<({Set<PackageInfo> packages, DateTime expiryUtc})>>
  _getUwpPackages(String productId, MSStoreRing ring) async {
    // 1. Get Cookie (lazy)
    if (_cookie == null) {
      final String template = await _xmlParser.getTemplate('cookie');
      final Result<String> result = await _uwpService.getCookie(template);
      switch (result) {
        case Success(value: final responseBody):
          _cookie = _xmlParser.parseCookieResponse(responseBody);
        case Failure(exception: final exception):
          return Result<
            ({Set<PackageInfo> packages, DateTime expiryUtc})
          >.failure(exception);
      }
    }

    // 2. Get Category ID
    final Result<({String categoryId, DateTime expiryUtc})> categoryResult =
        await _uwpService.getCategoryId(productId);
    final String categoryId;
    final DateTime expiryUtc;
    switch (categoryResult) {
      case Success(value: final value):
        categoryId = value.categoryId;
        expiryUtc = value.expiryUtc;
      case Failure(exception: final exception):
        return Result<
          ({Set<PackageInfo> packages, DateTime expiryUtc})
        >.failure(exception);
    }

    // 3. Fetch File List XML
    final String wuTemplate = await _xmlParser.getTemplate('wu');
    final Result<String> xmlResult = await _uwpService.fetchPackageListXml(
      categoryId: categoryId,
      cookie: _cookie!,
      ring: ring,
      wuTemplate: wuTemplate,
    );
    final String xmlString;
    switch (xmlResult) {
      case Success(value: final value):
        xmlString = value;
      case Failure(exception: final exception):
        return Result<
          ({Set<PackageInfo> packages, DateTime expiryUtc})
        >.failure(exception);
    }

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

    return Result<({Set<PackageInfo> packages, DateTime expiryUtc})>.success((
      packages: pkgs,
      expiryUtc: expiryUtc,
    ));
  }

  @override
  Future<Result<void>> downloadPackages({
    required String productId,
    required MSStoreRing ring,
    required List<PackageInfo> packages,
    required void Function(String fileName, double progress) onProgress,
    required CancelToken cancelToken,
  }) async {
    if (packages.isEmpty) return const Result<void>.success(null);

    final String urlTemplate = await _xmlParser.getTemplate('url');
    final String tempDir = _fileService.getTempPath(productId, ring);

    for (final pkg in packages) {
      if (cancelToken.isCancelled) {
        return const Result<void>.success(null);
      }

      String downloadUrl = pkg.uri;

      // UWP apps need session URL
      if (downloadUrl.isEmpty && pkg.updateIdentity != null) {
        final Result<String> result = await _uwpService.getAppxDownloadUri(
          updateId: pkg.updateIdentity!.id,
          revision: pkg.updateIdentity!.revisionNumber,
          ring: ring,
          urlTemplate: urlTemplate,
        );
        final String responseBody;
        switch (result) {
          case Success(value: final value):
            responseBody = value;
          case Failure(exception: final exception):
            if (cancelToken.isCancelled) {
              return const Result<void>.success(null);
            }
            return Result<void>.failure(exception);
        }
        downloadUrl = _xmlParser.parseDownloadUrl(
          responseBody,
          pkg.fileModel?.digest,
        );
      }

      if (downloadUrl.isEmpty) continue;

      final String fileName =
          pkg.fileModel?.packageFullName ??
          pkg.fileModel?.fileName ??
          'package_${pkg.id}';

      final String extension = pkg.fileModel?.fileType ?? 'appx';
      var fullPath = '$tempDir\\$fileName';

      if (!fileName.endsWith('.$extension')) {
        fullPath += '.$extension';
      }

      final Result<void> downloadResult = await _fileService.downloadPackage(
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
      if (downloadResult is Failure<void>) {
        return downloadResult;
      }
    }

    return const Result<void>.success(null);
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
