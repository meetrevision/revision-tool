import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/extensions.dart';

class Subtitle extends StatelessWidget {
  const Subtitle({super.key, required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(top: 14.0, bottom: 2.0),
        child: DefaultTextStyle(
          style: context.theme.typography.subtitle!,
          child: content,
        ),
      );
    });
  }
}
