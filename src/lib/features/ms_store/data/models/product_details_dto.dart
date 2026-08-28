// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/product_details.dart' as domain;

part 'product_details_dto.freezed.dart';
part 'product_details_dto.g.dart';

@freezed
sealed class ProductDetailsDto with _$ProductDetailsDto {
  const factory({
    @JsonKey(name: 'productId') String? productId,
    String? title,
    String? description,
    String? publisherName,
    @Default([]) List<String> categories,
    String? iconUrl,
    String? iconUrlBackground,
    String? heroImageUrl,
    @Default([]) List<ProductImageDto> screenshots,
    @Default([]) List<ProductImageDto> images,
    @Default([]) List<ProductImageDto> previews,
    @Default([]) List<String> features,
    double? averageRating,
    int? ratingCount,
    String? ratingCountFormatted,
    @Default([]) List<ProductRatingDto> productRatings,
    ProductSystemRequirementsDto? systemRequirements,
    int? approximateSizeInBytes,
    String? lastUpdateDateUtc,
    String? releaseDateUtc,
    ProductInstallerDto? installer,
  }) = _ProductDetailsDto;

  factory fromJson(Map<String, Object?> json) => _$ProductDetailsDtoFromJson(json);
}

extension ProductDetailsDtoX on ProductDetailsDto {
  domain.ProductDetails toDomain() {
    final String id = (productId ?? '').trim().toUpperCase();

    final List<ProductImageDto> rawShots = screenshots.isNotEmpty
        ? screenshots
        : (previews.isNotEmpty ? previews : images);

    final List<domain.ProductImage> shots = rawShots
        .where((p) => (p.url ?? '').isNotEmpty)
        .map(
          (p) => domain.ProductImage(
            url: (p.url ?? '').trim(),
            backgroundColor: (p.backgroundColor ?? '').trim(),
            width: p.width,
            height: p.height,
            caption: (p.caption ?? '').trim(),
          ),
        )
        .toList(growable: false);

    final List<domain.ProductRating> ratings = productRatings
        .map(
          (r) => domain.ProductRating(
            ratingId: r.ratingId,
            longName: r.longName,
            ratingValueLogoUrl: r.ratingValueLogoUrl,
            ratingDescriptors: r.ratingDescriptors,
            interactiveElements: r.interactiveElements,
          ),
        )
        .toList(growable: false);

    domain.ProductSystemRequirements? sysReq;
    if (systemRequirements != null) {
      domain.RequirementSection? mapSection(ProductSystemRequirementSectionDto? s) {
        if (s == null) return null;
        return domain.RequirementSection(
          title: s.title,
          items: s.items
              .map((i) => domain.RequirementItem(name: i.name, description: i.description))
              .toList(growable: false),
        );
      }

      sysReq = .new(
        minimum: mapSection(systemRequirements!.minimum),
        recommended: mapSection(systemRequirements!.recommended),
      );
    }

    domain.ProductInstaller? inst;
    if (installer != null) {
      final archMap = <String, domain.InstallerArch>{};
      installer!.architectures.forEach((k, v) {
        archMap[k] = .new(
          version: v.version,
          sourceUri: v.sourceUri,
          cdnUri: v.cdnUri,
          args: v.args,
          hash: v.hash,
        );
      });
      inst = .new(
        type: installer!.type,
        id: installer!.id,
        productCode: installer!.productCode,
        architectures: archMap,
      );
    }

    return .new(
      id: id,
      title: (title ?? '').trim(),
      description: (description ?? '').trim(),
      publisherName: (publisherName ?? '').trim(),
      categories: categories,
      iconUrl: (iconUrl ?? '').trim(),
      iconUrlBackground: (iconUrlBackground ?? '').trim(),
      heroImageUrl: (heroImageUrl ?? '').trim(),
      screenshots: shots,
      features: features,
      averageRating: averageRating,
      ratingCount: ratingCount,
      ratingCountFormatted: ratingCountFormatted,
      productRatings: ratings,
      systemRequirements: sysReq,
      approximateSizeBytes: approximateSizeInBytes,
      lastUpdateUtc: lastUpdateDateUtc,
      releaseDateUtc: releaseDateUtc,
      installer: inst,
    );
  }
}

@freezed
abstract class ProductImageDto with _$ProductImageDto {
  const factory({
    String? imageType,
    String? backgroundColor,
    String? foregroundColor,
    String? caption,
    String? imagePositionInfo,
    String? url,
    int? width,
    int? height,
  }) = _ProductImageDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductImageDtoFromJson(json);
}

@freezed
abstract class ProductRatingDto with _$ProductRatingDto {
  const factory({
    String? ratingSystem,
    String? ratingSystemShortName,
    String? ratingSystemId,
    String? ratingSystemUrl,
    String? ratingValue,
    String? ratingId,
    String? ratingValueLogoUrl,
    @Default([]) List<String> ratingDescriptors,
    @Default([]) List<String> interactiveElements,
    int? ratingAge,
    String? longName,
    String? shortName,
    String? description,
    bool? hasInAppPurchases,
  }) = _ProductRatingDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductRatingDtoFromJson(json);
}

@freezed
abstract class ProductSystemRequirementsDto with _$ProductSystemRequirementsDto {
  const factory({
    ProductSystemRequirementSectionDto? minimum,
    ProductSystemRequirementSectionDto? recommended,
  }) = _ProductSystemRequirementsDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductSystemRequirementsDtoFromJson(json);
}

@freezed
abstract class ProductSystemRequirementSectionDto with _$ProductSystemRequirementSectionDto {
  const factory({String? title, @Default([]) List<ProductSystemRequirementItemDto> items}) =
      _ProductSystemRequirementSectionDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductSystemRequirementSectionDtoFromJson(json);
}

@freezed
abstract class ProductSystemRequirementItemDto with _$ProductSystemRequirementItemDto {
  const factory({
    String? level,
    String? itemCode,
    String? name,
    String? description,
    String? validationHint,
    bool? isValidationPassed,
    String? priority,
  }) = _ProductSystemRequirementItemDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductSystemRequirementItemDtoFromJson(json);
}

@freezed
abstract class ProductInstallerDto with _$ProductInstallerDto {
  const factory({
    String? type,
    String? id,
    String? productCode,
    @Default({}) Map<String, ProductInstallerArchDto> architectures,
  }) = _ProductInstallerDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductInstallerDtoFromJson(json);
}

@freezed
abstract class ProductInstallerArchDto with _$ProductInstallerArchDto {
  const factory({String? version, String? sourceUri, String? cdnUri, String? args, String? hash}) =
      _ProductInstallerArchDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductInstallerArchDtoFromJson(json);
}
