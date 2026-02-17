import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:process_run/shell_run.dart';

import '../../../utils.dart';
import '../ms_store_enums.dart';

/// Service for file system operations related to MS Store packages.
class PackageFileService {
  const PackageFileService();

  static final String _storeFolder =
      '${Directory.systemTemp.path}\\Revision-Tool\\MSStore';

  /// Returns the temporary path for a specific product and ring
  String getTempPath(String productId, MSStoreRing ring) {
    return '$_storeFolder\\$productId\\${ring.value}';
  }

  /// Downloads a file from [url] to [path] with progress reporting
  Future<void> downloadPackage(
    String url,
    String path, {
    bool isDependency = false,
    void Function(int count, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(path);
    final Directory dir = isDependency
        ? Directory('${file.parent.path}\\Dependencies')
        : file.parent;

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final finalPath = isDependency
        ? '${dir.path}\\${file.uri.pathSegments.last}'
        : path;

    final dio = Dio();
    await dio.download(
      url,
      finalPath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  /// Deletes the root temporary store folder
  Future<void> cleanupDownloads() async {
    final dir = Directory(_storeFolder);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Lists all files in the temporary folder for a product and ring
  List<File> listDownloadedFiles(String productId, MSStoreRing ring) {
    final String path = getTempPath(productId, ring);
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    final files = <File>[];
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    return files;
  }

  /// Installs a UWP (AppX/Msix) package
  Future<ProcessResult> runAppxInstall(String path) async {
    final ProcessResult result = await runPSCommand(
      'Add-AppxPackage -Path "$path" -ForceApplicationShutdown',
    );
    return result;
  }

  /// Installs a Win32 (exe/msi) package with optional silent arguments
  Future<ProcessResult> runWin32Install(String path, List<String> args) async {
    return runExecutableArguments(path, args, verbose: true);
  }

  /// Computes the SHA-256 hash of a file and returns it as lowercase hex string
  Future<String> computeFileSha256(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final Digest digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  /// Verifies the file digest against expected hex string (case-insensitive)
  Future<bool> verifyFileDigest(File file, String? expectedHex) async {
    if (expectedHex == null || expectedHex.isEmpty) return false;
    final String actual = await computeFileSha256(file);
    return actual == expectedHex.toLowerCase();
  }
}
