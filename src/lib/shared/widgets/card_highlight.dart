import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/gestures.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/extensions.dart';

// const cardBorderColorForDark = Color.fromARGB(255, 29, 29, 29);
// const cardBorderColorForLight = Color.fromARGB(255, 229, 229, 229);
const _cardBorderRadius = BorderRadius.all(Radius.circular(5.0));
const _cardDescStyleForDark = TextStyle(
  fontSize: 11,
  color: Color.fromARGB(255, 200, 200, 200),
  overflow: TextOverflow.fade,
);

const _cardDescStyleForLight = TextStyle(
  fontSize: 11,
  color: Color.fromARGB(255, 117, 117, 117),
  overflow: TextOverflow.fade,
);

const _imgXY = 48.0;

class CardHighlight extends StatelessWidget {
  const CardHighlight({
    super.key,
    this.icon,
    required this.label,
    this.description,
    this.descriptionLink,
    this.image,
    required this.action,
    this.children,
    this.onPressed,
  }) : assert(
         icon == null || image == null,
         'Cannot provide both icon and image',
       );

  final IconData? icon;
  final String label;

  final String? description;
  final String? descriptionLink;

  final String? image;
  final Widget action;
  final List<Widget>? children;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Use label hash for stable PageStorageKey to prevent unnecessary rebuilds
    final pageStorageKey = label.hashCode;

    final expanderWidget = Expander(
      key: PageStorageKey(pageStorageKey),

      enabled: children != null,
      icon: children != null
          ? null
          : RepaintBoundary(
              child: action,
            ), // action replaces chevron if no children
      trailing: children != null
          ? RepaintBoundary(child: action)
          : null, // when there are children, action goes to trailing and chevron shows up

      leading: image != null
          ? ClipRRect(
              borderRadius: _cardBorderRadius,
              child: Image.network(
                image!,
                width: _imgXY,
                height: _imgXY,
                cacheHeight: (_imgXY * MediaQuery.devicePixelRatioOf(context))
                    .toInt(),
                cacheWidth: (_imgXY * MediaQuery.devicePixelRatioOf(context))
                    .toInt(),
                filterQuality: FilterQuality.high,
              ),
            )
          : Icon(icon, size: 24),
      headerShape: (open) => RoundedRectangleBorder(
        borderRadius: open
            ? const BorderRadius.only(
                topLeft: Radius.circular(5.0),
                topRight: Radius.circular(5.0),
              )
            : _cardBorderRadius,
        side: BorderSide(color: context.theme.resources.cardStrokeColorDefault),
      ),
      headerBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isHovered) {
          return context.theme.resources.cardBackgroundFillColorSecondary;
        }
        return context.theme.cardColor;
      }),
      contentShape: (open) => RoundedRectangleBorder(
        borderRadius: open
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(5.0),
                bottomRight: Radius.circular(5.0),
              )
            : _cardBorderRadius,
        side: BorderSide(
          color: context.theme.resources.cardStrokeColorDefault,
          width: 0.5,
        ),
      ),
      contentBackgroundColor: context.theme.cardColor,
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.2), //102px
        child: InfoLabel(
          label: label,
          labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
          child: description != null
              ? RichText(
                  text: TextSpan(
                    text: description!,
                    style: context.theme.brightness.isDark
                        ? _cardDescStyleForDark
                        : _cardDescStyleForLight,
                    children: descriptionLink != null
                        ? [
                            const TextSpan(text: ' '),

                            TextSpan(
                              text: 'More about ${label.toLowerCase()}',
                              style: TextStyle(
                                color: context.theme.accentColor.lightest,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  await run(
                                    "rundll32 url.dll,FileProtocolHandler $descriptionLink",
                                  );
                                },
                            ),
                          ]
                        : [],
                  ),
                )
              : const SizedBox(),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 9),
      content: children != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children!,
            )
          : const SizedBox.shrink(),
    );

    // Only wrap in HoverButton when non-expandable
    if (children == null && action is ChevronRightAction) {
      return HoverButton(
        key: PageStorageKey(pageStorageKey),
        onPressed: onPressed,
        hitTestBehavior: HitTestBehavior.deferToChild,
        builder: (_, states) => FocusBorder(
          focused: states.isFocused,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: states.isHovered
                  ? context.theme.resources.cardBackgroundFillColorSecondary
                  : null,
              borderRadius: _cardBorderRadius,
            ),
            child: IgnorePointer(
              child: expanderWidget,
            ), // disabled Expander inside is absorbing pointer events, preventing the HoverButton's onPressed execution. IgnorePointer fixes this.
          ),
        ),
      );
    }

    return expanderWidget;
  }
}

