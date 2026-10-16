import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:adaptive_palette/adaptive_palette.dart';
import 'package:dio/dio.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/result.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../../../appx/domain/entities/appx_package.dart';
import '../../domain/entities/download_state.dart';
import '../../domain/entities/package_info.dart';
import '../../domain/entities/product_details.dart';
import '../../domain/entities/search_product.dart';
import '../../domain/entities/store_download_info.dart';
import '../../domain/entities/store_enums.dart';
import '../../domain/services/store_service.dart';

part 'store_providers.g.dart';

/// Dart 3 record + FIC: 100% type-safe, immutable, value-equal state in a
/// single line. No freezed, no Equatable props to forget, no build_runner.
/// IList/ISet/IMap compare by value, so Riverpod dedupes identical emissions
/// synchronously instead of rebuilding on every identical List/Set/Map.
typedef StoreState = ({
  StoreRing ring,
  StoreDownloadState download,
  StorePackagesByProductId? sessionPackages,
  bool sessionInstallAfter,
  ISet<StorePackageFileDownload> sessionDownloads,
});

extension StoreStateX on StoreState {
  StoreState copyWith({
    StoreRing? ring,
    StoreDownloadState? download,
    StorePackagesByProductId? sessionPackages,
    bool? sessionInstallAfter,
    ISet<StorePackageFileDownload>? sessionDownloads,
  }) => (
    ring: ring ?? this.ring,
    download: download ?? this.download,
    sessionPackages: sessionPackages ?? this.sessionPackages,
    sessionInstallAfter: sessionInstallAfter ?? this.sessionInstallAfter,
    sessionDownloads: sessionDownloads ?? this.sessionDownloads,
  );
}

typedef _ProgressTotals = ({int completed, int total, int downloadedBytes, int totalBytes});

const _ProgressTotals _zeroTotals = (completed: 0, total: 0, downloadedBytes: 0, totalBytes: 0);

@Riverpod(keepAlive: true)
class StoreController() extends _$StoreController {
  static const _progressUpdateDelay = Duration(milliseconds: 300);

  CancelToken? _cancelToken;
  Timer? _progressTimer;

