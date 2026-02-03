import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../utils.dart';

import 'data/ms_store_search_service.dart';
import 'data/package_file_service.dart';
import 'data/uwp_api_service.dart';
import 'data/uwp_xml_parser.dart';
import 'data/win32_api_service.dart';
import 'models/package_info.dart';
import 'models/search/search_product.dart';
import 'models/uwp/uwp_package.dart';
import 'models/win32/win32_manifest_dto.dart';
import 'ms_store_enums.dart';

abstract class MSStoreRepository {
  Future<List<SearchProduct>> searchProducts(String query);
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required MSStoreRing ring,
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
    required Win32ApiService win32Service,
    required MSStoreSearchService searchService,
    required UwpXmlParser xmlParser,
    required PackageFileService fileService,
  }) : _uwpService = uwpService,
       _win32Service = win32Service,
       _searchService = searchService,
       _xmlParser = xmlParser,
       _fileService = fileService;

  final UwpApiService _uwpService;
  final Win32ApiService _win32Service;
  final MSStoreSearchService _searchService;
  final UwpXmlParser _xmlParser;
  final PackageFileService _fileService;

  static final Map<String, _PackageCacheEntry> _cache = {};
  static String? _cookie;

  @override
  Future<List<SearchProduct>> searchProducts(String query) async {
    return _searchService.searchProducts(query);
  }

  @override
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required MSStoreRing ring,
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
      final (packages: Set<PackageInfo> uwpPkgs, expiryUtc: DateTime expiry) =
          await _getUwpPackages(productId, ring);
      packages = uwpPkgs;
      expiryDate = expiry;
    } else {
      final Set<PackageInfo> win32Pkgs = await _getWin32Packages(productId);
      packages = win32Pkgs;
      expiryDate = .now().add(const Duration(minutes: 2));
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

  Future<Set<PackageInfo>> _getWin32Packages(String productId) async {
    final Win32ManifestDto manifest = await _win32Service.getPackageManifest(
      productId,
    );
    final List<Versions>? versions = manifest.data?.versions;
    if (versions == null || versions.isEmpty) return {};

    final pkgs = <PackageInfo>{};
    final urls = <String>{};

    for (final Versions version in versions) {
      for (final Installers installer in version.installers ?? <Installers>[]) {
        final String? url = installer.installerUrl;
        if (url == null || urls.contains(url)) continue;

        final String fileType =
            installer.installerType ?? url.substring(url.lastIndexOf('.') + 1);
        if (!['exe', 'msi'].contains(fileType.toLowerCase())) continue;

        pkgs.add(
          PackageInfo(
            id: productId,
            isDependency: false,
            uri: url,
            arch: installer.architecture ?? _xmlParser.extractArchitecture(url),
            fileModel: FileModel(
              fileName: "${installer.installerLocale!}-${url.split('/').last}",
              fileType: fileType,
              digest: installer.installerSha256!.toLowerCase(),
            ),
            commandLines: installer.installerSwitches?.silent?.replaceAll(
              '"',
              '',
            ),
          ),
        );
        urls.add(url);
      }
    }
    return pkgs;
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
            downloadUrl = UwpXmlParser.parseDownloadUrl(
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
    final List<File> files = _fileService.listDownloadedFiles(productId, ring);
    if (files.isEmpty) return [];

    final MSStoreAppType? appType = .fromProductId(productId);
    final results = <ProcessResult>[];

    final cacheKey = '$productId-${ring.value}';
    final _PackageCacheEntry? packageCache = _cache[cacheKey];

    if (appType == .uwp) {
      final String basePath = _fileService.getTempPath(productId, ring);
      final baseDir = Directory(basePath);
      final depsDir = Directory('$basePath\\Dependencies');

      // Install dependencies first if they exist
      if (depsDir.existsSync()) {
        final Iterable<File> deps = depsDir.listSync().whereType<File>();
        for (final file in deps) {
          final String fileName = p.basenameWithoutExtension(file.path);
          final String fileHash = await _fileService.computeFileSha256(file);

          final PackageInfo? matchedPkg = packageCache?.packages.firstWhereOrNull(
            (pkg) => pkg.fileModel?.digest == fileHash,
          );

          if (matchedPkg != null) {
            logger.i('Hash verified for dependency: $fileName');
          } else {
            logger.w('Hash verification failed for dependency: $fileName');
          }

          results.add(await _fileService.runAppxInstall(file.path));
        }
      }

      final Iterable<File> mainFiles = baseDir
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.contains('Dependencies'));

      for (final file in mainFiles) {
        final String fileName = p.basenameWithoutExtension(file.path);
        final String fileHash = await _fileService.computeFileSha256(file);

        final PackageInfo? matchedPkg = packageCache?.packages.firstWhereOrNull(
          (pkg) => pkg.fileModel?.digest == fileHash,
        );

        if (matchedPkg != null) {
          logger.i('Hash verified for package: $fileName');
        } else {
          logger.w('Hash verification failed for package: $fileName');
        }

        results.add(await _fileService.runAppxInstall(file.path));
      }
    } else {
      for (final file in files) {
        final String fileName = p.basenameWithoutExtension(file.path);
        final String fileHash = await _fileService.computeFileSha256(file);

        final PackageInfo? matchedPkg = packageCache?.packages.firstWhereOrNull(
          (pkg) {
            return pkg.fileModel?.digest! == fileHash;
          },
        );

        if (matchedPkg != null) {
          logger.i('Matched package by digest for $fileName');
        }

        final List<String> arguments =
            matchedPkg?.commandLines?.split(' ') ?? List<String>.empty();

        results.add(await _fileService.runWin32Install(file.path, arguments));
      }
    }
    return results;
  }

  @override
  Future<void> cleanup() async {
    await _fileService.cleanupDownloads();
    _cache.clear();
    _cookie = null;
  }
}
