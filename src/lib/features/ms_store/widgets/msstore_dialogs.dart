import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/shell.dart';
import 'package:revitool/i18n/generated/strings.g.dart';

Future<Object?> showLoadingDialog(BuildContext context, String title) {
  return showDialog(
    context: context,
    dismissWithEsc: false,
    builder: (context) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
      title: Text(title),
      content: Center(
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .center,
          children: [
            const ProgressRing(),
            const SizedBox(height: 10),
            Text(t.msstoreWait),
          ],
        ),
      ),
    ),
  );
}

Future<Object?> showInstallProcess(
  BuildContext context,
  List<ProcessResult> processResult,
) {
  return showDialog(
    context: context,
    dismissWithEsc: false,
    builder: (context) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
      title: Text(t.installing),
      content: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .center,
            mainAxisAlignment: .center,
            children: [
              for (final item in processResult) ...[
                Text(processResultToDebugString(item)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          child: Text(t.close),
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
        content: Text(t.msstorePackagesNotFound),
        actions: [
          FilledButton(
            child: Text(t.close),
            onPressed: () => Navigator.pop(context, 'Not found'),
          ),
        ],
      );
    },
  );
}
