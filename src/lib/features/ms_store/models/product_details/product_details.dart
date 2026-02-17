// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../search/search_product.dart';

part 'product_details.freezed.dart';
part 'product_details.g.dart';

@freezed
abstract class ProductDetails with _$ProductDetails {
  const factory ProductDetails({
    @JsonKey(name: 'productId') String? productId,
    String? title,
    String? description,
    String? publisherName,
    String? categoryId,
    List<String>? categoryIds,
    List<String>? categories,
    String? subcategoryName,
    String? displayPrice,
    String? strikethroughPrice,
    double? averageRating,
    int? ratingCount,
    String? ratingCountFormatted,
    String? productFamilyName,
    String? iconUrl,
    String? iconUrlBackground,
    String? posterArtUrl,
    String? boxArtUrl,
    String? heroImageUrl,
    String? pdpImageUrl,
    List<SearchProductPreviews>? screenshots,
    List<SearchProductPreviews>? images,
    List<SearchProductPreviews>? previews,
    List<String>? features,
    List<String?>? notes,
    List<String>? permissionsRequired,
    List<String>? platforms,
    List<String>? supportedLanguages,
    String? privacyUrl,
    String? appWebsiteUrl,
    String? publisherId,
    String? publisherAddress,
    String? publisherPhoneNumber,
    String? publisherCopyrightInformation,
    String? lastUpdateDateUtc,
    String? packageLastUpdateDateUtc,
    String? releaseDateUtc,
    int? approximateSizeInBytes,
    int? maxInstallSizeInBytes,
    String? version,
    List<ProductRating>? productRatings,
    ProductSystemRequirements? systemRequirements,
    ProductInstaller? installer,
  }) = _ProductDetails;

  factory ProductDetails.fromJson(Map<String, Object?> json) =>
      _$ProductDetailsFromJson(json);
}

@freezed
abstract class ProductRating with _$ProductRating {
  const factory ProductRating({
    String? ratingSystem,
    String? ratingSystemShortName,
    String? ratingSystemId,
    String? ratingSystemUrl,
    String? ratingValue,
    String? ratingId,
    String? ratingValueLogoUrl,
    List<String>? ratingDescriptors,
    List<String>? interactiveElements,
    int? ratingAge,
    String? longName,
    String? shortName,
    String? description,
    bool? hasInAppPurchases,
  }) = _ProductRating;

  factory ProductRating.fromJson(Map<String, Object?> json) =>
      _$ProductRatingFromJson(json);
}

@freezed
abstract class ProductSystemRequirements with _$ProductSystemRequirements {
  const factory ProductSystemRequirements({
    ProductSystemRequirementSection? minimum,
    ProductSystemRequirementSection? recommended,
  }) = _ProductSystemRequirements;

  factory ProductSystemRequirements.fromJson(Map<String, Object?> json) =>
      _$ProductSystemRequirementsFromJson(json);
}

@freezed
abstract class ProductSystemRequirementSection
    with _$ProductSystemRequirementSection {
  const factory ProductSystemRequirementSection({
    String? title,
    List<ProductSystemRequirementItem>? items,
  }) = _ProductSystemRequirementSection;

  factory ProductSystemRequirementSection.fromJson(Map<String, Object?> json) =>
      _$ProductSystemRequirementSectionFromJson(json);
}

@freezed
abstract class ProductSystemRequirementItem
    with _$ProductSystemRequirementItem {
  const factory ProductSystemRequirementItem({
    String? level,
    String? itemCode,
    String? name,
    String? description,
    String? validationHint,
    bool? isValidationPassed,
    String? priority,
  }) = _ProductSystemRequirementItem;

  factory ProductSystemRequirementItem.fromJson(Map<String, Object?> json) =>
      _$ProductSystemRequirementItemFromJson(json);
}

@freezed
abstract class ProductInstaller with _$ProductInstaller {
  const factory ProductInstaller({
    String? type,
    String? id,
    String? productCode,
    Map<String, ProductInstallerArch>? architectures,
  }) = _ProductInstaller;

  factory ProductInstaller.fromJson(Map<String, Object?> json) =>
      _$ProductInstallerFromJson(json);
}

@freezed
abstract class ProductInstallerArch with _$ProductInstallerArch {
  const factory ProductInstallerArch({
    String? version,
    String? sourceUri,
    String? cdnUri,
    String? args,
    String? hash,
  }) = _ProductInstallerArch;

  factory ProductInstallerArch.fromJson(Map<String, Object?> json) =>
      _$ProductInstallerArchFromJson(json);
}
