import 'dart:async';
import 'dart:developer' as developer;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

/// An [ImageProvider] that reduces network requests by tracking the largest
/// dimensions fetched per URL and reusing [ResizeImage] to downsample for smaller requests.
/// Adds a configurable [fetchPadding] to prevent refetches during UI animations.
/// Designed for MS Store images that support dynamic resizing via query parameters.
@immutable
class MSStoreImageProvider extends ImageProvider<MSStoreImageProvider> {
  const MSStoreImageProvider({
    required this.baseUrl,
    required this.width,
    required this.height,
    this.fetchPadding = 100,
  });

  final String baseUrl;
  final int width;
  final int height;
  final int fetchPadding;

  static final Map<String, ({int height, int width})> _maxFetched = {};

  @override
  Future<MSStoreImageProvider> obtainKey(ImageConfiguration config) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    MSStoreImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final int fetchWidth = width + fetchPadding;
    final int fetchHeight = height + fetchPadding;
    final ({int height, int width})? maxDims = _maxFetched[baseUrl];

    if (maxDims == null) {
      // First request - fetch padded size
      _maxFetched[baseUrl] = (height: fetchHeight, width: fetchWidth);

      final ImageProvider<Object> provider = ResizeImage(
        NetworkImage('$baseUrl?w=$fetchWidth&h=$fetchHeight'),
        height: height,
        width: width,
      );

      developer.log(
        'Initial fetch: ${fetchWidth}x$fetchHeight (display: ${width}x$height) $baseUrl',
      );

      return provider.resolve(ImageConfiguration.empty).completer!;
    }

    // Subsequent request - check if we can reuse larger cached image
    if (width <= maxDims.width && height <= maxDims.height) {
      final ImageProvider<Object> provider = ResizeImage(
        NetworkImage('$baseUrl?w=${maxDims.width}&h=${maxDims.height}'),
        width: width,
        height: height,
      );

      developer.log(
        'ResizeImage: ${width}x$height from cached ${maxDims.width}x${maxDims.height} $baseUrl',
      );
      return provider.resolve(ImageConfiguration.empty).completer!;
    }

    // Need larger - fetch new size
    _maxFetched[baseUrl] = (width: fetchWidth, height: fetchHeight);
    final ImageProvider<Object> provider = ResizeImage(
      NetworkImage('$baseUrl?w=$fetchWidth&h=$fetchHeight'),
      width: width,
      height: height,
    );
    developer.log(
      'Fetching larger: ${fetchWidth}x$fetchHeight (display: ${width}x$height) $baseUrl',
    );
    return provider.resolve(ImageConfiguration.empty).completer!;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MSStoreImageProvider &&
        other.baseUrl == baseUrl &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(baseUrl, width, height);
}
