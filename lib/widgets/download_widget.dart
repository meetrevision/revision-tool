import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:dio/dio.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/models/ms_store/packages_info.dart';

import '../services/msstore_service.dart';
import 'dialogs/msstore_dialogs.dart';

class DownloadWidget extends StatefulWidget {
  final List<PackagesInfo> items;
  final String productId;

  const DownloadWidget({
    Key? key,
    required this.items,
    required this.productId,
  }) : super(key: key);

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
    _streams = widget.items
        .map((item) => _dio.download(
              item.uri!,
              '${Directory.systemTemp.path}\\Revision-Tool\\MSStore\\${widget.productId}\\${item.name}.${item.extension}',
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
                child: Text(ReviLocalizations.of(context).install),
                onPressed: () async {
                  showLoadingDialog(
                      context, ReviLocalizations.of(context).installing);

                  List<ProcessResult> processResult = [];
                  if (widget.items.first.extension == "exe" ||
                      widget.items.first.extension == "msi") {
                    for (final item in widget.items) {
                      processResult.add(await _ms.installNonUWPPackages(
                          '${Directory.systemTemp.path}\\Revision-Tool\\MSStore\\${widget.productId}\\',
                          "${item.name}.${item.extension}",
                          item.commandLines!));
                    }
                  } else {
                    processResult.addAll(await _ms.installUWPPackages(
                        '${Directory.systemTemp.path}\\Revision-Tool\\MSStore\\${widget.productId}'));
                  }

                  if (!mounted) return;
                  Navigator.pop(context);

                  await showInstallProcess(context, processResult);
                },
              ),
              Button(
                child: Text(ReviLocalizations.of(context).close),
                onPressed: () => Navigator.pop(context),
              ),
            ] else ...[
              MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Button(
                  child: Text(ReviLocalizations.of(context).install),
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
    for (var progress in _progressList) {
      progress.dispose();
    }
    _downloadCompletionController.close();
    _dio.close();
    super.dispose();
  }
}
