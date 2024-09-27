import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/shell.dart';
import 'package:revitool/extensions.dart';

Future<Object?> showLoadingDialog(BuildContext context, String title) {
  return showDialog(
    context: context,
    dismissWithEsc: false,
    builder: (context) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
      title: Text(title),
      content: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProgressRing(),
            const SizedBox(height: 10),
            Text(context.l10n.msstoreWait),
          ],
        ),
      ),
    ),
  );
}

Future<Object?> showInstallProcess(
    BuildContext context, List<ProcessResult> processResult) {
  return showDialog(
    context: context,
    dismissWithEsc: false,
    builder: (context) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
      title: Text(context.l10n.installing),
      content: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final item in processResult) ...[
                Text(processResultToDebugString(item))
              ]
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          child: Text(context.l10n.close),
          onPressed: () => Navigator.pop(context, 'Install process'),
        ),
      ],
    ),
  );
}

Future<Object?> showNotFound(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return ContentDialog(
        constraints: const BoxConstraints(maxWidth: 600),
        content: Text(context.l10n.msstorePackagesNotFound),
        actions: [
          FilledButton(
            child: Text(context.l10n.close),
            onPressed: () => Navigator.pop(context, 'Not found'),
          ),
        ],
      );
    },
  );
}
