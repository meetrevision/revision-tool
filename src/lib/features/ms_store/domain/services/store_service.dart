import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/int_bytes.dart';
import '../../../../core/services/win_registry_service.dart';
import '../../../../core/utils/base_service.dart';
import '../../../../utils.dart';
import '../../data/repositories/ms_store_repository.dart';
import '../../data/services/package_file_service.dart';

import '../entities/package_info.dart';
import '../entities/product_details.dart';
import '../entities/search_product.dart';
import '../entities/store_download_info.dart';
import '../entities/store_enums.dart';

final _punctuationRegex = RegExp(r'[^A-Za-z0-9,]'); // remove all punctuation except commas

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(
    uwpRepository: ref.read(uwpStoreRepositoryProvider),
    win32Repository: ref.read(win32StoreRepositoryProvider),
    fileService: ref.read(storePackageFileServiceProvider),
  );
});

final class const StoreService({
  required final StoreRepository _uwpRepository,
  required final StoreRepository _win32Repository,
  required final PackageFileService _fileService,
}) with BaseService {
  static final _locks = <String, RandomAccessFile>{};

  /// Cached arch index per package set. First lookup counts in O(n),
  /// repeat lookups on the same ISet instance hit the cache in O(1).
  static final _archCounts = CacheKey<ISet<PackageInfo>, Map<String, int>>((packages) {
    final counts = <String, int>{};
    for (final p in packages) {
      final String arch = p.arch.toLowerCase();
      counts[arch] = (counts[arch] ?? 0) + 1;
    }
    return counts;
  });

  @override
  ErrorMapper get errorMapper => (error, stackTrace) {
    if (error is AppException) return error;
    return UnexpectedNetworkException(cause: error);
  };

  @override
  String get logTag => 'StoreService';

  void _lockFile(String path) {
    if (_locks.containsKey(path)) return;
    final file = File(path);
    // Skip lock if file not on disk (e.g. mocked download in tests).
    // Real download always creates file before lock.
    if (!file.existsSync()) return;
    try {
      final RandomAccessFile lock = file.openSync();
      lock.lockSync(FileLock.blockingShared);
      _locks[path] = lock;
    } on FileSystemException {
      // Lock failed, ignore. File may be missing or locked elsewhere.
      return;
    }
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
    // Copy keys first: _unlockFile mutates _locks during iteration.
    _locks.keys.toIList().forEach(_unlockFile);
  }

  void _trackDownloadedFile(String path) => _lockFile(path);

  Future<Result<IList<SearchProduct>>> searchProducts(String query) => run(() async {
    final IList<SearchProduct> results = await _uwpRepository.searchProducts(query);
    return results.where((p) => p.displayPrice == 'Free').toIList();
  });

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
      // Group IDs by app type with a mutable accumulator, lock once at the end.
      final Map<StoreAppType, Set<String>> idsByType = {};
      for (final String id in productIds.map((id) => id.toUpperCase())) {
        final StoreAppType? type = .fromProductId(id);
        if (type == null) continue;
        idsByType.putIfAbsent(type, () => {}).add(id);
      }
      // fromEntries builds the IMap in one pass (no intermediate Map copy).
      final IMap<StoreAppType, ISet<String>> groupedIds = .fromEntries(
        idsByType.entries.map((e) => MapEntry(e.key, e.value.lock)),
      );

      if (groupedIds.isEmpty) {
        throw const UnexpectedNetworkException(message: 'At least one product ID required');
      }

      final String resolvedArch = arch == .auto
          ? (WinRegistryService.cpuArch == 'amd64' ? 'x64' : 'arm64')
          : arch.value;

      var merged = const IMap<String, ISet<PackageInfo>>.empty();

      // Fetch for each type in parallel
      for (final MapEntry<StoreAppType, ISet<String>> entry in groupedIds.entries) {
        final StoreAppType type = entry.key;
        final StoreRepository repo = type == .uwp ? _uwpRepository : _win32Repository;
        await Future.wait(
          entry.value.map((productId) async {
            final ISet<PackageInfo> all = await repo.getPackages(productId: productId, ring: ring);
            // Touch the arch-count cache so repeat inspections on the same
            // instance are O(1). Cheap, zero overhead if unused elsewhere.
            all.cached(_archCounts);
            final ISet<PackageInfo> packages = all.where((p) {
              if (arch == .all) return true;
              final String a = p.arch.toLowerCase();
              if (a == 'neutral' || a == resolvedArch) return true;
              return p.isDependency &&
                  ((resolvedArch == 'x64' && a == 'x86') ||
                      (resolvedArch == 'arm64' && a == 'arm'));
            }).toISet();

            if (packages.isEmpty) {
              throw UnexpectedNetworkException(
                cause: Exception('No matching packages for $productId arch=${arch.value}'),
              );
            }
            merged = merged.add(productId, packages);
          }),
        );
      }
      return merged;
    });
  }

  Future<Result<ISet<StorePackageFileDownload>>> download({
    required StoreRing ring,
    required IMap<String, Iterable<PackageInfo>> packagesByProductId,
    required void Function(StorePackageDownloadProgress) onProgress,
    required CancelToken cancelToken,
    String? downloadPath,
  }) async {
    return run(() async {
      if (downloadPath != null && downloadPath.isNotEmpty) {
        final dir = Directory(downloadPath);
        if (!dir.existsSync()) dir.createSync(recursive: true);
      }

      // Flatten once into an immutable set; iteration is allocation-free after.
      final ISet<({PackageInfo package, String productId})> flat = packagesByProductId.entries
          .expand(
            (entry) => entry.value.map((pkg) => (package: pkg, productId: entry.key.toUpperCase())),
          )
          .toISet();

      final String downloadId = packagesByProductId.keys.length == 1
          ? packagesByProductId.keys.first.toUpperCase()
          : DateTime.now().millisecondsSinceEpoch.toString();

      final int totalPackages = flat.length;
      final int totalBytes = flat.fold<int>(0, (s, e) => s + e.package.expectedBytes);
      var downloadedBytes = 0;
      var completedCount = 0;
      var downloads = const ISet<StorePackageFileDownload>.empty();
      if (cancelToken.isCancelled) return downloads;

      for (final item in flat) {
        if (cancelToken.isCancelled) return downloads;

        final PackageInfo package = item.package;
        final String productId = item.productId;
        final StoreAppType type = StoreAppType.fromProductId(productId)!;

        // Build local path
        final String tempDir = downloadPath ?? _fileService.downloadPath(downloadId, ring);
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
              : package.expectedBytes <= 0 || cachedFile.lengthSync() == package.expectedBytes;
          if (valid) {
            downloads = downloads.add(
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
          .uwp => await _uwpRepository.getPackageDownloadUrl(package: package, ring: ring),
          .win32 => await _win32Repository.getPackageDownloadUrl(package: package, ring: ring),
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
        if (result is Failure) {
          final file = File(storedPath);
          if (file.existsSync()) await file.delete();
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
        downloads = downloads.add(download);
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
  Future<Result<IMap<String, ProcessResult>>> install({
    required ISet<StorePackageFileDownload> downloads,
  }) async {
    return run(() async {
      if (downloads.isEmpty) {
        throw ArgumentError.value(downloads, 'downloads', 'Must not be empty');
      }

      // ISet iteration preserves insertion order; concat deps-first without
      // allocating an intermediate growable List.
      final IList<StorePackageFileDownload> ordered = downloads
          .where((d) => d.appType == .uwp && d.package.isDependency)
          .followedBy(downloads.where((d) => !(d.appType == .uwp && d.package.isDependency)))
          .toIList();

      var results = const IMap<String, ProcessResult>.empty();
      for (final download in ordered) {
        final PackageInfo package = download.package;
        if (package.hasDigest) {
          final bool ok = await _fileService.verifyFileDigest(
            file: File(download.path),
            digest: package.digest!,
            algorithm: package.algorithm!,
          );
          if (!ok) {
            throw Exception('Hash verification failed for ${package.progressName}');
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
        results = results.add(package.id, installResult);
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
