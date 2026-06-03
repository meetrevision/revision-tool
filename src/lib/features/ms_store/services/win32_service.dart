// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../utils.dart';
import '../models/package_info.dart';
import '../models/product_details/product_details.dart';
import '../models/uwp/uwp_package.dart';
import '../models/win32/win32_manifest_dto.dart';
import '../ms_store_endpoints.dart';
import 'ms_store_product_details_service.dart';
import 'uwp_xml_parser.dart';

/// Service for Win32 (non-UWP) MS Store API calls.
class Win32Service {
  // const Win32ApiService(this._networkService);

  const Win32Service({
    required ApiClient api,
    required MSStoreProductDetailsService detailsService,
    required UwpXmlParser xmlParser,
  }) : _api = api,
       _detailsService = detailsService,
       _xmlParser = xmlParser;

  final ApiClient _api;
  final MSStoreProductDetailsService _detailsService;
  final UwpXmlParser _xmlParser;

  /// Fetches Win32 packages. Tries the installer field from product details
  /// first, then falls back to the Win32 manifest API.
  Future<Result<Set<PackageInfo>>> getPackages(
    String productId,
    ProductDetails? cachedDetails,
  ) async {
    // Primary: use installer from product details (re-use cached if available)
    final Set<PackageInfo> pkgs = _parseInstallerArchitectures(
      productId,
      cachedDetails,
    );
    if (pkgs.isNotEmpty) {
      return Result<Set<PackageInfo>>.success(pkgs);
    }

    // If no cached details, try fetching them
    if (cachedDetails == null) {
      final Result<ProductDetails> detailsResult = await _detailsService
          .getProductDetails(productId);
      final ProductDetails? details = detailsResult.when(
        success: (ProductDetails value) => value,
        failure: (AppException exception) {
          logger.w(
            'Failed to fetch product details for $productId: $exception',
          );
          return null;
        },
      );
      if (details != null) {
        final Set<PackageInfo> freshPkgs = _parseInstallerArchitectures(
          productId,
          details,
        );
        if (freshPkgs.isNotEmpty) {
          return Result<Set<PackageInfo>>.success(freshPkgs);
        }
      }
    }

    // Fallback: Win32 manifest API
    return _getPackagesFromManifest(productId);
  }

  /// Parses package info from the installer.architectures field.
  Set<PackageInfo> _parseInstallerArchitectures(
    String productId,
    ProductDetails? details,
  ) {
    final Map<String, ProductInstallerArch>? architectures =
        details?.installer?.architectures;
    if (architectures == null || architectures.isEmpty) return {};

    final pkgs = <PackageInfo>{};

    for (final MapEntry(:String key, :ProductInstallerArch value)
        in architectures.entries) {
      final String? url = value.sourceUri;
      if (url == null || url.isEmpty) continue;

      final String fileName = url.split('/').last;
      final int dotIndex = fileName.lastIndexOf('.');
      final String fileType = dotIndex != -1
          ? fileName.substring(dotIndex + 1)
          : 'exe';

      pkgs.add(
        PackageInfo(
          id: productId,
          isDependency: false,
          uri: url,
          arch: key.toLowerCase(),
          fileModel: FileModel(
            fileName: fileName,
            fileType: fileType,
            digest: value.hash?.toLowerCase(),
          ),
          commandLines: value.args?.replaceAll('"', ''),
        ),
      );
    }
    return pkgs;
  }

  /// Fallback: fetches Win32 packages from the manifest API.
  Future<Result<Set<PackageInfo>>> _getPackagesFromManifest(
    String productId,
  ) async {
    final Result<Win32ManifestDto> manifestResult = await getPackageManifest(
      productId,
    );
    AppException? manifestException;
    final Win32ManifestDto? manifest = manifestResult.when(
      success: (Win32ManifestDto value) => value,
      failure: (AppException exception) {
        manifestException = exception;
        return null;
      },
    );
    if (manifest == null) {
      return Result<Set<PackageInfo>>.failure(
        manifestException ?? const UnexpectedNetworkException(),
      );
    }

    final List<Versions>? versions = manifest.data?.versions;
    if (versions == null || versions.isEmpty) {
      return const Result<Set<PackageInfo>>.success(<PackageInfo>{});
    }

    final pkgs = <PackageInfo>{};
    final urls = <String>{};

    for (final Versions version in versions) {
      for (final Installers installer in version.installers ?? <Installers>[]) {
        final String? url = installer.installerUrl;
        if (url == null || urls.contains(url)) continue;

        final String fileType =
            installer.installerType ?? url.substring(url.lastIndexOf('.') + 1);
        if (!['exe', 'msi'].contains(fileType.toLowerCase())) continue;

        pkgs.add(
          PackageInfo(
            id: productId,
            isDependency: false,
            uri: url,
            arch: installer.architecture ?? _xmlParser.extractArchitecture(url),
            fileModel: FileModel(
              fileName: '${installer.installerLocale!}-${url.split('/').last}',
              fileType: fileType,
              digest: installer.installerSha256!.toLowerCase(),
            ),
            commandLines: installer.installerSwitches?.silent?.replaceAll(
              '"',
              '',
            ),
          ),
        );
        urls.add(url);
      }
    }
    return Result<Set<PackageInfo>>.success(pkgs);
  }

  /// Fetches the manifest for a Win32 app
  Future<Result<Win32ManifestDto>> getPackageManifest(
    String productId, {
    String market = 'US',
  }) async {
    final Result<Response<dynamic>> result = await _api.get(
      MSStoreEndpoints.packageManifest(productId: productId, market: market),
    );

    return result.when(
      success: (Response<dynamic> response) {
        if (response.statusCode == 200) {
          return Result<Win32ManifestDto>.success(
            Win32ManifestDto.fromJson(response.data as Map<String, dynamic>),
          );
        }
        return Result<Win32ManifestDto>.failure(
          HttpStatusException(
            response.statusCode ?? 500,
            'Failed to get package manifest for $productId',
            responseBody: response.data,
          ),
        );
      },
      failure: Result<Win32ManifestDto>.failure,
    );
  }
}
