import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/compute.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/uwp/uwp_package.dart';
import '../services/ms_store_xml_templates.dart';
import '../services/uwp_xml_parser.dart';
import 'ms_store_endpoints.dart';

// Client for fe3.delivery.mp.microsoft.com SOAP API.
// Handles cookie, SyncUpdates and GetExtendedUpdateInfo2.
// Stateless except for in-memory cookie cache.

final fe3DeliveryClientProvider = Provider<Fe3DeliveryClient>((ref) {
  return Fe3DeliveryClient(
    api: ref.read(apiClientProvider),
    parser: ref.read(storeUwpXmlParserProvider),
  );
});

final class const Fe3DeliveryClient({
  required final ApiClient _api,
  required final UwpXmlParser _parser,
}) {
  // In-memory cookie. Clear via clearSession().
  static String? _cookie;

  static final Options _soapOptions = Options(
    headers: const {
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'Accept': '*/*',
      'Content-Type': 'application/soap+xml',
    },
  );

  // Get encrypted cookie from FE3. Cached in memory.
  // Cookie is needed for SyncUpdates. Expires quickly, but app keeps it for session.
  Future<String> getCookie() async {
    if (_cookie != null) return _cookie!;

    final Result<Response<dynamic>> result = await _api.post<dynamic>(
      MSStoreEndpoints.fe3Delivery(),
      data: MsStoreXmlTemplate.cookie.xml,
      options: _soapOptions,
    );

    final String xml = result.when(
      success: (r) {
        if (r.statusCode == 200) return r.data.toString();
        throw HttpStatusException(r.statusCode ?? 500, 'Failed to get a cookie');
      },
      failure: (e) => throw e,
    );

    _cookie = _parser.parseCookieResponse(xml);
    return _cookie!;
  }

  // SyncUpdates returns list of UWP packages for given category and ring.
  // Parses large XML in isolate via compute.
  Future<UwpPackageResponse> syncUpdates({required String categoryId, required String ring}) async {
    final String cookie = await getCookie();

    final String body = MsStoreXmlTemplate.wu.xml
        .replaceAll('{1}', cookie)
        .replaceAll('{2}', categoryId)
        .replaceAll('{3}', ring);

    final Result<Response<dynamic>> result = await _api.post<dynamic>(
      MSStoreEndpoints.fe3Delivery(),
      data: body,
      options: _soapOptions,
    );

    final String xml = result
        .when(
          success: (r) {
            if (r.statusCode == 200) return r.data.toString();
            throw HttpStatusException(
              r.statusCode ?? 500,
              'Failed to get package information for $categoryId',
              responseBody: r.data,
            );
          },
          failure: (e) => throw e,
        )
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    return compute(UwpXmlParser.parsePackageListXml, xml);
  }

  // Get download URL for a single UWP file.
  // Uses SHA1 digest for correlation. FE3 FileDigest is SHA1.
  Future<String> getDownloadUrl({
    required String updateId,
    required String revision,
    required String ring,
    String? digest,
  }) async {
    final String body = MsStoreXmlTemplate.url.xml
        .replaceAll('{1}', updateId)
        .replaceAll('{2}', revision)
        .replaceAll('{3}', ring);

    final Response<dynamic> response = await _api
        .post<dynamic>(
          MSStoreEndpoints.fe3Delivery(secured: true),
          data: body,
          options: _soapOptions,
        )
        .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

    if (response.statusCode != 200) {
      throw HttpStatusException(
        response.statusCode ?? 500,
        'Failed to get download URI for $updateId',
        responseBody: response.data,
      );
    }

    return _parser.parseDownloadUrl(response.data.toString(), digest);
  }

  static void clearSession() {
    _cookie = null;
  }
}
