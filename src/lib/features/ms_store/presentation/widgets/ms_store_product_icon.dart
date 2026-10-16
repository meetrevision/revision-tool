import 'package:fluent_ui/fluent_ui.dart';

import '../../../../core/widgets/app_image.dart';

class const MSStoreProductIcon({
  super.key,
  required final String productId,
  required final String iconUrl,
  required final double size,
  final double borderRadius = 0.0,
  final Color? backgroundColor,
  final Widget placeholder = const SizedBox.shrink(),
}) extends StatelessWidget {
  static const _artworkSize = 100.0;

  static Object heroTag(String productId) => ('ms-store-product-icon', productId.toUpperCase());

  @override
  Widget build(BuildContext context) {
    if (iconUrl.isEmpty) return placeholder;

    final BorderRadius radius = .circular(borderRadius * _artworkSize / size);

    return SizedBox.square(
      dimension: size,
      child: Hero(
        tag: heroTag(productId),
        child: FittedBox(
          child: SizedBox.square(
            dimension: _artworkSize,
            child: DecoratedBox(
              decoration: BoxDecoration(color: backgroundColor, borderRadius: radius),
              child: AppImage(
                fetchPadding: 0,
                baseUrl: iconUrl,
                borderRadius: radius,
                errorWidget: placeholder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
