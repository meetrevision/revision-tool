import 'dart:async' show Timer;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/result.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../extensions.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../../domain/entities/search_product.dart';
import '../providers/store_providers.dart';
import 'ms_store_product_icon.dart';

const BorderRadius _cardRadius = .all(.circular(8.0));
const _iconXY = 56.0;
const _iconRadius = 4.0;
const _innerPadding = 16.0;
const _sectionGap = 12.0;
const _headerSpacing = 12.0;
const _titleFontSize = 14.0;
const _titleLineHeight = 20.0;
const _titleMaxLines = 2;
const _captionFontSize = 12.0;
const _captionLineHeight = 16.0;
const _descriptionMaxLines = 2;
const _posterAspectRatio = 1.71;
const _posterRadius = 4.0;
const EdgeInsets _pillPadding = .symmetric(horizontal: 8, vertical: 2);
const _cardBorder = 1.5;
const _hoverScale = 1.05;

class const MSStoreProductCard({
  super.key,
  required final SearchProduct product,
  final VoidCallback? onPressed,
}) extends StatefulWidget {
  static const idealWidth = 366.0;

  static double heightFor(double width, TextScaler textScaler) {
    final double titleBlock =
        textScaler.scale(_titleLineHeight) * _titleMaxLines + textScaler.scale(_captionLineHeight);
    final double header = titleBlock > _iconXY ? titleBlock : _iconXY;
    final double description = textScaler.scale(_captionLineHeight) * _descriptionMaxLines;
    final double poster = (width - _innerPadding * 2) / _posterAspectRatio;
    return _innerPadding * 2 + header + _sectionGap + description + _sectionGap + poster;
  }

  @override
  State<MSStoreProductCard> createState() => _MSStoreProductCardState();
}

class _MSStoreProductCardState() extends State<MSStoreProductCard> {
  final ValueNotifier<bool> _extendedHoverNotifier = ValueNotifier(false);
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;
  Timer? _hoverTimer;
  Size _cardSize = .zero;

