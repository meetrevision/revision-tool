import '../store_enums.dart';
import 'package_info.dart';

typedef StorePackagesByProductId = Map<String, Set<PackageInfo>>;

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
