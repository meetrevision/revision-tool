import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_plus/window_plus.dart';

class const UnsupportedWidget({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: ContentDialog(
        title: const Text('Error'),
        content: const Text('Unsupported build detected'),
        actions: [
          Button(child: const Text('OK'), onPressed: () async => WindowPlus.instance.close()),
        ],
      ),
    );
  }
}