  void _onEnter() {
    setState(() => _isHovered = true);
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_isHovered) return;
      final RenderObject? box = context.findRenderObject();
      if (box is! RenderBox) return;
      _cardSize = box.size;
      _extendedHoverNotifier.value = true;
      _overlayController.show();
    });
  }

  void _onExit() {
    _hoverTimer?.cancel();
    setState(() => _isHovered = false);
    if (!_overlayController.isShowing) _extendedHoverNotifier.value = false;
  }

  VoidCallback? get _onPressed {
    if (widget.onPressed case final onPressed?) {
      return () {
        _hoverTimer?.cancel();
        _hideOverlay();
        onPressed();
      };
    }
    return null;
  }

  void _hideOverlay() {
    if (!_overlayController.isShowing) return;
    _overlayController.hide();
    if (mounted) setState(() => _extendedHoverNotifier.value = false);
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _extendedHoverNotifier.dispose();
    super.dispose();
  }

  Widget _buildOverlay(BuildContext context) {
    final ResourceDictionary resources = context.theme.resources;
    final Size scaledSize = _cardSize * _hoverScale;
    final offset = Offset(
      -(scaledSize.width - _cardSize.width) / 2,
      -(scaledSize.height - _cardSize.height) / 2,
    );

    // Align loosens the tight full-screen constraints the Overlay hands to the
    // overlay child, letting the follower size itself to the card.
    return Align(
      alignment: .topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: offset,
        child: SizedBox.fromSize(
          size: scaledSize,
          child: TweenAnimationBuilder<double>(
            duration: context.theme.slowAnimationDuration,
            curve: const Cubic(0, 0, 0, 1),
            tween: .new(begin: 0.95, end: 1.0),
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Opacity(opacity: value, child: child),
            ),
            // non-opaque so scroll passes through while hover exit is tracked
            child: MouseRegion(
              opaque: false,
              onExit: (_) => _hideOverlay(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _cardRadius,
                  color: context.theme.cardColor,
                  border: .all(color: resources.cardStrokeColorDefault, width: _cardBorder),
                ),
                child: ClipRRect(
                  clipBehavior: .hardEdge,
                  borderRadius: _cardRadius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.theme.brightness == .light
                          ? Colors.white
                          : const Color(0xFF2A2E39),
                      border: .all(color: resources.cardStrokeColorDefault, width: _cardBorder),
                    ),
                    child: Padding(
                      padding: const .all(_innerPadding),
                      child: HeroMode(
                        enabled: false,
                        child: _CardContent(
                          product: widget.product,
                          hovered: true,
                          extendedHover: _extendedHoverNotifier,
                          onPressed: _onPressed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResourceDictionary resources = context.theme.resources;

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: HoverButton(
          onPressed: _onPressed,
          builder: (_, states) => CompositedTransformTarget(
            link: _layerLink,
            child: FocusBorder(
              focused: states.isFocused,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _cardRadius,
                  color: context.theme.cardColor,
                  border: .all(color: resources.cardStrokeColorDefault, width: _cardBorder),
                ),
                child: ClipRRect(
                  clipBehavior: .hardEdge,
                  borderRadius: _cardRadius,
                  child: AnimatedContainer(
                    duration: context.theme.slowAnimationDuration,
                    curve: const Cubic(0, 0, 0, 1.0),
                    padding: const .all(_innerPadding),
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? (context.theme.brightness == .light
                                ? null
                                : resources.cardBackgroundFillColorSecondary)
                          : Colors.transparent,
                    ),
                    child: _CardContent(
                      product: widget.product,
                      hovered: _isHovered,
                      extendedHover: _extendedHoverNotifier,
                      onPressed: _onPressed,
                    ),
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

class const _CardContent({
  required final SearchProduct product,
  required final bool hovered,
  required final ValueNotifier<bool> extendedHover,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ResourceDictionary resources = context.theme.resources;
    // Use domain entity. Title and displayPrice are always non-empty strings.
    // Empty title means fallback to unknown label.
    final String title = product.title.isEmpty ? t.msstoreUnknown : product.title;
    final String price = product.displayPrice.isEmpty
        ? t.msstoreUnknown
        : product.displayPrice;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _CardHeader(
          product: product,
          title: title,
          trailing: ValueListenableBuilder<bool>(
            valueListenable: extendedHover,
            builder: (context, value, _) => _HoverGetButton(
              productId: product.id,
              isHovered: value,
              // Starts the install lookup as soon as the pointer enters the
              // card, so it's usually resolved before the hover button shows.
              checkInstalled: hovered || value,
              trailingText: price,
              onPressed: onPressed,
            ),
          ),
        ),
        const SizedBox(height: _sectionGap),
        Text(
          product.description,
          maxLines: _descriptionMaxLines,
          overflow: .ellipsis,
          style: TextStyle(
            color: resources.textFillColorSecondary,
            fontSize: _captionFontSize,
            height: _captionLineHeight / _captionFontSize,
          ),
        ),
        const SizedBox(height: _sectionGap),
        // Poster URL is chosen in DTO.toDomain() with fallback to images.
        // Empty posterUrl means no image. Show placeholder icon.
        Expanded(
          child: _Poster(
            posterUrl: product.posterUrl,
            backgroundColor: product.posterBackgroundColor,
          ),
        ),
      ],
    );
  }
}

class const _CardHeader({
  required final SearchProduct product,
  required final String title,
  required final Widget trailing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = context.theme;

    return Row(
      crossAxisAlignment: .start,
      spacing: _headerSpacing,
      children: [
        MSStoreProductIcon(
          productId: product.id,
          iconUrl: product.iconUrl,
          size: _iconXY,
          borderRadius: _iconRadius,
          placeholder: const SizedBox.square(
            dimension: _iconXY,
            child: Icon(msicons.FluentIcons.store_microsoft_24_regular, size: _iconXY - 6),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                title,
                maxLines: _titleMaxLines,
                overflow: .ellipsis,
                style: TextStyle(
                  fontSize: _titleFontSize,
                  height: _titleLineHeight / _titleFontSize,
                  fontWeight: .w600,
                  color: theme.resources.textFillColorPrimary,
                ),
              ),
              if (product.productFamilyName.isNotEmpty)
                Text(
                  product.productFamilyName,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: _captionFontSize,
                    height: _captionLineHeight / _captionFontSize,
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class const _HoverGetButton({
  required final String productId,
  required final bool isHovered,
  required final bool checkInstalled,
  required final String trailingText,
  required final VoidCallback? onPressed,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResourceDictionary resources = context.theme.resources;
    // Only looked up while hovered, so a page of results doesn't fire a
    // network request per card. Lookup failures fall back to "Get".
    final bool installed =
        checkInstalled &&
        productId.isNotEmpty &&
        ref.watch(storeProductInstalledPackageProvider(productId)).value != null;

    return AnimatedContainer(
      duration: context.theme.fastAnimationDuration,
      curve: const Cubic(0, 0, 0, 1.0),
      child: isHovered
          ? FilledButton(
              key: ValueKey(installed ? 'open-button' : 'get-button'),
              style: const ButtonStyle(padding: WidgetStatePropertyAll(_pillPadding)),
              onPressed: installed ? () => _openApp(ref) : onPressed,
              child: Text(
                installed ? t.msstoreOpen : t.get,
                style: const TextStyle(fontWeight: .bold),
              ),
            )
          : FilledButton(
              key: const ValueKey('price-button'),
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(_pillPadding),
                backgroundColor: .all(resources.cardBackgroundFillColorSecondary),
                foregroundColor: .all(resources.textFillColorSecondary),
              ),
              onPressed: null,
              child: Text(trailingText),
            ),
    );
  }

  /// Launches the installed app, like "Open" in the Store. If it can't be
  /// launched, falls back to the product page, which shows the details.
  Future<void> _openApp(WidgetRef ref) async {
    final String? familyName = ref.read(storeProductPackageFamilyNameProvider(productId)).value;
    if (familyName == null) {
      onPressed?.call();
      return;
    }
    final Result<void> result = await ref.read(appxServiceProvider).launch(familyName: familyName);
    if (result is Failure) onPressed?.call();
  }
}

class const _Poster({required final String posterUrl, required final String backgroundColor})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final ResourceDictionary resources = theme.resources;

    // Background color comes from DTO preview or iconUrlBackground.
    // It is hex like "#1ed760". Invalid or empty value uses card color.
    final Color bg = backgroundColor.isNotEmpty && backgroundColor.startsWith('#')
        ? Color(int.parse(backgroundColor.replaceFirst('#', '0xFF')))
        : resources.cardBackgroundFillColorSecondary;

    final placeholder = Icon(
      msicons.FluentIcons.image_24_regular,
      size: 48,
      color: resources.textFillColorSecondary,
    );
    const BorderRadius radius = .all(.circular(_posterRadius));

    return DecoratedBox(
      position: .foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: .all(color: resources.controlStrokeColorDefault),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: bg,
          child: posterUrl.isEmpty
              ? placeholder
              : AppImage(baseUrl: posterUrl, errorWidget: placeholder),
        ),
      ),
    );
  }
}
