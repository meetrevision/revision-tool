import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

// final buttonColors = WindowButtonColors(
//   iconNormal: const Color(0xFF805306),
//   mouseOver: const Color(0xFFF6A00C),
//   mouseDown: const Color(0xFF805306),
//   iconMouseOver: const Color(0xFF805306),
//   iconMouseDown: const Color(0xFFFFD500),
// );

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: FluentTheme.of(context).brightness.isDark ? const Color(0xFFFFFFFF) : Colors.black,
      mouseOver: const Color(0xFF404040),
      mouseDown: const Color(0xFF202020),
      iconMouseOver: const Color(0xFFFFFFFF),
      iconMouseDown: const Color(0xA7A7A7A7),
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: FluentTheme.of(context).brightness.isDark ? const Color(0xFFFFFFFF) : Colors.black,
      iconMouseOver: Colors.white,
      iconMouseDown: const Color(0xA7A7A7A7),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: MinimizeWindowButton(colors: buttonColors),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: MaximizeWindowButton(colors: buttonColors),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: CloseWindowButton(colors: closeButtonColors),
        ),
      ],
    );
  }
}
