import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../extensions.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';
import '../settings/app_settings_provider.dart';

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
    this.action,
    this.children,
    this.onPressed,
    this.initiallyExpanded = false,
  }) : assert(
         icon == null || image == null,
         'Cannot provide both icon and image',
       );

  final IconData? icon;
  final String label;

  final String? description;
  final String? descriptionLink;

  final String? image;
  final Widget? action;
  final List<Widget>? children;

  final VoidCallback? onPressed;

  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    // Use label hash for stable PageStorageKey to prevent unnecessary rebuilds
    final pageStorageKey = label.hashCode;

    // Build the leading widget (icon or image)
    final Widget leadingWidget = image != null
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
        : Icon(icon, size: 24);

    // If it's a clickable card (no children, has ChevronRightAction), build custom HoverButton
    if (children == null && action is ChevronRightAction) {
      return _ClickableCardChevron(
        pageStorageKey: pageStorageKey,
        onPressed: onPressed,
        leadingWidget: leadingWidget,
        label: label,
        description: description,
        descriptionLink: descriptionLink,
        action: action,
      );
    }

    // Otherwise, use Expander for expandable cards
    return _ExpandableCard(
      pageStorageKey: pageStorageKey,
      initiallyExpanded: initiallyExpanded,
      leadingWidget: leadingWidget,
      label: label,
      description: description,
      descriptionLink: descriptionLink,
      action: action,
      children: children,
    );
  }
}

class _ExpandableCard extends ConsumerStatefulWidget {
  const _ExpandableCard({
    required this.pageStorageKey,
    required this.initiallyExpanded,
    required this.leadingWidget,
    required this.label,
    required this.description,
    required this.descriptionLink,
    required this.action,
    required this.children,
  });

  final int pageStorageKey;
  final bool initiallyExpanded;
  final Widget leadingWidget;
  final String label;
  final String? description;
  final String? descriptionLink;
  final Widget? action;
  final List<Widget>? children;

  @override
  ConsumerState<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends ConsumerState<_ExpandableCard> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;
    final ResourceDictionary resources = theme.resources;
    final isLight = theme.brightness == .light;
    final Color defaultBorderColor = resources.cardStrokeColorDefault;
    final Color hoverBottomBorderColor = isLight
        ? ref
              .read(appSettingsProvider.notifier)
              .cardLightHoverBottomBorderColor()!
        : defaultBorderColor;

