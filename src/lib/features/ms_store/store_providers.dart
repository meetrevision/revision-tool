import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:adaptive_palette/adaptive_palette.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/result.dart';
import '../../i18n/generated/strings.g.dart';
import 'models/download_state.dart';
import 'models/package_info.dart';
import 'models/product_details/product_details.dart';
import 'models/search/search_product.dart';
import 'models/store_download_info.dart';
import 'store_enums.dart';
import 'store_service.dart';

part 'store_providers.g.dart';

typedef StoreState = ({
  StoreRing ring,
  AsyncValue<List<SearchProduct>> search,
  StoreDownloadState download,
  StorePackagesByProductId? sessionPackages,
  bool sessionInstallAfter,
  Set<StorePackageFileDownload> sessionDownloads,
});

extension StoreStateX on StoreState {
  StoreState copyWith({
    StoreRing? ring,
    AsyncValue<List<SearchProduct>>? search,
    StoreDownloadState? download,
    StorePackagesByProductId? sessionPackages,
    bool? sessionInstallAfter,
    Set<StorePackageFileDownload>? sessionDownloads,
  }) => (
    ring: ring ?? this.ring,
    search: search ?? this.search,
    download: download ?? this.download,
    sessionPackages: sessionPackages ?? this.sessionPackages,
    sessionInstallAfter: sessionInstallAfter ?? this.sessionInstallAfter,
    sessionDownloads: sessionDownloads ?? this.sessionDownloads,
  );
}

typedef _ProgressTotals = ({
  int completed,
  int total,
  int downloadedBytes,
  int totalBytes,
});

const _ProgressTotals _zeroTotals = (
  completed: 0,
  total: 0,
  downloadedBytes: 0,
  totalBytes: 0,
);

@Riverpod(keepAlive: true)
class StoreController extends _$StoreController {
  static const _progressUpdateDelay = Duration(milliseconds: 300);

  CancelToken? _cancelToken;
  Timer? _progressTimer;

  final Map<String, double> _pendingProgress = {};
  _ProgressTotals _pendingTotals = _zeroTotals;

  @override
  StoreState build() {
    ref.onDispose(() {
      _progressTimer?.cancel();
      _cancelToken?.cancel();
    });

    return (
      ring: .releasePreview,
      search: const .data([]),
      download: const .idle(),
      sessionPackages: null,
      sessionInstallAfter: false,
      sessionDownloads: const {},
    );
  }

  void setRing(StoreRing ring) => state = state.copyWith(ring: ring);

  Future<void> search(String query) async {
    state = state.copyWith(search: const .loading());
    final Result<List<SearchProduct>> result = await ref
        .read(storeServiceProvider)
        .searchProducts(query);
    state = result.when(
      success: (products) => state.copyWith(search: AsyncValue.data(products)),
      failure: (error) =>
          state.copyWith(search: AsyncValue.error(error, StackTrace.current)),
    );
  }

  Future<void> download({
    required String productId,
    StoreRing ring = .releasePreview,
    StoreArch arch = .auto,
  }) => _start(productId: productId, ring: ring, arch: arch, install: false);

  Future<void> downloadAndInstall({
    required String productId,
    StoreRing ring = .releasePreview,
    StoreArch arch = .auto,
  }) => _start(productId: productId, ring: ring, arch: arch, install: true);

  Future<void> downloadPackages({
    required String productId,
    required StoreRing ring,
    required Set<PackageInfo> packages,
    bool install = false,
  }) => _start(
    productId: productId,
    ring: ring,
    arch: StoreArch.auto,
    install: install,
    existingPackages: {productId: packages},
  );

