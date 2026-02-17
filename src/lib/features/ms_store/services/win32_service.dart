import 'package:dio/dio.dart';

import '../../../core/services/network_service.dart';
import '../../../utils.dart';
import '../models/package_info.dart';
import '../models/product_details/product_details.dart';
import '../models/uwp/uwp_package.dart';
import '../models/win32/win32_manifest_dto.dart';
import 'ms_store_product_details_service.dart';
import 'uwp_xml_parser.dart';

/// Service for Win32 (non-UWP) MS Store API calls.
class Win32Service {
  // const Win32ApiService(this._networkService);

  const Win32Service({
    required NetworkService networkService,
    required MSStoreProductDetailsService detailsService,
    required UwpXmlParser xmlParser,
  }) : _networkService = networkService,
       _detailsService = detailsService,
       _xmlParser = xmlParser;

  final NetworkService _networkService;
  final MSStoreProductDetailsService _detailsService;
  final UwpXmlParser _xmlParser;

  static const _storeAPI = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0';

  /// Fetches Win32 packages. Tries the installer field from product details
  /// first, then falls back to the Win32 manifest API.
  Future<Set<PackageInfo>> getPackages(
    String productId,
    ProductDetails? cachedDetails,
  ) async {
    // Primary: use installer from product details (re-use cached if available)
    final Set<PackageInfo> pkgs = _parseInstallerArchitectures(
      productId,
      cachedDetails,
    );
    if (pkgs.isNotEmpty) return pkgs;

    // If no cached details, try fetching them
    if (cachedDetails == null) {
      try {
        final ProductDetails details = await _detailsService.getProductDetails(
          productId,
        );
        final Set<PackageInfo> freshPkgs = _parseInstallerArchitectures(
          productId,
          details,
        );
        if (freshPkgs.isNotEmpty) return freshPkgs;
      } catch (e) {
        logger.w('Failed to 1 product details for $productId: $e');
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
  Future<Set<PackageInfo>> _getPackagesFromManifest(String productId) async {
    final Win32ManifestDto manifest = await getPackageManifest(productId);
    final List<Versions>? versions = manifest.data?.versions;
    if (versions == null || versions.isEmpty) return {};

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
    return pkgs;
  }

  /// Fetches the manifest for a Win32 app
  Future<Win32ManifestDto> getPackageManifest(
    String productId, {
    String market = 'US',
  }) async {
    final Response<dynamic> response = await _networkService.get(
      '$_storeAPI/packageManifests/$productId?Market=$market',
    );

    if (response.statusCode == 200) {
      return Win32ManifestDto.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception(
      'Failed to get package manifest for $productId (Status: ${response.statusCode})',
    );
  }
}
