import 'package:dio/dio.dart';

import '../../../core/services/network_service.dart';
import '../models/win32/win32_manifest_dto.dart';

/// Service for Win32 (non-UWP) MS Store API calls.
class Win32ApiService {
  Win32ApiService(this._networkService);

  final NetworkService _networkService;
  static const _storeAPI = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0';

  /// Fetches the manifest for a Win32 app
  Future<Win32ManifestDto> getPackageManifest(String productId) async {
    final Response<dynamic> response = await _networkService.get(
      '$_storeAPI/packageManifests/$productId?Market=US',
    );

    if (response.statusCode == 200) {
      return Win32ManifestDto.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception(
      'Failed to get package manifest for $productId (Status: ${response.statusCode})',
    );
  }
}
