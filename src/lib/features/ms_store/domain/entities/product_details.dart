import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';

/// Domain entities use FIC collections for value equality, structural sharing,
/// and O(1)/O(log N) copy-on-write updates. Records + FIC give 100% type-safe,
/// immutable, value-equal state without codegen (see StoreState in
/// presentation/providers/store_providers.dart).
@immutable
class const ProductDetails({
  required final String id,
  required final String title,
  required final String description,
  required final String publisherName,
  required final IList<String> categories,
  required final String iconUrl,
  required final String iconUrlBackground,
  required final String heroImageUrl,
  required final IList<ProductImage> screenshots,
  required final IList<String> features,
  required final double? averageRating,
  required final int? ratingCount,
  required final String? ratingCountFormatted,
  required final IList<ProductRating> productRatings,
  required final ProductSystemRequirements? systemRequirements,
  required final int? approximateSizeBytes,
  required final String? lastUpdateUtc,
  required final String? releaseDateUtc,
  required final ProductInstaller? installer,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDetails &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          publisherName == other.publisherName &&
          categories == other.categories &&
          iconUrl == other.iconUrl &&
          iconUrlBackground == other.iconUrlBackground &&
          heroImageUrl == other.heroImageUrl &&
          screenshots == other.screenshots &&
          features == other.features &&
          averageRating == other.averageRating &&
          ratingCount == other.ratingCount &&
          ratingCountFormatted == other.ratingCountFormatted &&
          productRatings == other.productRatings &&
          systemRequirements == other.systemRequirements &&
          approximateSizeBytes == other.approximateSizeBytes &&
          lastUpdateUtc == other.lastUpdateUtc &&
          releaseDateUtc == other.releaseDateUtc &&
          installer == other.installer;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    publisherName,
    categories,
    iconUrl,
    heroImageUrl,
    screenshots,
    features,
    averageRating,
    ratingCount,
    productRatings,
    systemRequirements,
    approximateSizeBytes,
    installer,
  );
}

extension ProductDetailsX on ProductDetails {
  /// Cached index of screenshots by URL. First call is O(n), then O(1).
  /// Cache lives on the IList instance and is GC'd with it.
  static final _screenshotsByUrl = CacheKey<IList<ProductImage>, Map<String, ProductImage>>(
    (shots) => {for (final s in shots) s.url: s},
  );

  ProductImage? screenshotByUrl(String url) => screenshots.cached(_screenshotsByUrl)[url];

  /// Cached installer lookup is already O(1) via IMap, but this shows how to
  /// derive a filtered view (e.g. only architectures with a download URI).
  static final _downloadableArchs =
      CacheKey<IMap<String, InstallerArch>, IMap<String, InstallerArch>>(
        (archs) => archs.where((k, v) => v.sourceUri?.isNotEmpty ?? false),
      );

  IMap<String, InstallerArch> get downloadableArchitectures =>
      installer?.architectures.cached(_downloadableArchs) ?? const .empty();
}

@immutable
class const ProductImage({
  required final String url,
  required final String backgroundColor,
  required final int? width,
  required final int? height,
  required final String caption,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductImage &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          backgroundColor == other.backgroundColor &&
          width == other.width &&
          height == other.height &&
          caption == other.caption;

  @override
  int get hashCode => Object.hash(url, backgroundColor, width, height, caption);
}

@immutable
class const ProductRating({
  required final String? ratingId,
  required final String? longName,
  required final String? ratingValueLogoUrl,
  required final IList<String> ratingDescriptors,
  required final IList<String> interactiveElements,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductRating &&
          runtimeType == other.runtimeType &&
          ratingId == other.ratingId &&
          longName == other.longName &&
          ratingValueLogoUrl == other.ratingValueLogoUrl &&
          ratingDescriptors == other.ratingDescriptors &&
          interactiveElements == other.interactiveElements;

  @override
  int get hashCode =>
      Object.hash(ratingId, longName, ratingValueLogoUrl, ratingDescriptors, interactiveElements);
}

@immutable
class const ProductSystemRequirements({
  required final RequirementSection? minimum,
  required final RequirementSection? recommended,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSystemRequirements &&
          runtimeType == other.runtimeType &&
          minimum == other.minimum &&
          recommended == other.recommended;

  @override
  int get hashCode => Object.hash(minimum, recommended);
}

@immutable
class const RequirementSection({
  required final String? title,
  required final IList<RequirementItem> items,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequirementSection &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          items == other.items;

  @override
  int get hashCode => Object.hash(title, items);
}

@immutable
class const RequirementItem({required final String? name, required final String? description}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequirementItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => Object.hash(name, description);
}

@immutable
class const ProductInstaller({
  required final String? type,
  required final String? id,
  required final String? productCode,
  required final IMap<String, InstallerArch> architectures,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductInstaller &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id &&
          productCode == other.productCode &&
          architectures == other.architectures;

  @override
  int get hashCode => Object.hash(type, id, productCode, architectures);
}

@immutable
class const InstallerArch({
  required final String? version,
  required final String? sourceUri,
  required final String? cdnUri,
  required final String? args,
  required final String? hash,
}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallerArch &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          sourceUri == other.sourceUri &&
          cdnUri == other.cdnUri &&
          args == other.args &&
          hash == other.hash;

  @override
  int get hashCode => Object.hash(version, sourceUri, cdnUri, args, hash);
}
