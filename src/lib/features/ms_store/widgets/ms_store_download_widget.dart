import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../i18n/generated/strings.g.dart';
import '../../../utils.dart';
import '../models/download_state.dart';
import '../ms_store_enums.dart';
import '../ms_store_providers.dart';
import 'ms_store_dialogs.dart';

class MSStoreDownloadWidget extends ConsumerStatefulWidget {
  const MSStoreDownloadWidget({
    super.key,
    required this.productId,
    required this.ring,
    required this.arch,
  });

  final String productId;
  final MSStoreRing ring;
  final MSStoreArch arch;

  @override
  ConsumerState<MSStoreDownloadWidget> createState() =>
      _MSStoreDownloadWidgetState();
}

class _MSStoreDownloadWidgetState extends ConsumerState<MSStoreDownloadWidget> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      ref
          .read(mSStoreDownloadProvider.notifier)
          .download(
            productId: widget.productId,
            ring: widget.ring,
            arch: widget.arch,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final MSStoreDownloadState downloadState = ref.watch(
      mSStoreDownloadProvider,
    );

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
      title: Text(t.msstoreSearchingPackages),
      content: downloadState.when(
        idle: () => const Center(child: ProgressRing()),
        downloading: (progress, completed, total) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 5,
            children: [
              Text(
                t.msstoreDownloadingPackages(
                  completed: completed,
                  total: total,
                ),
              ),
              ...progress.entries.map(
                (e) => _buildDownloadItem(e.key, e.value),
              ),
            ],
          ),
        ),
        completed: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.completed, size: 40, color: Colors.green),
              const SizedBox(height: 10),
              Text(t.msstoreDownloadCompleted),
            ],
          ),
        ),
        error: (message) {
          logger.e('Error downloading MS Store packages: $message');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.error, size: 40, color: Colors.red),
                const SizedBox(height: 10),
                Text(message),
              ],
            ),
          );
        },
      ),
      actions: [
        downloadState.maybeWhen(
          completed: () => FilledButton(
            child: Text(t.install),
            onPressed: () async {
              unawaited(showLoadingDialog(context, t.installing));
              try {
                final List<ProcessResult> results = await ref
                    .read(msStoreRepositoryProvider)
                    .installPackages(
                      productId: widget.productId,
                      ring: widget.ring,
                    );

                if (context.mounted) {
                  context.pop();
                  await showInstallProcess(context, results);
                }
              } catch (e) {
                if (context.mounted) {
                  context.pop();
                  await _showError(context, e.toString());
                }
              }
            },
          ),
          orElse: () => MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: FilledButton(onPressed: null, child: Text(t.install)),
          ),
        ),
        Button(
          child: Text(t.close),
          onPressed: () {
            ref.read(mSStoreDownloadProvider.notifier).reset();
            context.pop();
          },
        ),
      ],
    );
  }

  Widget _buildDownloadItem(String fileName, double progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InfoLabel(
        label: fileName,
        child: Row(
          children: [
            Expanded(child: ProgressBar(value: progress * 100)),
            const SizedBox(width: 10),
            Text('${(progress * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Future<void> _showError(BuildContext context, String error) async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [Button(child: Text(t.close), onPressed: () => context.pop())],
      ),
    );
  }
}
