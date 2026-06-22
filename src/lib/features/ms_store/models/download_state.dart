import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_state.freezed.dart';

@freezed
sealed class StoreDownloadState with _$StoreDownloadState {
  const factory StoreDownloadState.idle() = _Idle;

  const factory StoreDownloadState.preparing({
    required String productId,
    String? message,
  }) = _Preparing;

  const factory StoreDownloadState.downloading({
    required String productId,
    required Map<String, double> progress,
    required int completedCount,
    required int totalCount,
    required int downloadedBytes,
    required int totalBytes,
  }) = _Downloading;

  const factory StoreDownloadState.paused({
    required String productId,
    required Map<String, double> progress,
    required int completedCount,
    required int totalCount,
    required int downloadedBytes,
    required int totalBytes,
  }) = _Paused;

  const factory StoreDownloadState.completed({
    required String productId,
    required Map<String, ProcessResult> installResults,
    required bool installed,
  }) = _Completed;

  const factory StoreDownloadState.error({
    required String productId,
    required String message,
  }) = _Error;
}

extension StoreDownloadStateX on StoreDownloadState {
  bool isForProduct(String productId) {
    return maybeWhen(
      preparing: (id, _) => id == productId,
      downloading: (id, _, _, _, _, _) => id == productId,
      paused: (id, _, _, _, _, _) => id == productId,
      completed: (id, _, _) => id == productId,
      error: (id, _) => id == productId,
      orElse: () => false,
    );
  }

  bool get isTerminal => maybeWhen(
    completed: (_, _, _) => true,
    error: (_, _) => true,
    orElse: () => false,
  );

  Map<String, ProcessResult>? get installResults =>
      maybeWhen(completed: (_, r, _) => r, orElse: () => null);

  String? get errorMessage => maybeWhen(error: (_, m) => m, orElse: () => null);
}
