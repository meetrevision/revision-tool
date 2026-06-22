import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/result.dart';
import '../../core/extensions/int_bytes.dart';
import '../../core/services/win_registry_service.dart';
import '../../core/utils/base_service.dart';
import '../../utils.dart';
import 'models/package_info.dart';
import 'models/product_details/product_details.dart';
import 'models/search/search_product.dart';
import 'models/store_download_info.dart';
import 'ms_store_repository.dart';
import 'services/package_file_service.dart';
import 'store_enums.dart';

final _punctuationRegex = RegExp(
  r'[^A-Za-z0-9,]',
); // remove all punctuation except commas

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(
    uwpRepository: ref.read(uwpStoreRepositoryProvider),
    win32Repository: ref.read(win32StoreRepositoryProvider),
    fileService: ref.read(storePackageFileServiceProvider),
  );
});

final class StoreService with BaseService {
  const StoreService({
    required this._uwpRepository,
    required this._win32Repository,
    required this._fileService,
  });

  final StoreRepository _uwpRepository;
  final StoreRepository _win32Repository;
  final PackageFileService _fileService;

  static final _locks = <String, RandomAccessFile>{};

  @override
  ErrorMapper get errorMapper => (error, stackTrace) {
    if (error is AppException) return error;
    return UnexpectedNetworkException(cause: error);
  };

  @override
  String get logTag => 'StoreService';

  void _lockFile(String path) {
    if (_locks.containsKey(path)) return;
    final RandomAccessFile lock = File(path).openSync();
    lock.lockSync(FileLock.blockingShared);
    _locks[path] = lock;
  }

  void _unlockFile(String path) {
    final RandomAccessFile? lock = _locks.remove(path);
    if (lock == null) return;
    try {
      lock.unlockSync();
    } finally {
      lock.closeSync();
    }
  }

  /// Releases locks held for download-only flows, cancel, or cleanup.
  void releaseDownloadLocks() {
    _locks.keys.toList().forEach(_unlockFile);
  }

  void _trackDownloadedFile(String path) => _lockFile(path);

  Future<Result<List<SearchProduct>>> searchProducts(String query) => run(
    () async => _uwpRepository.searchProducts(query).then((r) {
      return r.where((p) => p.displayPrice == 'Free').toList(growable: false);
    }),
  );

  Future<Result<ProductDetails>> getProductDetails(String productId) async {
    return run(() {
      if (productId.isEmpty) {
        throw ArgumentError.value(productId, 'productId', 'Must not be empty');
      }

      productId = productId.replaceAll(_punctuationRegex, '');

      productId = productId.split(',').first.trim();
      if (StoreAppType.fromProductId(productId) == null) {
        throw ArgumentError.value(productId, 'productId', 'Unknown product ID');
      }
      return _win32Repository.getProductDetails(productId);
    });
  }

  Future<Result<StorePackagesByProductId>> getPackages({
    required Iterable<String> productIds,
    StoreRing ring = .releasePreview,
    StoreArch arch = .auto,
  }) async {
    return run(() async {
      final Map<StoreAppType, Set<String>> idsByType = productIds
          .map((id) => id.toUpperCase())
          .map((id) => (StoreAppType.fromProductId(id)!, id))
          .fold<Map<StoreAppType, Set<String>>>({}, (m, e) {
            m.putIfAbsent(e.$1, () => {}).add(e.$2);
            return m;
          });

      if (idsByType.isEmpty) {
        throw const UnexpectedNetworkException(
          message: 'At least one product ID required',
        );
      }

      final String resolvedArch = arch == .auto
          ? (WinRegistryService.cpuArch == 'amd64' ? 'x64' : 'arm64')
          : arch.value;

      final merged = <String, Set<PackageInfo>>{};

      // Fetch for each type in parallel
      for (final MapEntry<StoreAppType, Set<String>> entry
          in idsByType.entries) {
        final StoreAppType type = entry.key;
        final StoreRepository repo = type == .uwp
            ? _uwpRepository
            : _win32Repository;
        await Future.wait(
          entry.value.map((productId) async {
            final Set<PackageInfo> packages =
                (await repo.getPackages(
                  productId: productId,
                  ring: ring,
                )).where((p) {
                  final String pArch = p.arch.toLowerCase();
                  return arch == .all ||
                      pArch == resolvedArch ||
                      pArch == 'neutral';
                }).toSet();

            if (packages.isEmpty) {
              throw UnexpectedNetworkException(
                cause: Exception(
                  'No matching packages for $productId arch=${arch.value}',
                ),
              );
            }
            merged[productId] = packages;
          }),
        );
      }
      return merged;
    });
  }

