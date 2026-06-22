import '../store_enums.dart';
import 'package_info.dart';

typedef StorePackagesByProductId = Map<String, Set<PackageInfo>>;

final class StorePackageDownloadProgress {
  const StorePackageDownloadProgress({
    required this.fileName,
    required this.fileProgress,
    required this.completedCount,
    required this.totalCount,
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final String fileName;
  final double fileProgress;
  final int completedCount;
  final int totalCount;
  final int downloadedBytes;
  final int totalBytes;
}

final class StorePackageFileDownload {
  const StorePackageFileDownload({
    required this.downloadId,
    required this.ring,
    required this.appType,
    required this.package,
    required this.path,
    required this.bytes,
  });
  final String downloadId;
  final StoreRing ring;
  final StoreAppType appType;
  final PackageInfo package;
  final String path;
  final int bytes;
}
