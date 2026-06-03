import 'dart:developer' as developer;

import 'package:adaptive_palette/adaptive_palette.dart';
import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import '../../core/services/win_registry_service.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils.dart';
import 'models/download_state.dart';
import 'models/package_info.dart';
import 'models/product_details/product_details.dart';
import 'models/search/search_product.dart';
import 'ms_store_enums.dart';
import 'ms_store_repository.dart';
import 'services/ms_store_product_details_service.dart';
import 'services/package_file_service.dart';
import 'services/uwp_xml_parser.dart';

part 'ms_store_providers.g.dart';

@Riverpod(keepAlive: true)
MSStoreRepository msStoreRepository(Ref ref) {
  final ApiClient api = ref.watch(apiClientProvider);
  final detailsService = MSStoreProductDetailsService(api);
  const xmlParser = UwpXmlParser();
  final fileService = PackageFileService(api);

  return MSStoreRepositoryImpl(
    uwpService: .new(api),
    searchService: .new(api),
    detailsService: detailsService,
    xmlParser: xmlParser,
    fileService: fileService,
    installerService: .new(fileService),
    win32PackageService: .new(
      api: api,
      detailsService: detailsService,
      xmlParser: xmlParser,
    ),
  );
}

@Riverpod(keepAlive: true)
Future<ProductDetails> msStoreProductDetails(Ref ref, String productId) async {
  final Result<ProductDetails> result = await ref
      .read(msStoreRepositoryProvider)
      .getProductDetails(productId);
  return result.when(
    success: (value) => value,
    failure: (exception) => throw exception,
  );
}

@Riverpod(keepAlive: true)
class MSStoreSearch extends _$MSStoreSearch {
  @override
  FutureOr<List<SearchProduct>> build() => [];

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await .guard(() async {
      final Result<List<SearchProduct>> result = await ref
          .read(msStoreRepositoryProvider)
          .searchProducts(query);

      return result.when(
        success: (value) => value,
        failure: (exception) => throw exception,
      );
    });
  }
}

@Riverpod(keepAlive: true)
class MSStorePackages extends _$MSStorePackages {
  @override
  FutureOr<Set<PackageInfo>> build(String productId, MSStoreRing ring) async {
    final ProductDetails? cachedDetails = ref
        .read(msStoreProductDetailsProvider(productId))
        .maybeWhen(data: (d) => d, orElse: () => null);

    final Result<Set<PackageInfo>> result = await ref
        .read(msStoreRepositoryProvider)
        .getPackages(
          productId: productId,
          ring: ring,
          cachedDetails: cachedDetails,
        );
    return result.when(
      success: (value) => value,
      failure: (exception) => throw exception,
    );
  }
}

@riverpod
class MSStoreDownload extends _$MSStoreDownload {
  CancelToken? _cancelToken;

  @override
  MSStoreDownloadState build() {
    ref.onDispose(() {
      try {
        if (_cancelToken != null && !_cancelToken!.isCancelled) {
          _cancelToken!.cancel();
        }
      } on Object catch (error, stackTrace) {
        developer.log(
          'Error while cancelling download on dispose',
          error: error,
          stackTrace: stackTrace,
          name: 'MSStoreDownload',
        );
      }
    });
    return const .idle();
  }

  Future<void> download({
    required String productId,
    required MSStoreRing ring,
    required MSStoreArch arch,
  }) async {
    _cancelToken = CancelToken();
    state = const .downloading(progress: {}, completedCount: 0, totalCount: 0);

    try {
      final MSStoreRepository repository = ref.read(msStoreRepositoryProvider);

      // Get packages again (cached) to know how many we are downloading
      final Result<Set<PackageInfo>> packagesResult = await repository
          .getPackages(productId: productId, ring: ring);
      final Set<PackageInfo> pkgs = packagesResult.when(
        success: (value) => value,
        failure: (exception) => throw exception,
      );

      String resolvedArch = arch.value;
      if (arch == .auto) {
        resolvedArch = WinRegistryService.cpuArch == 'amd64' ? 'x64' : 'arm64';
      }

      final List<PackageInfo> filtered = pkgs
          .where(
            (p) =>
                arch == .all || p.arch == resolvedArch || p.arch == 'neutral',
          )
          .toList();

      if (filtered.isEmpty) {
        state = .error(t.msstorePackagesNotFound);
        return;
      }

      final progressMap = <String, double>{};
      var completed = 0;

      final Result<void> result = await repository.downloadPackages(
        productId: productId,
        ring: ring,
        packages: filtered,
        cancelToken: _cancelToken!,
        onProgress: (fileName, progress) {
          if (!ref.mounted) return;

          progressMap[fileName] = progress;
          if (progress >= 1.0) {
            completed = progressMap.values.where((v) => v >= 1.0).length;
          }
          state = .downloading(
            progress: .unmodifiable(progressMap),
            completedCount: completed,
            totalCount: filtered.length,
          );
        },
      );
      result.when(success: (_) {}, failure: (exception) => throw exception);

      if (ref.mounted) {
        state = const .completed();
      }
    } catch (e) {
      if (ref.mounted && !_cancelToken!.isCancelled) {
        logger.e('MSStoreDownloadProvider error: $e');
        state = .error(e.toString());
      }
    }
  }

  void reset() {
    state = const .idle();
  }
}

/// Downscales the image (to speed up the extraction process) and extracts a color palette.
/// Caches the extracted color palette from product images.
/// Results are kept alive to avoid recalculation on repeated navigation.
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
    developer.log(
      'Extracting palette for productId: $productId from: $url',
      name: 'msStoreProductPalette',
    );
    final resizeImage = NetworkImage(url);
    final List<Color> colors = await FluidPaletteExtractor.extractColors(
      resizeImage,
    );
    return colors;
  } catch (e) {
    developer.log(
      'Error extracting palette for $productId: $e',
      name: 'msStoreProductPalette',
      level: 1000,
      error: e,
    );
    return null;
  }
}
