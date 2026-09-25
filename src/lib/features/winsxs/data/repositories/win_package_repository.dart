import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../domain/entities/win_package.dart';
import '../models/release_model.dart';

/// Package data operations. Returns domain entities, throws on failure.
/// Only the service layer wraps calls in [Result].
abstract interface class WinPackageRepository() {
  Future<ReleaseModel> fetchRelease();

  Future<void> downloadAsset({required CabAsset asset, required String filePath});

  void ensureDirectory(String path);

  bool fileExists(String path);

  void copyFile({required String sourcePath, required String targetPath});

  String? findBundledPackage(WinPackageType type);

  Future<IList<String>> fetchInstalledPackageNames(WinPackageType type);

  Future<String> fetchSignatureUsage(String packagePath);

  Future<void> addPackage(String packagePath);

  Future<void> removePackages(WinPackageType type);

  Future<void> removePackagesExcept(WinPackageType type, String keepPackageName);

  void deleteTempPackage(String packagePath);

  bool isPackageInstalled(WinPackageType type);
}
