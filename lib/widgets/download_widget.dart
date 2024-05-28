import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:dio/dio.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/models/ms_store/packages_info.dart';
import 'package:revitool/services/network_service.dart';

import '../services/msstore_service.dart';
import 'dialogs/msstore_dialogs.dart';

class DownloadWidget extends StatefulWidget {
  final List<PackagesInfo> items;
  final String productId;
  final bool cleanUpAfterInstall;
  final String ring;

  const DownloadWidget({
    super.key,
    required this.items,
    required this.productId,
    required this.cleanUpAfterInstall,
    required this.ring,
  });

  @override
  State<DownloadWidget> createState() => _DownloadWidgetState();
}

class _DownloadWidgetState extends State<DownloadWidget> {
  final _dio = Dio();
  late final List<Stream<Response>> _streams;
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

    _streams = widget.items
        .map((item) => _dio.download(
              item.uri!,
              '$path\\${item.name}.${item.extension}',
              cancelToken: CancelToken(),
              onReceiveProgress: (received, total) {
                if (total != -1) {
                  final index = widget.items.indexOf(item);
                  _progressList[index].value =
                      ((received / total) * 100).floorToDouble();
                  if (received == total) {
                    _completedDownloadsCount++;
                    _downloadCompletionController.add(_completedDownloadsCount);
                  }
                }
              },
            ).asStream())
        .toList();
    _progressList =
        List.generate(widget.items.length, (_) => ValueNotifier<double>(0));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _downloadCompletionController.stream,
      builder: (context, snapshot) {
        _completedDownloadsCount = snapshot.data ?? 0;
        int itemsLength = widget.items.length;
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < itemsLength; i++)
                  Card(
                    child: InfoLabel(
                      label: widget.items[i].name!,
                      child: StreamBuilder<Response>(
                        stream: _streams[i],
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          } else {
                            final index = widget.items.indexOf(widget.items[i]);
                            return Column(
                              children: [
                                ValueListenableBuilder<double>(
                                  valueListenable: _progressList[index],
                                  builder: (context, value, child) {
                                    return Row(
                                      children: [
                                        ProgressBar(value: value),
                                        const SizedBox(width: 10),
                                        Text("$value%"),
                                      ],
                                    );
                                  },
                                )
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            if (_completedDownloadsCount == itemsLength) ...[
              FilledButton(
                child: Text(context.l10n.install),
                onPressed: () async {
                  showLoadingDialog(context, context.l10n.installing);

                  final processResult = <ProcessResult>[];
                  processResult.addAll(
                    await _ms.installPackages(widget.productId, widget.ring),
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  await showInstallProcess(context, processResult);

                  if (widget.cleanUpAfterInstall) {
                    await _ms.cleanUpDownloads();
                  }
                },
              ),
              Button(
                child: Text(context.l10n.close),
                onPressed: () => Navigator.pop(context),
              ),
            ] else ...[
              MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Button(
                  child: Text(context.l10n.install),
                  onPressed: () {},
                ),
              )
            ]
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _streams.clear();

    for (var progress in _progressList) {
      progress.dispose();
    }
    _downloadCompletionController.close();
    _dio.close();
    super.dispose();
  }
}
