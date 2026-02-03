import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_state.freezed.dart';

@freezed
sealed class MSStoreDownloadState with _$MSStoreDownloadState {
  const factory MSStoreDownloadState.idle() = _Idle;
  const factory MSStoreDownloadState.downloading({
    required Map<String, double> progress,
    required int completedCount,
    required int totalCount,
  }) = _Downloading;
  const factory MSStoreDownloadState.completed() = _Completed;
  const factory MSStoreDownloadState.error(String message) = _Error;
}
