import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../i18n/generated/strings.g.dart';
import '../msstore_service.dart';
import '../packages_info_dto.dart';
import 'msstore_dialogs.dart';

class MsStorePackagesDownloadWidget extends StatefulWidget {
  const MsStorePackagesDownloadWidget({
    super.key,
    required this.items,
    required this.productId,
    required this.cleanUpAfterInstall,
    required this.ring,
  });
  final List<MSStorePackagesInfoDTO> items;
  final String productId;
  final bool cleanUpAfterInstall;
  final String ring;

  @override
  State<MsStorePackagesDownloadWidget> createState() =>
      _MsStorePackagesDownloadWidgetState();
}

class _MsStorePackagesDownloadWidgetState
    extends State<MsStorePackagesDownloadWidget> {
  final _dio = Dio(
    BaseOptions(
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );
  late final List<Stream<Response<dynamic>>> _streams;
  late final List<ValueNotifier<double>> _progressList;
  final _ms = MSStoreService();
  final _downloadCompletionController = StreamController<int>.broadcast();

  int _completedDownloadsCount = 0;

  @override
  void initState() {
    super.initState();

    final path = '${_ms.storeFolder}\\${widget.productId}\\${widget.ring}';
    final directory = Directory(path);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }

    _streams = widget.items.map((item) {
      final downloadPath = item.isDependency ? '$path\\Dependencies' : path;
      return _dio
          .download(
            item.uri,
            '$downloadPath\\${item.fileModel!.fileName}.${item.fileModel!.fileType}',
            cancelToken: CancelToken(),
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final int index = widget.items.indexOf(item);
                _progressList[index].value = ((received / total) * 100)
                    .floorToDouble();
                if (received == total) {
                  _completedDownloadsCount++;
                  _downloadCompletionController.add(_completedDownloadsCount);
                }
              }
            },
          )
          .asStream();
    }).toList();

    _progressList = List.generate(
      widget.items.length,
      (_) => ValueNotifier<double>(0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int itemsLength = widget.items.length;
    return StreamBuilder<int>(
      stream: _downloadCompletionController.stream,
      builder: (context, snapshot) {
        _completedDownloadsCount = snapshot.data ?? 0;

        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                for (int i = 0; i < itemsLength; i++) _buildDownloadItem(i),
              ],
            ),
          ),
          actions: [
            if (_completedDownloadsCount == itemsLength) ...[
              FilledButton(
                child: Text(t.install),
                onPressed: () async {
                  await showLoadingDialog(context, t.installing);

                  final processResult = <ProcessResult>[];
                  processResult.addAll(
                    await _ms.installPackages(widget.productId, widget.ring),
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  await showInstallProcess(context, processResult);

                  // if (widget.cleanUpAfterInstall) {
                  //   await _ms.cleanUpDownloads();
                  // }
                },
              ),
              Button(
                child: Text(t.close),
                onPressed: () => Navigator.pop(context),
              ),
            ] else ...[
              MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Button(child: Text(t.install), onPressed: () {}),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDownloadItem(int i) {
    return Card(
      child: InfoLabel(
        label: widget.items[i].fileModel!.fileName!,
        child: StreamBuilder<Response<dynamic>>(
          stream: _streams[i],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            } else {
              final int index = widget.items.indexOf(widget.items[i]);
              return Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _progressList[index],
                    builder: (context, value, child) {
                      return Row(
                        children: [
                          ProgressBar(value: value),
                          const SizedBox(width: 10),
                          Text('$value%'),
                        ],
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _streams.clear();
    _dio.close(force: true);

    for (final ValueNotifier<double> progress in _progressList) {
      progress.dispose();
    }
    _downloadCompletionController.close();
    super.dispose();
  }
}