  void pause() {
    state = state.copyWith(
      download: state.download.maybeMap(
        downloading: (d) => .paused(
          productId: d.productId,
          progress: d.progress,
          completedCount: d.completedCount,
          totalCount: d.totalCount,
          downloadedBytes: d.downloadedBytes,
          totalBytes: d.totalBytes,
        ),
        orElse: () => state.download,
      ),
    );
    _cancelToken?.cancel();
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> resume() async {
    if (state.sessionPackages == null) return;
    await state.download.maybeMap(
      paused: (p) async {
        _cancelToken = CancelToken();
        state = state.copyWith(
          download: .downloading(
            productId: p.productId,
            progress: p.progress,
            completedCount: p.completedCount,
            totalCount: p.totalCount,
            downloadedBytes: p.downloadedBytes,
            totalBytes: p.totalBytes,
          ),
        );
        try {
          await _performDownload(productId: p.productId, resumeFrom: p);
        } on Exception catch (e) {
          if (_cancelToken?.isCancelled == true) return;
          state = state.copyWith(
            download: .error(productId: p.productId, message: e.toString()),
          );
        }
      },
      orElse: () {},
    );
  }

  void cancel() {
    _cancelToken?.cancel();
    _progressTimer?.cancel();
    _progressTimer = null;
    _pendingProgress.clear();
    _pendingTotals = _zeroTotals;
    ref.read(storeServiceProvider).releaseDownloadLocks();
    state = (
      ring: state.ring,
      search: state.search,
      download: const .idle(),
      sessionPackages: null,
      sessionInstallAfter: false,
      sessionDownloads: const {},
    );
  }

  String? downloadFolderPath() => state.sessionDownloads.isEmpty
      ? null
      : File(state.sessionDownloads.first.path).parent.path;

  Future<void> installCurrentDownload() async {
    await state.download.maybeMap(
      completed: (c) async {
        if (c.installed || state.sessionPackages == null) return;
        await _installPackages(c.productId);
      },
      orElse: () {},
    );
  }

  Future<void> _start({
    required String productId,
    required StoreRing ring,
    required StoreArch arch,
    required bool install,
    StorePackagesByProductId? existingPackages,
  }) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    _progressTimer?.cancel();
    _progressTimer = null;
    _pendingProgress.clear();
    _pendingTotals = _zeroTotals;

    state = state.copyWith(
      download: .preparing(
        productId: productId,
        message: t.msstoreSearchingPackages,
      ),
    );

    try {
      final StorePackagesByProductId packages =
          existingPackages ??
          await _fetchPackages(productId: productId, ring: ring, arch: arch);

      state = state.copyWith(
        ring: ring,
        sessionPackages: packages,
        sessionInstallAfter: install,
        sessionDownloads: const {},
        download: .preparing(
          productId: productId,
          message: t.msstorePreparingToDownload,
        ),
      );

      await _performDownload(productId: productId);
    } on Exception catch (e) {
      if (_cancelToken?.isCancelled == true) return;
      state = state.copyWith(
        download: .error(productId: productId, message: e.toString()),
      );
    }
  }

  Future<StorePackagesByProductId> _fetchPackages({
    required String productId,
    required StoreRing ring,
    required StoreArch arch,
  }) async => ref
      .read(storeServiceProvider)
      .getPackages(productIds: {productId}, ring: ring, arch: arch)
      .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

