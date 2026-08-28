import 'package:flutter/foundation.dart';

@immutable
class const ProductDetails({
  required final String id,
  required final String title,
  required final String description,
  required final String publisherName,
  required final List<String> categories,
  required final String iconUrl,
  required final String iconUrlBackground,
  required final String heroImageUrl,
  required final List<ProductImage> screenshots,
  required final List<String> features,
  required final double? averageRating,
  required final int? ratingCount,
  required final String? ratingCountFormatted,
  required final List<ProductRating> productRatings,
  required final ProductSystemRequirements? systemRequirements,
  required final int? approximateSizeBytes,
  required final String? lastUpdateUtc,
  required final String? releaseDateUtc,
  required final ProductInstaller? installer,
});

@immutable
class const ProductImage({
  required final String url,
  required final String backgroundColor,
  required final int? width,
  required final int? height,
  required final String caption,
});

@immutable
class const ProductRating({
  required final String? ratingId,
  required final String? longName,
  required final String? ratingValueLogoUrl,
  required final List<String> ratingDescriptors,
  required final List<String> interactiveElements,
});

@immutable
class const ProductSystemRequirements({
  required final RequirementSection? minimum,
  required final RequirementSection? recommended,
});

@immutable
class const RequirementSection({
  required final String? title,
  required final List<RequirementItem> items,
});

@immutable
class const RequirementItem({required final String? name, required final String? description});

@immutable
class const ProductInstaller({
  required final String? type,
  required final String? id,
  required final String? productCode,
  required final Map<String, InstallerArch> architectures,
});

@immutable
class const InstallerArch({
  required final String? version,
  required final String? sourceUri,
  required final String? cdnUri,
  required final String? args,
  required final String? hash,
});
