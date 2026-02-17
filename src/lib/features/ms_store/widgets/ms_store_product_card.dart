import 'dart:async' show Timer;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/card_highlight.dart';
import '../../../extensions.dart';
import '../../../i18n/strings.g.dart';
import '../models/search/search_product.dart';

const BorderRadius _cardRadius = .all(.circular(8.0));
const _iconXY = 64.0;
const double _posterAspectRatio = 16 / 9;

class MSStoreProductCard extends StatefulWidget {
  const MSStoreProductCard({super.key, required this.product, this.onPressed});

  final SearchProduct product;
  final VoidCallback? onPressed;

  @override
  State<MSStoreProductCard> createState() => _MSStoreProductCardState();
}

class _MSStoreProductCardState extends State<MSStoreProductCard> {
  final ValueNotifier<bool> _extendedHoverNotifier = ValueNotifier(false);
  bool _isHovered = false;
  Timer? _hoverTimer;
  OverlayEntry? _overlayEntry;
  bool _overlayVisible = false;
  final LayerLink _layerLink = LayerLink();

  void _onHoverChange(bool isHovered, Widget child) {
    if (isHovered) {
      setState(() => _isHovered = true);
      _hoverTimer?.cancel();
      _hoverTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_isHovered) {
          _extendedHoverNotifier.value = true;
          _showOverlay(child);
        }
      });
    } else {
      _hoverTimer?.cancel();
      setState(() {
        _isHovered = false;
        if (!_overlayVisible) {
          _extendedHoverNotifier.value = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _removeOverlay();
    _extendedHoverNotifier.dispose();
    super.dispose();
  }

  void _showOverlay(Widget child) {
    if (_overlayVisible) return;
    final OverlayState overlayState = Overlay.of(context);
    final RenderObject? box = context.findRenderObject();
    if (box == null || box is! RenderBox) return;
    final Size size = box.size;
    const scale = 1.05;
    final Size scaledSize = size * scale;
    final offset = Offset(
      -(scaledSize.width - size.width) / 2,
      -(scaledSize.height - size.height) / 2,
    );

    _overlayEntry = OverlayEntry(
      canSizeOverlay: true,
      builder: (_) {
        final ResourceDictionary resources = context.theme.resources;
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: offset,
          child: UnconstrainedBox(
            alignment: .topLeft,
            child: SizedBox.fromSize(
              size: scaledSize,
              child: TweenAnimationBuilder<double>(
                duration: context.theme.slowAnimationDuration,
                curve: const Cubic(0, 0, 0, 1),
                tween: .new(begin: 0.95, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: MouseRegion(
                  opaque:
                      false, // makes the overlay hover region non-opaque so pointer events (like scroll) pass through while still tracking hover exit
                  onExit: (_) => _removeOverlay(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _cardRadius,
                      color: context.theme.cardColor,
                      border: .all(
                        color: resources.cardStrokeColorDefault,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      clipBehavior: .hardEdge,
                      borderRadius: _cardRadius,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.theme.brightness == .light
                              ? Colors.white
                              : const Color(0xFF2A2E39),
                          border: .all(
                            color: resources.cardStrokeColorDefault,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(padding: const .all(11), child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    _overlayVisible = true;
  }

  void _removeOverlay() {
    if (!_overlayVisible) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayVisible = false;
    if (mounted) {
      setState(() {
        _extendedHoverNotifier.value = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ResourceDictionary resources = context.theme.resources;

    final column = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        CardListTile(
          leading: _buildLeadingIcon(context),
          title: widget.product.title ?? 'Unknown',
          description: '${widget.product.productFamilyName}',
          trailing: ValueListenableBuilder<bool>(
            valueListenable: _extendedHoverNotifier,
            builder: (context, value, _) => _HoverGetButton(
              isHovered: value,
              trailingText: widget.product.displayPrice!,
              onPressed: widget.onPressed,
            ),
          ),
          extraTrailingPadding: false,
          contentPadding: const .fromLTRB(0, 0, 10, 0),
        ),
        Padding(
          padding: const .all(6.0),
          child: Text(
            widget.product.description ?? '',
            maxLines: 2,
            overflow: .ellipsis,
            style: TextStyle(
              color: resources.textFillColorSecondary,
              fontSize: 12,
            ),
            textAlign: .start,
          ),
        ),
        _Poster(preview: widget.product.previews!.first),
      ],
    );

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true, column),
      onExit: (_) => _onHoverChange(false, column),
      child: HoverButton(
        onPressed: widget.onPressed,
        builder: (_, states) => CompositedTransformTarget(
          link: _layerLink,
          child: FocusBorder(
            focused: states.isFocused,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _cardRadius,
                color: context.theme.cardColor,
                border: .all(
                  color: resources.cardStrokeColorDefault,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                clipBehavior: .hardEdge,
                borderRadius: _cardRadius,
                child: AnimatedContainer(
                  duration: context.theme.slowAnimationDuration,
                  curve: const Cubic(0, 0, 0, 1.0),
                  padding: const .all(11),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? (context.theme.brightness == .light
                              ? null
                              : resources.cardBackgroundFillColorSecondary)
                        : Colors.transparent,
                  ),
                  child: column,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final String? iconUrl = widget.product.iconUrl;
    if (iconUrl == null || iconUrl.isEmpty) {
      return const Icon(
        msicons.FluentIcons.store_microsoft_24_regular,
        size: _iconXY - 6,
      );
    }

    return SizedBox(
      width: _iconXY,
      height: _iconXY,
      child: AppImage(
        fetchPadding: 0,
        baseUrl: iconUrl,
        borderRadius: const .all(.circular(4.0)),
      ),
    );
  }
}

class _HoverGetButton extends StatelessWidget {
  const _HoverGetButton({
    required this.isHovered,
    required this.trailingText,
    required this.onPressed,
  });

  final bool isHovered;
  final String trailingText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ResourceDictionary resources = context.theme.resources;
    return AnimatedContainer(
      duration: context.theme.fastAnimationDuration,
      curve: const Cubic(0, 0, 0, 1.0),
      child: isHovered
          ? FilledButton(
              key: const ValueKey('get-button'),
              onPressed: onPressed,
              child: Text(t.get, style: const TextStyle(fontWeight: .bold)),
            )
          : FilledButton(
              key: const ValueKey('price-button'),
              style: ButtonStyle(
                backgroundColor: .all(
                  resources.cardBackgroundFillColorSecondary,
                ),
                foregroundColor: .all(resources.textFillColorSecondary),
              ),
              onPressed: null,
              child: Text(trailingText),
            ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.preview});

  final SearchProductPreviews preview;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final ResourceDictionary resources = theme.resources;

    return Padding(
      padding: const .all(7),
      child: ClipRRect(
        clipBehavior: .hardEdge,
        borderRadius: const .all(.circular(6.0)),
        child: AspectRatio(
          aspectRatio: _posterAspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  preview.backgroundColor != null &&
                      preview.backgroundColor!.isNotEmpty &&
                      preview.backgroundColor!.startsWith('#')
                  ? Color(
                      int.parse(
                        preview.backgroundColor!.replaceFirst('#', '0xFF'),
                      ),
                    )
                  : resources.cardBackgroundFillColorSecondary,
              border: .all(
                color: resources.cardBackgroundFillColorSecondary,
                width: 1.5,
              ),
            ),
            child: AppImage(
              baseUrl: preview.url!,
              errorWidget: Icon(
                msicons.FluentIcons.image_24_regular,
                size: 48,
                color: resources.textFillColorSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
