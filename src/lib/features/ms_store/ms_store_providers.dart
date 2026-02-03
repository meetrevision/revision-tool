import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/network_service.dart';
import '../../core/services/win_registry_service.dart';
import '../../i18n/strings.g.dart';
import '../../utils.dart';
import 'models/download_state.dart';
import 'models/package_info.dart';
import 'models/search/search_product.dart';
import 'ms_store_enums.dart';
import 'ms_store_repository.dart';

part 'ms_store_providers.g.dart';

@Riverpod(keepAlive: true)
MSStoreRepository msStoreRepository(Ref ref) {
  final NetworkService networkService = ref.watch(networkServiceProvider);
  return MSStoreRepositoryImpl(
    uwpService: .new(networkService),
    win32Service: .new(networkService),
    searchService: .new(networkService),
    xmlParser: const .new(),
    fileService: const .new(),
  );
}

@riverpod
class MSStoreSearch extends _$MSStoreSearch {
  @override
  FutureOr<List<SearchProduct>> build() => [];

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(msStoreRepositoryProvider).searchProducts(query);
    });
  }
}

@riverpod
class MSStorePackages extends _$MSStorePackages {
  @override
  FutureOr<Set<PackageInfo>> build(String productId, MSStoreRing ring) async {
    return ref
        .read(msStoreRepositoryProvider)
        .getPackages(productId: productId, ring: ring);
  }
}

@riverpod
class MSStoreDownload extends _$MSStoreDownload {
  CancelToken? _cancelToken;

  @override
  MSStoreDownloadState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
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
      final Set<PackageInfo> pkgs = await repository.getPackages(
        productId: productId,
        ring: ring,
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

      await repository.downloadPackages(
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
