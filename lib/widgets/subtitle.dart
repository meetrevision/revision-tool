import 'package:fluent_ui/fluent_ui.dart';

Widget subtitle({required Widget content}) {
  return Builder(builder: (context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 2.0),
      child: DefaultTextStyle(
        style: FluentTheme.of(context).typography.subtitle!,
        child: content,
      ),
    );
  });
}
