import 'package:fluent_ui/fluent_ui.dart';
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
    this.codeSnippet,
    this.backgroundColor,
    this.borderColor,
    this.image,
    required this.action,
  }) : assert(
         icon == null || image == null,
         'Cannot provide both icon and image',
       );

  final IconData? icon;
  final String label;
  final String? description;
  final String? codeSnippet;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? image;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    // Use label hash for stable PageStorageKey to prevent unnecessary rebuilds
    final pageStorageKey = label.hashCode;

    return Column(
      key: PageStorageKey(pageStorageKey),
      children: [
        Card(
          backgroundColor: backgroundColor,
          borderRadius: _cardBorderRadius,
          borderColor: borderColor,
          child: SizedBox(
            width: double.infinity,
            child: Align(
              heightFactor: 1.18,
              alignment: AlignmentDirectional.center,
              child: Row(
                children: [
                  if (image != null) ...[
                    const SizedBox(width: 5.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        image!,
                        width: _imgXY,
                        height: _imgXY,
                        cacheHeight:
                            (_imgXY * MediaQuery.devicePixelRatioOf(context))
                                .toInt(),
                        cacheWidth:
                            (_imgXY * MediaQuery.devicePixelRatioOf(context))
                                .toInt(),
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 15.0),
                  ] else if (icon != null) ...[
                    const SizedBox(width: 5.0),
                    Icon(icon, size: 24),
                    const SizedBox(width: 15.0),
                  ],
                  Expanded(
                    child: InfoLabel(
                      label: label,
                      labelStyle: const TextStyle(
                        overflow: TextOverflow.ellipsis,
                      ),
                      child: description != null
                          ? Text(
                              description!,
                              style: context.theme.brightness.isDark
                                  ? _cardDescStyleForDark
                                  : _cardDescStyleForLight,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 10.0),

                  RepaintBoundary(child: action),
                ],
              ),
            ),
          ),
        ),
        if (codeSnippet != null) ...[
          _CardHighlightCodeSnippet(
            pageStorageKey: pageStorageKey,
            codeSnippet: codeSnippet!,
          ),
        ],
        const SizedBox(height: 5.0),
      ],
    );
  }
}

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

class _CardHighlightCodeSnippet extends StatelessWidget {
  const _CardHighlightCodeSnippet({
    required this.pageStorageKey,
    required this.codeSnippet,
  });

  final int pageStorageKey;
  final String codeSnippet;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.transparent,
          child: Expander(
            key: PageStorageKey(pageStorageKey),
            headerShape: (open) => const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
            onStateChanged: (state) {
              setState(() {});
            },
            header: Text(context.l10n.moreInformation),
            content: Text(codeSnippet),
          ),
        );
      },
    );
  }
}
