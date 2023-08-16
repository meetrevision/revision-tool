// ignore_for_file: prefer_final_fields, unused_field

import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';

const cardBorderColorForDark = Color.fromARGB(255, 29, 29, 29);
const cardBorderColorForLight = Color.fromARGB(255, 229, 229, 229);
const cardBorderRadius = BorderRadius.all(Radius.circular(5.0));
const cardDescStyleForDark = TextStyle(
    fontSize: 11,
    color: Color.fromARGB(255, 200, 200, 200),
    overflow: TextOverflow.fade);

const cardDescStyleForLight = TextStyle(
    fontSize: 11,
    color: Color.fromARGB(255, 117, 117, 117),
    overflow: TextOverflow.fade);

class CardHighlightSwitch extends StatefulWidget {
  const CardHighlightSwitch(
      {Key? key,
      this.codeSnippet,
      this.icon,
      this.label,
      this.description,
      this.switchBool,
      required this.function,
      this.requiresRestart})
      : super(key: key);
  final String? codeSnippet;

  final IconData? icon;
  final String? label;
  final String? description;
  final bool? switchBool;
  final ValueChanged function;
  final bool? requiresRestart;

  @override
  State<CardHighlightSwitch> createState() => _CardHighlightSwitchState();
}

class _CardHighlightSwitchState extends State<CardHighlightSwitch>
    with AutomaticKeepAliveClientMixin<CardHighlightSwitch> {
  static bool _isOpen = false;
  static bool _isCopying = false;

  final _key = Random().nextInt(1000);

  @override
  Widget build(BuildContext context) {
    // final theme = FluentTheme.of(context);
    super.build(context);
    return Column(
      children: [
        Card(
          borderColor: FluentTheme.of(context).brightness.isDark
              ? cardBorderColorForDark
              : cardBorderColorForLight,
          borderRadius: cardBorderRadius,
          child: SizedBox(
            // height: 44,
            width: double.infinity,
            child: Align(
              heightFactor: 1.18,
              alignment: AlignmentDirectional.center,
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    const SizedBox(width: 5.0),
                    Icon(widget.icon, size: 24),
                    const SizedBox(width: 15.0),
                  ],
                  Expanded(
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoLabel(label: widget.label!),
                          if (widget.description != null) ...[
                            Text(
                              widget.description!,
                              style: FluentTheme.of(context).brightness.isDark
                                  ? cardDescStyleForDark
                                  : cardDescStyleForLight,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  Text(widget.switchBool!
                      ? ReviLocalizations.of(context).onStatus
                      : ReviLocalizations.of(context).offStatus),
                  const SizedBox(width: 10.0),
                  ToggleSwitch(
                    checked: widget.switchBool!,
                    onChanged: (value) {
                      widget.function(value);
                      if (widget.requiresRestart != null) {
                        showDialog(
                          context: context,
                          builder: (context) => ContentDialog(
                            content: Text(
                                ReviLocalizations.of(context).restartDialog),
                            actions: [
                              Button(
                                child: Text(
                                    ReviLocalizations.of(context).okButton),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          ),
                        );
                      }
                    },
                  ),

                  // if (widget.requiresRestart != null) {
                  //       showDialog(
                  //         context: context,
                  //         builder: (context) => ContentDialog(
                  //           content: Text(
                  //               ReviLocalizations.of(context).restartDialog),
                  //           actions: [
                  //             Button(
                  //               child: Text(
                  //                   ReviLocalizations.of(context).okButton),
                  //               onPressed: () {
                  //                 Navigator.pop(context);
                  //               },
                  //             )
                  //           ],
                  //         ),
                  //       );
                  //     }
                ],
              ),
            ),
          ),
        ),
        if (widget.codeSnippet != null) ...[
          Card(
            padding: const EdgeInsets.all(0),
            borderColor: FluentTheme.of(context).brightness.isDark
                ? const Color.fromARGB(255, 29, 29, 29)
                : const Color.fromARGB(255, 229, 229, 229),
            backgroundColor: Colors.transparent,
            child: Expander(
              key: PageStorageKey(_key),
              headerShape: (open) => const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4.0))),
              onStateChanged: (state) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  if (mounted) setState(() => _isOpen = state);
                });
              },
              header: Text(ReviLocalizations.of(context).moreInformation),
              content: Text(widget.codeSnippet!),
            ),
          ),
        ],
        const SizedBox(height: 5.0),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

const fluentHighlightTheme = {
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

class CardHighlight extends StatefulWidget {
  const CardHighlight(
      {Key? key,
      this.backgroundColor,
      required this.child,
      this.codeSnippet,
      this.icon,
      this.label,
      this.description})
      : super(key: key);

  final Widget child;
  final String? codeSnippet;
  final Color? backgroundColor;
  final IconData? icon;
  final String? label;
  final String? description;

  @override
  State<CardHighlight> createState() => _CardHighlightState();
}

class _CardHighlightState extends State<CardHighlight>
    with AutomaticKeepAliveClientMixin<CardHighlight> {
  static bool _isOpen = false;
  static bool _isCopying = false;

  final _key = Random().nextInt(1000);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Card(
        borderColor: FluentTheme.of(context).brightness.isDark
            ? cardBorderColorForDark
            : cardBorderColorForLight,
        borderRadius: cardBorderRadius,
        child: SizedBox(
          // height: 44,
          width: double.infinity,
          child: Align(
            heightFactor: 1.18,
            alignment: AlignmentDirectional.center,
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  const SizedBox(width: 5.0),
                  Icon(widget.icon, size: 24),
                  const SizedBox(width: 15.0),
                ],
                Expanded(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoLabel(label: widget.label!),
                        if (widget.description != null) ...[
                          Text(
                            widget.description ?? "",
                            style: FluentTheme.of(context).brightness.isDark
                                ? cardDescStyleForDark
                                : cardDescStyleForLight,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                widget.child,
              ],
            ),
          ),
        ),
      ),
      if (widget.codeSnippet != null) ...[
        Card(
          padding: const EdgeInsets.all(0),
          borderColor: FluentTheme.of(context).brightness.isDark
              ? cardBorderColorForDark
              : cardBorderColorForLight,
          backgroundColor: Colors.transparent,
          child: Expander(
            key: PageStorageKey(_key),
            headerShape: (open) =>
                const RoundedRectangleBorder(borderRadius: cardBorderRadius),
            onStateChanged: (state) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                if (mounted) setState(() => _isOpen = state);
              });
            },
            header: Text(ReviLocalizations.of(context).moreInformation),
            content: Text(widget.codeSnippet!),
          ),
        ),
      ],
      const SizedBox(height: 5.0),
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