  Future<void> _performDownload({
    required String productId,
    StoreDownloadState? resumeFrom,
  }) async {
    final StorePackagesByProductId packages = state.sessionPackages!;
    final int totalCount = packages.values.fold<int>(
      0,
      (sum, p) => sum + p.length,
    );
    final int totalBytes = packages.values
        .expand((e) => e)
        .fold<int>(0, (s, p) => s + p.expectedBytes);

    final bool resuming =
        resumeFrom?.mapOrNull(
          paused: (p) {
            _pendingProgress
              ..clear()
              ..addAll(p.progress);
            _pendingTotals = (
              completed: p.completedCount,
              total: totalCount,
              downloadedBytes: p.downloadedBytes,
              totalBytes: p.totalBytes,
            );
            return true;
          },
        ) ??
        false;

    if (!resuming) {
      state = state.copyWith(
        download: .downloading(
          productId: productId,
          progress: const {},
          completedCount: 0,
          totalCount: totalCount,
          downloadedBytes: 0,
          totalBytes: totalBytes,
        ),
      );
    }

    final CancelToken cancelToken = _cancelToken!;
    try {
      final Set<StorePackageFileDownload> downloads = await ref
          .read(storeServiceProvider)
          .download(
            ring: state.ring,
            packagesByProductId: packages,
            cancelToken: cancelToken,
            onProgress: (p) => _onProgress(p, productId),
          )
          .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

      state = state.copyWith(sessionDownloads: downloads);

      if (cancelToken.isCancelled) return;

      if (state.sessionInstallAfter) {
        await _installPackages(productId);
      } else {
        ref.read(storeServiceProvider).releaseDownloadLocks();
        state = state.copyWith(
          download: .completed(
            productId: productId,
            installResults: const {},
            installed: false,
          ),
        );
      }
    } on Exception {
      if (cancelToken.isCancelled) return;
      rethrow;
    }
  }

  Future<void> _installPackages(String productId) async {
    if (state.sessionPackages == null) return;

    state = state.copyWith(
      download: .preparing(productId: productId, message: t.msstoreInstalling),
    );

    final Map<String, ProcessResult> result = await ref
        .read(storeServiceProvider)
        .install(downloads: state.sessionDownloads)
        .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

    if (_cancelToken?.isCancelled == true) return;

    state = state.copyWith(
      download: .completed(
        productId: productId,
        installResults: result,
        installed: true,
      ),
    );
  }

  void _onProgress(StorePackageDownloadProgress p, String productId) {
    _pendingProgress[p.fileName] = p.fileProgress;
    _pendingTotals = (
      completed: p.completedCount,
      total: p.totalCount,
      downloadedBytes: p.downloadedBytes,
      totalBytes: p.totalBytes,
    );

    if (p.fileProgress >= 1.0 && p.completedCount >= p.totalCount) {
      _progressTimer?.cancel();
      _progressTimer = null;
      _flushProgress(productId);
      return;
    }

    _progressTimer ??= Timer(_progressUpdateDelay, () {
      _progressTimer = null;
      _flushProgress(productId);
    });
  }

  void _flushProgress(String productId) {
    if (_cancelToken?.isCancelled == true) return;
    state = state.copyWith(
      download: state.download.maybeMap(
        downloading: (d) => d.copyWith(
          progress: .unmodifiable(_pendingProgress),
          completedCount: _pendingTotals.completed,
          totalCount: _pendingTotals.total,
          downloadedBytes: _pendingTotals.downloadedBytes,
          totalBytes: _pendingTotals.totalBytes,
        ),
        orElse: () => state.download,
      ),
    );
  }
}

@riverpod
class StoreProductDetails extends _$StoreProductDetails {
  @override
  FutureOr<ProductDetails> build(String productId) async {
    final Result<ProductDetails> result = await ref
        .read(storeServiceProvider)
        .getProductDetails(productId);
    return result.when(success: (v) => v, failure: (e) => throw e);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

@Riverpod(keepAlive: true)
Future<List<Color>?> msStoreProductPalette(
  Ref ref,
  String productId,
  String baseImageUrl, {
  int width = 256,
  int height = 256,
}) async {
  if (baseImageUrl.isEmpty) return null;

  try {
    final url = '$baseImageUrl?w=$width&h=$height';
    dev.log(
      'Extracting palette for productId: $productId from: $url',
      name: 'msStoreProductPalette',
    );
    final resizeImage = NetworkImage(url);
    return await FluidPaletteExtractor.extractColors(resizeImage);
  } catch (e) {
    dev.log(
      'Error extracting palette for $productId: $e',
      name: 'msStoreProductPalette',
      level: 1000,
      error: e,
    );
    return null;
  }
}