/// A toggle switch widget used in [CardHighlight] for actions.
class CardToggleSwitch extends StatelessWidget {
  const CardToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.requiresRestart = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool requiresRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value ? context.l10n.onStatus : context.l10n.offStatus),
        const SizedBox(width: 10.0),
        ToggleSwitch(
          checked: value,
          onChanged: (newValue) async {
            onChanged(newValue);
            if (requiresRestart) {
              showRestartDialog(context);
            }
          },
        ),
      ],
    );
  }
}

class ChevronRightAction extends StatelessWidget {
  const ChevronRightAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(msicons.FluentIcons.chevron_right_20_regular);
  }
}

/// A status text widget that shows on/off status.
///
/// Useful when you want to show status but without an interactive switch.
class CardStatusText extends StatelessWidget {
  const CardStatusText({super.key, required this.value});

  /// Status value to display
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Text(value ? context.l10n.onStatus : context.l10n.offStatus);
  }
}

/// Shows a restart dialog to inform the user that a restart is required.
void showRestartDialog(
  final BuildContext context, {
  String title = "",
  String content = "",
}) {
  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: title.isEmpty ? null : Text(title),
      content: Text(content.isEmpty ? context.l10n.restartDialog : content),
      actions: [
        Button(
          child: Text(context.l10n.okButton),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

// ignore: unused_element
const _fluentHighlightTheme = {
  'root': TextStyle(
    backgroundColor: Color(0x00ffffff),
    color: Color(0xffdddddd),
  ),
  'keyword': TextStyle(
    color: Color.fromARGB(255, 255, 255, 255),
    fontWeight: FontWeight.bold,
  ),
  'selector-tag': TextStyle(
    color: Color(0xffffffff),
    fontWeight: FontWeight.bold,
  ),
  'literal': TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold),
  'section': TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold),
  'link': TextStyle(color: Color(0xffffffff)),
  'subst': TextStyle(color: Color(0xffdddddd)),
  'string': TextStyle(color: Color(0xffdd8888)),
  'title': TextStyle(color: Color(0xffdd8888), fontWeight: FontWeight.bold),
  'name': TextStyle(color: Color(0xffdd8888), fontWeight: FontWeight.bold),
  'type': TextStyle(color: Color(0xffdd8888), fontWeight: FontWeight.bold),
  'attribute': TextStyle(color: Color(0xffdd8888)),
  'symbol': TextStyle(color: Color(0xffdd8888)),
  'bullet': TextStyle(color: Color(0xffdd8888)),
  'built_in': TextStyle(color: Color(0xffdd8888)),
  'addition': TextStyle(color: Color(0xffdd8888)),
  'variable': TextStyle(color: Color(0xffdd8888)),
  'template-tag': TextStyle(color: Color(0xffdd8888)),
  'template-variable': TextStyle(color: Color(0xffdd8888)),
  'comment': TextStyle(color: Color(0xff777777)),
  'quote': TextStyle(color: Color(0xff777777)),
  'deletion': TextStyle(color: Color(0xff777777)),
  'meta': TextStyle(color: Color(0xff777777)),
  'doctag': TextStyle(fontWeight: FontWeight.bold),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
};
