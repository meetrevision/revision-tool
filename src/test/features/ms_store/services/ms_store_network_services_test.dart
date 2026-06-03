import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/error/app_exception.dart';
import 'package:revitool/core/error/result.dart';
import 'package:revitool/core/network/api_client.dart';
import 'package:revitool/features/ms_store/models/product_details/product_details.dart';
import 'package:revitool/features/ms_store/models/search/search_product.dart';
import 'package:revitool/features/ms_store/models/win32/win32_manifest_dto.dart';
import 'package:revitool/features/ms_store/services/ms_store_product_details_service.dart';
import 'package:revitool/features/ms_store/services/ms_store_search_service.dart';
import 'package:revitool/features/ms_store/services/package_file_service.dart';
import 'package:revitool/features/ms_store/services/uwp_xml_parser.dart';
import 'package:revitool/features/ms_store/services/win32_service.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.test'));
    registerFallbackValue(Options());
  });

  group('MS Store network services', () {
    late _MockApiClient apiClient;

    setUp(() {
      apiClient = _MockApiClient();
    });

    test('search parses products from ApiClient response', () async {
      when(
        () => apiClient.get<dynamic>(
          any<Uri>(),
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Result<Response<dynamic>>.success(
          Response<dynamic>(
            requestOptions: RequestOptions(),
            statusCode: 200,
            data: {
              'productsList': [
                {'productId': '9TEST', 'title': 'Test App'},
              ],
            },
          ),
        ),
      );

      final Result<List<SearchProduct>> result = await MSStoreSearchService(
        apiClient,
      ).searchProducts('test');

      expect(result, isA<Success<List<SearchProduct>>>());
      final List<SearchProduct> products =
          (result as Success<List<SearchProduct>>).value;
      expect(products.single.productId, '9TEST');
    });

    test('product details parses ApiClient response', () async {
      when(
        () => apiClient.get<dynamic>(
          any<Uri>(),
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Result<Response<dynamic>>.success(
          Response<dynamic>(
            requestOptions: RequestOptions(),
            statusCode: 200,
            data: {'productId': '9TEST', 'title': 'Test App'},
          ),
        ),
      );

      final Result<ProductDetails> result = await MSStoreProductDetailsService(
        apiClient,
      ).getProductDetails('9TEST');

      expect(result, isA<Success<ProductDetails>>());
      expect((result as Success<ProductDetails>).value.title, 'Test App');
    });

    test('Win32 manifest propagates ApiClient failure', () async {
      when(() => apiClient.get<dynamic>(any<Uri>())).thenAnswer(
        (_) async =>
            const Result<Response<dynamic>>.failure(NetworkException()),
      );

      final service = Win32Service(
        api: apiClient,
        detailsService: MSStoreProductDetailsService(apiClient),
        xmlParser: const UwpXmlParser(),
      );

      final Result<Win32ManifestDto> result = await service.getPackageManifest(
        'XPTEST',
      );

      expect(result, isA<Failure<Win32ManifestDto>>());
      expect(
        (result as Failure<Win32ManifestDto>).exception,
        isA<NetworkException>(),
      );
    });

    test(
      'package downloads delegate to ApiClient and preserve progress',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync(
          'ms_store_file_service_test_',
        );
        final path = '${tempDir.path}\\package.msix';
        final progress = <double>[];

        when(
          () => apiClient.downloadFile(
            any<Uri>(),
            any<String>(),
            onReceiveProgress: any<ProgressCallback?>(
              named: 'onReceiveProgress',
            ),
            cancelToken: any<CancelToken?>(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          final callback =
              invocation.namedArguments[#onReceiveProgress]
                  as ProgressCallback?;
          callback?.call(5, 10);
          return Result<Response<dynamic>>.success(
            Response<dynamic>(
              requestOptions: RequestOptions(),
              statusCode: 200,
            ),
          );
        });

        final Result<void> result = await PackageFileService(apiClient)
            .downloadPackage(
              'https://example.test/package.msix',
              path,
              onProgress: (count, total) => progress.add(count / total),
            );

        expect(result, isA<Success<void>>());
        expect(progress, [0.5]);

        tempDir.deleteSync(recursive: true);
      },
    );
  });
}

final class _MockApiClient extends Mock implements ApiClient {}
