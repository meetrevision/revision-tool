import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/extensions.dart';

// const cardBorderColorForDark = Color.fromARGB(255, 29, 29, 29);
// const cardBorderColorForLight = Color.fromARGB(255, 229, 229, 229);
const _cardBorderRadius = BorderRadius.all(Radius.circular(5.0));
const _cardDescStyleForDark = TextStyle(
    fontSize: 11,
    color: Color.fromARGB(255, 200, 200, 200),
    overflow: TextOverflow.fade);

const _cardDescStyleForLight = TextStyle(
    fontSize: 11,
    color: Color.fromARGB(255, 117, 117, 117),
    overflow: TextOverflow.fade);

class CardHighlightSwitch extends StatelessWidget {
  const CardHighlightSwitch({
    super.key,
    this.icon,
    required this.label,
    this.description,
    required this.switchBool,
    required this.function,
    this.requiresRestart,
    this.codeSnippet,
  });

  final IconData? icon;
  final String label;
  final String? description;
  final ValueNotifier<bool> switchBool;
  final ValueChanged function;
  final bool? requiresRestart;
  final String? codeSnippet;

  static final _key = Random().nextInt(1000);
  @override
  Widget build(BuildContext context) {
    return Column(
      key: PageStorageKey(_key),
      children: [
        Card(
          borderRadius: _cardBorderRadius,
          child: SizedBox(
            // height: 44,
            width: double.infinity,
            child: Align(
              heightFactor: 1.18,
              alignment: AlignmentDirectional.center,
              child: Row(
                children: [
                  if (icon != null) ...[
                    const SizedBox(width: 5.0),
                    Icon(icon, size: 24),
                    const SizedBox(width: 15.0),
                  ],
                  Expanded(
                    child: SizedBox(
                      child: InfoLabel(
                        label: label,
                        labelStyle:
                            const TextStyle(overflow: TextOverflow.ellipsis),
                        child: description != null
                            ? Text(
                                description ?? "",
                                style: context.theme.brightness.isDark
                                    ? _cardDescStyleForDark
                                    : _cardDescStyleForLight,
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  ValueListenableBuilder<bool>(
                      valueListenable: switchBool,
                      builder: (context, value, child) {
                        return Text(value
                            ? context.l10n.onStatus
                            : context.l10n.offStatus);
                      }),
                  const SizedBox(width: 10.0),
                  ValueListenableBuilder<bool>(
                    valueListenable: switchBool,
                    builder: (context, builderValue, child) {
                      return ToggleSwitch(
                        checked: builderValue,
                        onChanged: (value) async {
                          function(value);
                          if (requiresRestart != null) {
                            showDialog(
                              context: context,
                              builder: (context) => ContentDialog(
                                content: Text(context.l10n.restartDialog),
                                actions: [
                                  Button(
                                    child: Text(context.l10n.okButton),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  )
                                ],
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (codeSnippet != null) ...[
          _CardHighlightCodeSnippet(
              pageStorageKey: _key, codeSnippet: codeSnippet!),
        ],
        const SizedBox(height: 5.0),
      ],
    );
  }
}

const _fluentHighlightTheme = {
  'root': TextStyle(
    backgroundColor: Color(0x00ffffff),
    color: Color(0xffdddddd),
  ),
  'keyword': TextStyle(
      color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold),
  'selector-tag':
      TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold),
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

class CardHighlight extends StatelessWidget {
  const CardHighlight(
      {super.key,
      required this.child,
      this.codeSnippet,
      this.backgroundColor,
      this.icon,
      this.label,
      this.description,
      this.image,
      this.borderColor});
  final Widget child;
  final String? codeSnippet;
  final Color? backgroundColor;
  final IconData? icon;
  final String? label;
  final String? description;
  final String? image;
  final Color? borderColor;

  static final _key = Random().nextInt(1000);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          backgroundColor: backgroundColor,
          borderRadius: _cardBorderRadius,
          borderColor: borderColor,
          child: SizedBox(
            // height: 44,
            width: double.infinity,
            child: Align(
              heightFactor: 1.18,
              alignment: AlignmentDirectional.center,
              child: Row(
                children: [
                  if (icon != null) ...[
                    const SizedBox(width: 5.0),
                    Icon(icon, size: 24),
                    const SizedBox(width: 15.0),
                  ],
                  if (image != null) ...[
                    const SizedBox(width: 5.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        image!,
                        width: 48,
                        height: 48,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 15.0),
                  ],
                  Expanded(
                    child: InfoLabel(
                      label: label!,
                      labelStyle: const TextStyle(overflow: TextOverflow.clip),
                      child: description != null
                          ? Text(description ?? "",
                              style: context.theme.brightness.isDark
                                  ? _cardDescStyleForDark
                                  : _cardDescStyleForLight,
                              overflow: TextOverflow.clip)
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  child,
                ],
              ),
            ),
          ),
        ),
        if (codeSnippet != null) ...[
          _CardHighlightCodeSnippet(
              pageStorageKey: _key, codeSnippet: codeSnippet!)
        ],
        const SizedBox(height: 5.0),
      ],
    );
  }
}

class _CardHighlightCodeSnippet extends StatelessWidget {
  const _CardHighlightCodeSnippet({
    required this.pageStorageKey,
    required this.codeSnippet,
  });

  final int pageStorageKey;
  final String codeSnippet;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return Card(
        padding: const EdgeInsets.all(0),
        backgroundColor: Colors.transparent,
        child: Expander(
          key: PageStorageKey(pageStorageKey),
          headerShape: (open) => const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4.0))),
          onStateChanged: (state) {
            setState(() {});
          },
          header: Text(context.l10n.moreInformation),
          content: Text(codeSnippet),
        ),
      );
    });
  }
}
