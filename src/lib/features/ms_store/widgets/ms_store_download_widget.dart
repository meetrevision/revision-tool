import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/int_bytes.dart';
import '../../../i18n/generated/strings.g.dart';
import '../models/download_state.dart';
import '../models/package_info.dart';
import '../models/store_download_info.dart';
import '../store_enums.dart';
import '../store_providers.dart';
import '../store_service.dart';

final class const StorePackagePickerDialog({
    super.key,
    required final String productId,
    final StoreRing ring = .releasePreview,
    final StoreArch arch = .auto,
  }) extends ConsumerStatefulWidget {
  @override
  ConsumerState<StorePackagePickerDialog> createState() => _StorePackagePickerDialogState();
}

enum _PickerPhase() { selecting, running }

final NotifierProvider<_PackagePickerSelection, Set<String>> _packagePickerSelectionProvider =
    NotifierProvider.autoDispose<_PackagePickerSelection, Set<String>>(_PackagePickerSelection.new);

final class _PackagePickerSelection() extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void setAll(Iterable<String> ids) => state = ids.toSet();

  void clear() => state = {};

  void toggle(String id, bool selected) {
    state = selected ? {...state, id} : (Set<String>.from(state)..remove(id));
  }
}

final class _StorePackagePickerDialogState() extends ConsumerState<StorePackagePickerDialog> {
  late StoreRing ring;
  late StoreArch arch;
  Future<StorePackagesByProductId>? packagesFuture;
  List<PackageInfo> packages = const [];
  Object? loadError;
  bool loading = true;
  _PickerPhase phase = .selecting;
  String? downloadError;
  bool lastRunWasDownloadOnly = false;
  String? lastDownloadFolderPath;

  @override
  void initState() {
    super.initState();
    ring = widget.ring;
    arch = widget.arch;
    ref.listenManual(storeControllerProvider.select((s) => s.download), _onDownloadStateChanged);
    scheduleMicrotask(_reloadPackages);
  }

  void _onDownloadStateChanged(StoreDownloadState? previous, StoreDownloadState next) {
    if (phase != .running || !next.isTerminal || !mounted) return;
    final StoreController controller = ref.read(storeControllerProvider.notifier);
    final bool completedDownloadOnly = next.maybeWhen(
      completed: (_, _, installed) => !installed,
      orElse: () => false,
    );
    if (!lastRunWasDownloadOnly || !completedDownloadOnly) {
      setState(() => downloadError = next.errorMessage);
      return;
    }
    setState(() {
      phase = .selecting;
      downloadError = next.errorMessage;
      lastDownloadFolderPath = lastRunWasDownloadOnly && completedDownloadOnly
          ? controller.downloadFolderPath()
          : null;
    });
    controller.cancel();
  }

  Future<void> _reloadPackages() async {
    setState(() {
      loading = true;
      loadError = null;
      packages = const [];
    });
    ref.read(_packagePickerSelectionProvider.notifier).clear();
    final Future<StorePackagesByProductId> future = ref
        .read(storeServiceProvider)
        .getPackages(productIds: {widget.productId}, ring: ring, arch: arch)
        .then(
          (result) =>
              result.when(success: (value) => value, failure: (exception) => throw exception),
        );
    packagesFuture = future;
    await future
        .then((p) {
          if (!mounted || packagesFuture != future) return;

          packages = p.values.single.toList()
            ..sort((a, b) => a.progressName.compareTo(b.progressName));

          setState(() {
            loading = false;
          });
          ref.read(_packagePickerSelectionProvider.notifier).setAll(packages.map((p) => p.id));
        })
        .catchError((Object error) {
          if (!mounted || packagesFuture != future) return;
          setState(() {
            loadError = error;
            loading = false;
          });
        });
  }

  void _start({required bool install}) {
    final Set<String> selectedIds = ref.read(_packagePickerSelectionProvider);
    final Set<PackageInfo> selected = packages.where((p) => selectedIds.contains(p.id)).toSet();
    setState(() {
      phase = .running;
      downloadError = null;
      lastRunWasDownloadOnly = !install;
      lastDownloadFolderPath = null;
    });
    scheduleMicrotask(() {
      if (!mounted) return;
      ref
          .read(storeControllerProvider.notifier)
          .downloadPackages(
            productId: widget.productId,
            ring: ring,
            packages: selected,
            install: install,
          );
    });
  }

  void _close() {
    if (phase == .running && !ref.read(storeControllerProvider).download.isTerminal) {
      ref.read(storeControllerProvider.notifier).cancel();
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final running = phase == .running;
    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.widthOf(context) * .6,
        maxHeight: MediaQuery.heightOf(context) * .8,
      ),
      title: Text(t.msstoreChoosePackages),
      content: _PickerContent(
        ring: ring,
        arch: arch,
        loading: loading,
        loadError: loadError,
        downloadError: downloadError,
        packages: packages,
        running: running,
        onRingChanged: (r) => setState(() {
          ring = r;
          _reloadPackages();
        }),
        onArchChanged: (a) => setState(() {
          arch = a;
          _reloadPackages();
        }),
      ),
      actions: [
        _PickerCloseButton(running: running, onPressed: _close),
        _PickerDownloadButton(
          install: false,
          running: running,
          loading: loading,
          loadError: loadError,
          openInExplorerPath: lastDownloadFolderPath,
          onPressed: () => _start(install: false),
        ),
        _PickerDownloadButton(
          install: true,
          running: running,
          loading: loading,
          loadError: loadError,
          openInExplorerPath: null,
          onPressed: () => _start(install: true),
        ),
      ],
    );
  }
}