  // Mutable pending buffer for high-frequency progress callbacks.
  // Locked into IMap only on flush (every 300ms), so per-chunk updates stay O(1).
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
      download: const .idle(),
      sessionPackages: null,
      sessionInstallAfter: false,
      sessionDownloads: const ISetConst({}),
    );
  }

  void setRing(StoreRing ring) => state = state.copyWith(ring: ring);

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
    required ISet<PackageInfo> packages,
    bool install = false,
  }) => _start(
    productId: productId,
    ring: ring,
    arch: .auto,
    install: install,
    existingPackages: IMap({productId: packages}),
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
    // Pausing (not cancelling) keeps partially downloaded files on disk, so
    // resume() continues from the bytes already downloaded.
    _cancelToken?.cancel(StoreService.pauseReason);
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
    final StoreService service = ref.read(storeServiceProvider)..releaseDownloadLocks();
    // A paused download left partial files behind for resuming; drop them.
    unawaited(service.discardPartialDownloads());
    state = (
      ring: state.ring,
      download: const .idle(),
      sessionPackages: null,
      sessionInstallAfter: false,
      sessionDownloads: const ISetConst({}),
    );
  }

  String? downloadFolderPath() =>
      state.sessionDownloads.isEmpty ? null : File(state.sessionDownloads.first.path).parent.path;

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
      download: .preparing(productId: productId, message: t.msstoreSearchingPackages),
    );

    try {
      final StorePackagesByProductId packages =
          existingPackages ?? await _fetchPackages(productId: productId, ring: ring, arch: arch);

      state = state.copyWith(
        ring: ring,
        sessionPackages: packages,
        sessionInstallAfter: install,
        sessionDownloads: const ISetConst({}),
        download: .preparing(productId: productId, message: t.msstorePreparingToDownload),
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
      .getPackages(productIds: {productId}.lock, ring: ring, arch: arch)
      .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

  Future<void> _performDownload({required String productId, StoreDownloadState? resumeFrom}) async {
    final StorePackagesByProductId packages = state.sessionPackages!;
    final int totalCount = packages.totalPackageCount;
    final int totalBytes = packages.totalExpectedBytes;

    final bool resuming =
        resumeFrom?.mapOrNull(
          paused: (p) {
            _pendingProgress
              ..clear()
              ..addAll(p.progress.unlockView);
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
          progress: const IMapConst({}),
          completedCount: 0,
          totalCount: totalCount,
          downloadedBytes: 0,
          totalBytes: totalBytes,
        ),
      );
    }

    final CancelToken cancelToken = _cancelToken!;
    try {
      final ISet<StorePackageFileDownload> downloads = await ref
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
            installResults: const IMapConst({}),
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

    final IMap<String, ProcessResult> result = await ref
        .read(storeServiceProvider)
        .install(downloads: state.sessionDownloads)
        .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

    if (_cancelToken?.isCancelled == true) return;

    state = state.copyWith(
      download: .completed(productId: productId, installResults: result, installed: true),
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
          // Lock once per flush: O(n) copy every 300ms instead of O(log n)
          // structural update per downloaded chunk.
          progress: _pendingProgress.lock,
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

/// Search results for the MS Store page.
///
/// Kept separate from [StoreController] (which is `keepAlive` for downloads) so
/// results are auto-disposed together with the page and its query text,
/// instead of lingering after navigating to another page.
@riverpod
class StoreSearch() extends _$StoreSearch {
  @override
  AsyncValue<IList<SearchProduct>> build() => const .data(IListConst([]));

  Future<void> search(String query) async {
    state = const .loading();
    final Result<IList<SearchProduct>> result = await ref
        .read(storeServiceProvider)
        .searchProducts(query);
    if (!ref.mounted) return;
    state = result.when(
      success: (p) => .data(p),
      failure: (e) => .error(e, .current),
    );
  }
}

@riverpod
class StoreProductDetails() extends _$StoreProductDetails {
  @override
  FutureOr<ProductDetails> build(String productId) async {
    final Result<ProductDetails> result = await ref
        .read(storeServiceProvider)
        .getProductDetails(productId);
    return result.when(success: (v) => v, failure: (e) => throw e);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

@riverpod
Future<String?> storeProductPackageFamilyName(Ref ref, String productId) async {
  final Result<String?> result = await ref
      .read(storeServiceProvider)
      .getPackageFamilyName(productId);
  return result.when(
    success: (name) {
      // A product's family name never changes: cache successful lookups for
      // the session so hovering search results doesn't re-hit the network.
      // Failures stay auto-disposed and are retried next time.
      ref.keepAlive();
      return name;
    },
    failure: (error) => throw error,
  );
}

/// Installed package for [productId] for the current user, or `null`.
///
/// Built from the same providers as the product page, so search results and
/// the product page always agree, and install/uninstall invalidations on the
/// product page propagate here.
@riverpod
Future<AppxPackage?> storeProductInstalledPackage(Ref ref, String productId) async {
  final String? familyName = await ref.watch(
    storeProductPackageFamilyNameProvider(productId).future,
  );
  if (familyName == null) return null;
  return ref.watch(appxInstalledPackageProvider(familyName).future);
}

@riverpod
Future<bool> storeProductUpdateAvailable(
  Ref ref,
  String productId,
  String familyName,
  String installedVersion,
) async {
  final StoreRing ring = ref.watch(storeControllerProvider.select((s) => s.ring));
  final Result<bool> result = await ref
      .read(storeServiceProvider)
      .isUpdateAvailable(
        productId: productId,
        familyName: familyName,
        installedVersion: installedVersion,
        ring: ring,
      );
  return result.when(success: (available) => available, failure: (error) => throw error);
}

@Riverpod(keepAlive: true)
Future<IList<Color>?> msStoreProductPalette(
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
    final List<Color> colors = await FluidPaletteExtractor.extractColors(resizeImage);
    return colors.lock;
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
