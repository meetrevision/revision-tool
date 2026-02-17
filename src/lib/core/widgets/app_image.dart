import 'dart:developer' as developer;

import 'package:fluent_ui/fluent_ui.dart';

import '../../features/ms_store/ms_store_image_provider.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.baseUrl,
    this.fit = .cover,
    this.alignment = .center,
    this.borderRadius,
    this.clipBehavior = .hardEdge,
    this.fetchPadding = 100,
    this.placeholderColor,
    this.loadingWidget,
    this.errorWidget,
  });

  final String baseUrl;
  final BoxFit fit;
  final Alignment alignment;
  final int fetchPadding;
  final BorderRadiusGeometry? borderRadius;
  final Clip clipBehavior;
  final Color? placeholderColor;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    Widget image = LayoutBuilder(
      builder: (context, constraints) {
        final double dpr = MediaQuery.devicePixelRatioOf(context);
        final int width = (constraints.maxWidth * dpr).round();
        final int height = (constraints.maxHeight * dpr).round();

        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        return Image(
          image: MSStoreImageProvider(
            baseUrl: baseUrl,
            width: width,
            height: height,
            fetchPadding: fetchPadding,
          ),
          gaplessPlayback: true,
          fit: fit,
          alignment: alignment,
          loadingBuilder: (context, child, loadingProgress) =>
              loadingProgress == null
              ? child
              : loadingWidget ??
                    Container(
                      color: placeholderColor ?? Colors.grey.withAlpha(50),
                    ),
          errorBuilder: (context, error, stackTrace) {
            developer.log(
              'Failed to load image: $baseUrl',
              error: error,
              stackTrace: stackTrace,
            );
            return errorWidget ?? const SizedBox.shrink();
          },
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        clipBehavior: clipBehavior,
        child: image,
      );
    }

    return image;
  }
}