  Future<Result<Set<StorePackageFileDownload>>> download({
    required StoreRing ring,
    required Map<String, Iterable<PackageInfo>> packagesByProductId,
    required void Function(StorePackageDownloadProgress) onProgress,
    required CancelToken cancelToken,
  }) async {
    return run(() async {
      final flat = <({PackageInfo package, String productId})>{};
      for (final MapEntry<String, Iterable<PackageInfo>> entry
          in packagesByProductId.entries) {
        for (final PackageInfo pkg in entry.value) {
          flat.add((package: pkg, productId: entry.key.toUpperCase()));
        }
      }

      final String downloadId = packagesByProductId.keys.length == 1
          ? packagesByProductId.keys.first.toUpperCase()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final int totalPackages = flat.length;
      final int totalBytes = flat.fold<int>(
        0,
        (s, e) => s + e.package.expectedBytes,
      );
      var downloadedBytes = 0;
      var completedCount = 0;
      final downloads = <StorePackageFileDownload>{};
      if (cancelToken.isCancelled) return downloads;

      for (final item in flat) {
        if (cancelToken.isCancelled) return downloads;

        final PackageInfo package = item.package;
        final String productId = item.productId;
        final StoreAppType type = .fromProductId(productId)!;

        // Build local path
        final String tempDir = _fileService.downloadPath(downloadId, ring);
        final String fileName = package.downloadName;
        var storedPath = package.isDependency
            ? '$tempDir\\Dependencies\\$fileName'
            : '$tempDir\\$fileName';
        if (!fileName.endsWith('.${package.fileExt}')) {
          storedPath += '.${package.fileExt}';
        }

        // Use cache if valid
        var cacheHit = false;
        final cachedFile = File(storedPath);
        if (cachedFile.existsSync()) {
          final bool valid = package.hasDigest
              ? await _fileService.verifyFileDigest(
                  file: cachedFile,
                  digest: package.digest!,
                  algorithm: package.algorithm!,
                )
              : package.expectedBytes <= 0 ||
                    cachedFile.lengthSync() == package.expectedBytes;
          if (valid) {
            downloads.add(
              StorePackageFileDownload(
                downloadId: downloadId,
                ring: ring,
                appType: type,
                package: package,
                path: storedPath,
                bytes: package.expectedBytes,
              ),
            );
            cacheHit = true;
            _trackDownloadedFile(storedPath);
          }
        }
        if (cacheHit) {
          completedCount++;
          downloadedBytes += package.expectedBytes;
          onProgress(
            StorePackageDownloadProgress(
              fileName: package.progressName,
              fileProgress: 1.0,
              completedCount: completedCount,
              totalCount: totalPackages,
              downloadedBytes: totalBytes > 0
                  ? downloadedBytes.clampBytes(totalBytes)
                  : downloadedBytes,
              totalBytes: totalBytes > 0 ? totalBytes : package.expectedBytes,
            ),
          );
          continue;
        }

        if (cancelToken.isCancelled) throw const CancelledRequestException();

        // Get download URL using the correct repository
        final String url = switch (type) {
          .uwp => await _uwpRepository.getPackageDownloadUrl(
            package: package,
            ring: ring,
          ),
          .win32 => await _win32Repository.getPackageDownloadUrl(
            package: package,
            ring: ring,
          ),
        };
        if (cancelToken.isCancelled) throw const CancelledRequestException();

        // Download with progress
        var lastCount = 0;
        int lastTotal = package.expectedBytes;
        final Result<void> result = await _fileService.download(
          url,
          storedPath,
          cancelToken: cancelToken,
          onProgress: (count, total) {
            if (cancelToken.isCancelled) return;
            final int resolvedTotal = total > 0 ? total : package.expectedBytes;
            if (resolvedTotal <= 0) return;
            lastCount = count;
            lastTotal = resolvedTotal;
            onProgress(
              StorePackageDownloadProgress(
                fileName: package.progressName,
                fileProgress: count / resolvedTotal,
                completedCount: completedCount,
                totalCount: totalPackages,
                downloadedBytes: totalBytes > 0
                    ? (downloadedBytes + count).clampBytes(totalBytes)
                    : downloadedBytes + count,
                totalBytes: totalBytes > 0 ? totalBytes : resolvedTotal,
              ),
            );
          },
        );
        if (result is Failure && !cancelToken.isCancelled) {
          throw result.exception;
        }

        final download = StorePackageFileDownload(
          downloadId: downloadId,
          ring: ring,
          appType: type,
          package: package,
          path: storedPath,
          bytes: lastTotal > 0 ? lastTotal : lastCount,
        );
        downloads.add(download);
        _trackDownloadedFile(storedPath);
        completedCount++;
        downloadedBytes += download.bytes;

        onProgress(
          StorePackageDownloadProgress(
            fileName: package.progressName,
            fileProgress: 1.0,
            completedCount: completedCount,
            totalCount: totalPackages,
            downloadedBytes: totalBytes > 0
                ? downloadedBytes.clampBytes(totalBytes)
                : downloadedBytes,
            totalBytes: totalBytes > 0 ? totalBytes : download.bytes,
          ),
        );
      }
      return downloads;
    });
  }

  /// Installs a mixed set of downloads. UWP dependencies are installed first.
  Future<Result<Map<String, ProcessResult>>> install({
    required Set<StorePackageFileDownload> downloads,
  }) async {
    return run(() async {
      if (downloads.isEmpty) {
        throw ArgumentError.value(downloads, 'downloads', 'Must not be empty');
      }

      final List<StorePackageFileDownload> ordered = [
        ...downloads.where((d) => d.appType == .uwp && d.package.isDependency),
        ...downloads.where(
          (d) => !(d.appType == .uwp && d.package.isDependency),
        ),
      ];

      final results = <String, ProcessResult>{};
      for (final download in ordered) {
        final PackageInfo package = download.package;
        if (package.hasDigest) {
          final bool ok = await _fileService.verifyFileDigest(
            file: File(download.path),
            digest: package.digest!,
            algorithm: package.algorithm!,
          );
          if (!ok) {
            throw Exception(
              'Hash verification failed for ${package.progressName}',
            );
          }
          logger.i('Hash verified for ${package.progressName}');
        } else {
          logger.w('Hash verification unavailable for ${package.progressName}');
        }

        final ProcessResult installResult = switch (download.appType) {
          .uwp => await _fileService.runAppxInstall(File(download.path).path),
          .win32 => await _fileService.runWin32Install(
            File(download.path).path,
            package.commandLines?.split(' ') ?? const [],
          ),
        };
        results[package.id] = installResult;
        if (installResult.exitCode == 0) _unlockFile(download.path);
      }
      return results;
    });
  }

  Future<Result<void>> cleanup() => run(() async {
    releaseDownloadLocks();
    await _fileService.cleanup();
  });
}