    return MouseRegion(
      key: PageStorageKey(widget.pageStorageKey),
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: _cardBorderRadius,
              border: .all(
                color: isLight
                    ? defaultBorderColor
                    : widget.children != null && _isHovered && !_isExpanded
                    ? resources.cardBackgroundFillColorSecondary
                    : defaultBorderColor,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: isLight ? const .all(1.5) : .zero,
              child: Expander(
                initiallyExpanded: widget.initiallyExpanded,
                enabled: widget.children != null,
                icon: widget.children != null
                    ? null
                    : RepaintBoundary(child: widget.action),
                trailing: widget.children != null
                    ? RepaintBoundary(child: widget.action)
                    : null,
                leading: widget.leadingWidget,
                headerShape: (open) => RoundedRectangleBorder(
                  borderRadius: open
                      ? const .only(
                          topLeft: Radius.circular(5.0),
                          topRight: Radius.circular(5.0),
                        )
                      : _cardBorderRadius,
                ),
                headerBackgroundColor: .resolveWith((states) {
                  if (states.isHovered) {
                    return resources.cardBackgroundFillColorSecondary;
                  }
                  return Colors.transparent;
                }),
                onStateChanged: (expanded) {
                  setState(() => _isExpanded = expanded);
                },
                contentShape: (open) => RoundedRectangleBorder(
                  borderRadius: open
                      ? const .only(
                          bottomLeft: .circular(5.0),
                          bottomRight: .circular(5.0),
                        )
                      : _cardBorderRadius,
                ),
                contentBackgroundColor: Colors.transparent,
                header: CardListTile(
                  title: widget.label,
                  description: widget.description,
                  descriptionLink: widget.descriptionLink,
                  contentPadding: .symmetric(
                    horizontal: 6.5,
                    vertical: widget.description != null ? 16.75 : 24.25,
                  ),
                ),
                contentPadding: .zero,
                content: widget.children != null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: hoverBottomBorderColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: .start,
                          mainAxisSize: .min,
                          children: [
                            for (
                              int index = 0;
                              index < widget.children!.length;
                              index++
                            )
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: index == widget.children!.length - 1
                                        ? .none
                                        : BorderSide(
                                            color: defaultBorderColor,
                                            width: 2,
                                          ),
                                  ),
                                ),
                                child: widget.children![index],
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          if (widget.children != null && isLight && _isHovered && !_isExpanded)
            Positioned(
              left: 3,
              right: 3,
              bottom: 0,
              child: Divider(
                style: DividerThemeData(
                  horizontalMargin: .zero,
                  decoration: BoxDecoration(
                    color: hoverBottomBorderColor,
                    borderRadius: _cardBorderRadius,
                  ),
                  thickness: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClickableCardChevron extends StatelessWidget {
  const _ClickableCardChevron({
    required this.pageStorageKey,
    required this.onPressed,
    required this.leadingWidget,
    required this.label,
    required this.description,
    required this.descriptionLink,
    required this.action,
  });

  final int pageStorageKey;
  final VoidCallback? onPressed;
  final Widget leadingWidget;
  final String label;
  final String? description;
  final String? descriptionLink;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;
    final ResourceDictionary resources = theme.resources;
    return HoverButton(
      key: PageStorageKey(pageStorageKey),
      onPressed: onPressed,
      builder: (_, states) => FocusBorder(
        focused: states.isFocused,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _cardBorderRadius,
            color: theme.cardColor,
            border: .all(color: resources.cardStrokeColorDefault, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: _cardBorderRadius,
            child: Padding(
              // Inset the hover fill so it does not paint over the stroke.
              padding: const .all(1.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: states.isHovered
                      ? resources.cardBackgroundFillColorSecondary
                      : Colors.transparent,
                ),
                child: CardListTile(
                  leading: leadingWidget,
                  title: label,
                  description: description,
                  descriptionLink: descriptionLink,
                  trailing: action != null
                      ? RepaintBoundary(child: action)
                      : null,
                  extraTrailingPadding: false,
                  contentPadding: const .only(
                    left: 17.0,
                    top: 16.75,
                    bottom: 16.75,
                    right: 17.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A list tile widget used in [CardHighlight] for children.
class CardListTile extends StatelessWidget {
  const CardListTile({
    super.key,
    this.leading,
    required this.title,
    this.description,
    this.descriptionLink,
    this.trailing,
    this.contentPadding = const .symmetric(horizontal: 17.0, vertical: 9.0),
    this.extraTrailingPadding = true,
  });

  final Widget? leading;
  final String title;
  final String? description;
  final String? descriptionLink;
  final Widget? trailing;
  final EdgeInsetsGeometry contentPadding;

  /// Whether to add extra 28px padding on the right when trailing is present.
  /// Set to false for standalone cards, true for Expander children.
  final bool extraTrailingPadding;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;
    final isLight = theme.brightness == .light;
    final content = Column(
      crossAxisAlignment: .start,
      children: [
        Text.rich(TextSpan(text: title), style: theme.typography.body),
        if (description != null || descriptionLink != null) ...[
          RichText(
            text: TextSpan(
              text: description,
              style: isLight ? _cardDescStyleForLight : _cardDescStyleForDark,
              children: descriptionLink != null
                  ? [
                      if (description != null) const TextSpan(text: '. '),
                      TextSpan(
                        text: '${t.moreAbout} ${title.toLowerCase()}',
                        style: TextStyle(
                          color: isLight
                              ? theme.accentColor.darkest
                              : theme.accentColor.lightest,
                          fontWeight: .w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async =>
                              launchURL(descriptionLink!),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ],
    );

    if (trailing != null) {
      return Padding(
        padding: .only(
          left: contentPadding.resolve(.ltr).left + (leading != null ? 0 : 40),
          top: contentPadding.resolve(.ltr).top,
          bottom: contentPadding.resolve(.ltr).bottom,
          right:
              contentPadding.resolve(.ltr).right +
              (extraTrailingPadding ? 28 : 0),
        ),
        child: Row(
          spacing: 16.0,
          children: [
            if (leading != null) leading!,
            Expanded(child: content),
            trailing!,
          ],
        ),
      );
    }

    return Padding(padding: contentPadding, child: content);
  }
}

/// A toggle switch widget used in [CardHighlight] for actions.
class CardToggleSwitch extends StatelessWidget {
  const CardToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.requiresRestart = false,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool requiresRestart;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Text(
          value ? t.onStatus : t.offStatus,
          style: enabled
              ? null
              : TextStyle(color: context.theme.resources.textFillColorDisabled),
        ),
        const SizedBox(width: 10.0),
        ToggleSwitch(
          checked: value,
          onChanged: enabled
              ? (newValue) async {
                  onChanged(newValue);
                  if (requiresRestart) {
                    showRestartDialog(context);
                  }
                }
              : null,
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
    return Text(value ? t.onStatus : t.offStatus);
  }
}

/// Shows a restart dialog to inform the user that a restart is required.
void showRestartDialog(
  final BuildContext context, {
  String title = '',
  String content = '',
}) {
  showDialog(
    context: context,
    builder: (context) => ContentDialog(
      title: title.isEmpty ? null : Text(title),
      content: Text(content.isEmpty ? t.restartDialog : content),
      actions: [
        Button(child: Text(t.okButton), onPressed: () => context.pop()),
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