final class const _PickerContent({
    required final StoreRing ring,
    required final StoreArch arch,
    required final bool loading,
    required final Object? loadError,
    required final String? downloadError,
    required final List<PackageInfo> packages,
    required final bool running,
    required final ValueChanged<StoreRing> onRingChanged,
    required final ValueChanged<StoreArch> onArchChanged,
  }) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? liveError = running
        ? ref.watch(storeControllerProvider.select((s) => s.download.errorMessage))
        : null;
    final String? errorMessage = liveError ?? downloadError;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: ComboBox<StoreRing>(
                value: ring,
                isExpanded: true,
                items: StoreRing.values
                    .map((r) => ComboBoxItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: running
                    ? null
                    : (value) {
                        if (value != null) onRingChanged(value);
                      },
              ),
            ),
            Expanded(
              child: ComboBox<StoreArch>(
                value: arch,
                isExpanded: true,
                items: StoreArch.values
                    .map((a) => ComboBoxItem(value: a, child: Text(a.label)))
                    .toList(),
                onChanged: running
                    ? null
                    : (value) {
                        if (value != null) onArchChanged(value);
                      },
              ),
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          InfoBar(severity: .error, title: Text(t.msstoreError), content: Text(errorMessage)),
        ],
        const SizedBox(height: 12),
        Flexible(
          child: switch ((loading, loadError, packages.isEmpty)) {
            (true, _, _) => const Center(child: ProgressRing()),
            (false, final Object err?, _) => Text(err.toString()),
            (false, _, true) => Text(t.msstorePackagesNotFound),
            _ => ListView.builder(
              itemCount: packages.length,
              itemBuilder: (context, index) => _PackageListTile(
                key: ValueKey(packages[index].id),
                package: packages[index],
                packages: packages,
                running: running,
              ),
            ),
          },
        ),
      ],
    );
  }
}

final class const _PackageListTile({
    super.key,
    required final PackageInfo package,
    required final List<PackageInfo> packages,
    required final bool running,
  }) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool selected = ref.watch(
      _packagePickerSelectionProvider.select((s) => s.contains(package.id)),
    );
    final bool showProgress = running && selected;
    final double progress = showProgress
        ? ref.watch(
            storeControllerProvider.select(
              (s) => s.download.maybeWhen(
                completed: (_, _, _) => 1.0,
                downloading: (_, p, _, _, _, _) => p[package.progressName] ?? 0,
                paused: (_, p, _, _, _, _) => p[package.progressName] ?? 0,
                orElse: () => 0.0,
              ),
            ),
          )
        : 0.0;
    final ProcessResult? result = showProgress
        ? ref.watch(storeControllerProvider.select((s) => s.download.installResults?[package.id]))
        : null;

    final Widget subtitle = showProgress
        ? (result == null
              ? ProgressBar(value: progress * 100)
              : Text(t.msstoreExitCode(code: result.exitCode)))
        : Text(
            [
              if (package.isDependency) t.msstoreDependency else t.msstorePackage,
              package.fileModel?.fileType?.toUpperCase() ?? 'APPX',
              ...[
                package.fileModel?.size,
              ].whereType<int>().where((s) => s > 0).map((s) => s.formatBytes()),
            ].join(' · '),
          );

    final StatelessWidget trailing = showProgress
        ? (result == null
              ? Text('${(progress * 100).toStringAsFixed(0)}%')
              : Icon(
                  result.exitCode == 0 ? FluentIcons.completed : FluentIcons.error,
                  color: result.exitCode == 0 ? Colors.green : Colors.red,
                ))
        : Text(package.arch);

    return RepaintBoundary(
      child: ListTile.selectable(
        selectionMode: .multiple,
        selected: selected,
        title: Text(package.progressName, maxLines: 1, overflow: .ellipsis),
        subtitle: subtitle,
        trailing: trailing,
        onSelectionChange: running
            ? null
            : (value) =>
                  ref.read(_packagePickerSelectionProvider.notifier).toggle(package.id, value),
      ),
    );
  }
}

final class const _PickerCloseButton({required final bool running, required final VoidCallback onPressed}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool activeRunning =
        running && !ref.watch(storeControllerProvider.select((s) => s.download.isTerminal));
    return Button(onPressed: onPressed, child: Text(activeRunning ? t.msstoreCancel : t.close));
  }
}

final class const _PickerDownloadButton({
    required final bool install,
    required final bool running,
    required final bool loading,
    required final Object? loadError,
    required final String? openInExplorerPath,
    required final VoidCallback onPressed,
  }) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canOpenExplorer = !install && !running && openInExplorerPath != null;
    if (canOpenExplorer) {
      return Button(
        onPressed: () async => Process.run('explorer.exe', [openInExplorerPath!], runInShell: true),
        child: Text(t.msstoreOpenInExplorer),
      );
    }

    final bool hasSelection = ref.watch(
      _packagePickerSelectionProvider.select((s) => s.isNotEmpty),
    );
    final bool enabled = !running && hasSelection && !loading && loadError == null;
    final child = Text(install ? t.msstoreDownloadAndInstall : t.msstoreDownloadOnly);
    if (install) {
      return FilledButton(onPressed: enabled ? onPressed : null, child: child);
    }
    return Button(onPressed: enabled ? onPressed : null, child: child);
  }
}
