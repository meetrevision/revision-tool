import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'card_highlight.dart';

class CardButtonWidget extends StatelessWidget {
  const CardButtonWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    // required this.trailingIcon,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  // final IconData trailingIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // height: 85,
    // width: 324,
    return Card(
      borderRadius: BorderRadius.circular(5),
      padding: const EdgeInsets.all(0.0),
      child: IconButton(
        style: ButtonStyle(
          padding: ButtonState.all(const EdgeInsets.only(
            left: 4.0,
            right: 4.0,
            top: 5.0,
            bottom: 0.0,
          )),
          shape: ButtonState.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          )),
        ),
        onPressed: onPressed,
        icon: CardHighlight(
          icon: icon,
          label: title,
          description: subtitle,
          borderColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          child: const Icon(
            msicons.FluentIcons.chevron_right_20_regular,
            size: 20,
          ),
        ),
      ),
    );
  }
}
