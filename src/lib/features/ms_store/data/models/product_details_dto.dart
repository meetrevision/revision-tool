// ignore_for_file: invalid_annotation_target

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
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
    @Default(IListConst([])) IList<String> categories,
    String? iconUrl,
    String? iconUrlBackground,
    String? heroImageUrl,
    @Default(IListConst([])) IList<ProductImageDto> screenshots,
    @Default(IListConst([])) IList<ProductImageDto> images,
    @Default(IListConst([])) IList<ProductImageDto> previews,
    @Default(IListConst([])) IList<String> features,
    double? averageRating,
    int? ratingCount,
    String? ratingCountFormatted,
    @Default(IListConst([])) IList<ProductRatingDto> productRatings,
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

    final IList<ProductImageDto> rawShots = screenshots.isNotEmpty
        ? screenshots
        : (previews.isNotEmpty ? previews : images);

    final IList<domain.ProductImage> shots = rawShots
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
        .toIList();

    final IList<domain.ProductRating> ratings = productRatings
        .map(
          (r) => domain.ProductRating(
            ratingId: r.ratingId,
            longName: r.longName,
            ratingValueLogoUrl: r.ratingValueLogoUrl,
            ratingDescriptors: r.ratingDescriptors,
            interactiveElements: r.interactiveElements,
          ),
        )
        .toIList();

    domain.ProductSystemRequirements? sysReq;
    if (systemRequirements != null) {
      domain.RequirementSection? mapSection(ProductSystemRequirementSectionDto? s) {
        if (s == null) return null;
        return domain.RequirementSection(
          title: s.title,
          items: s.items
              .map((i) => domain.RequirementItem(name: i.name, description: i.description))
              .toIList(),
        );
      }

      sysReq = domain.ProductSystemRequirements(
        minimum: mapSection(systemRequirements!.minimum),
        recommended: mapSection(systemRequirements!.recommended),
      );
    }

    domain.ProductInstaller? inst;
    if (installer != null) {
      final IMap<String, domain.InstallerArch> archMap = installer!.architectures.map(
        (k, v) => MapEntry(
          k,
          domain.InstallerArch(
            version: v.version,
            sourceUri: v.sourceUri,
            cdnUri: v.cdnUri,
            args: v.args,
            hash: v.hash,
          ),
        ),
      );
      inst = domain.ProductInstaller(
        type: installer!.type,
        id: installer!.id,
        productCode: installer!.productCode,
        architectures: archMap,
      );
    }

    return (
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
    @Default(IListConst([])) IList<String> ratingDescriptors,
    @Default(IListConst([])) IList<String> interactiveElements,
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
  const factory({
    String? title,
    @Default(IListConst([])) IList<ProductSystemRequirementItemDto> items,
  }) = _ProductSystemRequirementSectionDto;

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
    @Default(IMapConst({})) IMap<String, ProductInstallerArchDto> architectures,
  }) = _ProductInstallerDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductInstallerDtoFromJson(json);
}

@freezed
abstract class ProductInstallerArchDto with _$ProductInstallerArchDto {
  const factory({String? version, String? sourceUri, String? cdnUri, String? args, String? hash}) =
      _ProductInstallerArchDto;

  factory fromJson(Map<String, dynamic> json) => _$ProductInstallerArchDtoFromJson(json);
}
