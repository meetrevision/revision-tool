import 'package:fluent_ui/fluent_ui.dart';

import '../../../i18n/generated/strings.g.dart';

Future<Object?> showLoadingDialog(BuildContext context, String title) {
  return showDialog(
    context: context,
    dismissWithEsc: false,
    builder: (context) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
      title: Text(title),
      content: Center(
        child: Column(
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
