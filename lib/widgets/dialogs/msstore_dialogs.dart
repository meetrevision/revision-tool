import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/shell.dart';

import '../../l10n/generated/localizations.dart';

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
            Text(ReviLocalizations.of(context).msstoreWait),
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
      title: Text(ReviLocalizations.of(context).installing),
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
          child: Text(ReviLocalizations.of(context).close),
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
        content: Text(ReviLocalizations.of(context).msstorePackagesNotFound),
        actions: [
          FilledButton(
            child: Text(ReviLocalizations.of(context).close),
            onPressed: () => Navigator.pop(context, 'Not found'),
          ),
        ],
      );
    },
  );
}
