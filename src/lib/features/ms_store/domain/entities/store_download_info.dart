import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package_info.dart';
import 'store_enums.dart';

/// Packages grouped by upper-cased product ID. IMap + ISet give structural
/// value equality, so the [StoreState] record (Dart 3 record + FIC) dedupes
/// identical emissions synchronously with zero boilerplate.
typedef StorePackagesByProductId = IMap<String, ISet<PackageInfo>>;

extension StorePackagesByProductIdX on StorePackagesByProductId {
  /// Cached flat index of packages by file name for O(1) lookups.
  /// First call builds in O(n), subsequent calls are O(1).
  static final _byFileName = CacheKey<StorePackagesByProductId, Map<String, PackageInfo>>(
    (byProduct) => {
      for (final entry in byProduct.entries)
        for (final pkg in entry.value)
          (pkg.fileModel?.fileName ?? pkg.id): pkg,
    },
  );

  PackageInfo? findByFileName(String fileName) => cached(_byFileName)[fileName];

  /// Cached totals derived from the immutable packages. Stable until the
  /// collection instance is replaced, then rebuilt lazily on next access.
  static final _totals = CacheKey<StorePackagesByProductId, ({int count, int bytes})>(
    (byProduct) => (
      count: byProduct.values.fold<int>(0, (sum, set) => sum + set.length),
      bytes: byProduct.values
          .expand((set) => set)
          .fold<int>(0, (sum, pkg) => sum + pkg.expectedBytes),
    ),
  );

  int get totalPackageCount => cached(_totals).count;
  int get totalExpectedBytes => cached(_totals).bytes;

  /// All packages flattened into a single immutable set.
  ISet<PackageInfo> get flattened => values.expand((set) => set).toISet();
}

final class const StorePackageDownloadProgress({
  required final String fileName,
  required final double fileProgress,
  required final int completedCount,
  required final int totalCount,
  required final int downloadedBytes,
  required final int totalBytes,
});

final class const StorePackageFileDownload({
  required final String downloadId,
  required final StoreRing ring,
  required final StoreAppType appType,
  required final PackageInfo package,
  required final String path,
  required final int bytes,
});

extension StorePackageFileDownloadsX on ISet<StorePackageFileDownload> {
  /// Cached index by package ID for O(1) install-result correlation.
  static final _byPackageId = CacheKey<ISet<StorePackageFileDownload>, Map<String, StorePackageFileDownload>>(
    (downloads) => {for (final d in downloads) d.package.id: d},
  );

  StorePackageFileDownload? findByPackageId(String id) => cached(_byPackageId)[id];
}
