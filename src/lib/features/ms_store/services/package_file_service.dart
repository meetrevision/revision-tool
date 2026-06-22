import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:process_run/shell_run.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../utils.dart';
import '../store_enums.dart';

final storePackageFileServiceProvider = Provider<PackageFileService>((ref) {
  return PackageFileService(ref.read(apiClientProvider));
});

/// Service for file system operations related to MS Store packages.
class PackageFileService {
  const PackageFileService(this._api);

  final ApiClient _api;

  static final String _storeFolder =
      '${Directory.systemTemp.path}\\Revision-Tool\\MSStore';

  String downloadPath(String downloadId, StoreRing ring) {
    return '$_storeFolder\\$downloadId\\${ring.value}';
  }

  Future<Result<void>> download(
    String url,
    String path, {
    void Function(int count, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(path);
    final Directory dir = file.parent;

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final Result<Response<dynamic>> result = await _api.downloadFile(
      Uri.parse(url),
      path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );

    return result.when(
      success: (Response<dynamic> response) => const Result<void>.success(null),
      failure: Result<void>.failure,
    );
  }

  /// Deletes the root temporary store folder
  Future<void> cleanup() async {
    final dir = Directory(_storeFolder);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
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

  /// Verifies Store API digests.
  /// UWP payloads may expose SHA1 as `Digest` and SHA256 as `AdditionalDigest`.
  Future<bool> verifyFileDigest({
    required File file,
    required String digest,
    required String algorithm,
  }) async {
    final String expected = digest.trim();
    if (expected.isEmpty) return false;

    final Digest actualDigest;
    switch (algorithm.toUpperCase().trim()) {
      case 'SHA1':
        actualDigest = await sha1.bind(file.openRead()).first;
      case 'SHA256':
        actualDigest = await sha256.bind(file.openRead()).first;
      default:
        return false;
    }

    final bool isHexDigest = RegExp(
      r'^([0-9a-fA-F]{40}|[0-9a-fA-F]{64})$',
    ).hasMatch(expected);
    if (isHexDigest) {
      // Win32 Store API hashes are already decoded SHA256 hex strings.
      return actualDigest.toString().toLowerCase() == expected.toLowerCase();
    }

    try {
      return const ListEquality<int>().equals(
        actualDigest.bytes,
        base64.decode(base64.normalize(expected)),
      );
    } on FormatException {
      return false;
    }
  }
}
