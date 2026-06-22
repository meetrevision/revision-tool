import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/error/app_exception.dart';
import 'package:revitool/core/error/result.dart';
import 'package:revitool/core/network/api_client.dart';
import 'package:revitool/features/ms_store/data/store_cache.dart';
import 'package:revitool/features/ms_store/models/package_info.dart';
import 'package:revitool/features/ms_store/models/product_details/product_details.dart';
import 'package:revitool/features/ms_store/models/search/search_product.dart';
import 'package:revitool/features/ms_store/models/store_download_info.dart';
import 'package:revitool/features/ms_store/models/uwp/uwp_package.dart';
import 'package:revitool/features/ms_store/ms_store_repository.dart';
import 'package:revitool/features/ms_store/services/package_file_service.dart';
import 'package:revitool/features/ms_store/services/uwp_xml_parser.dart';
import 'package:revitool/features/ms_store/store_enums.dart';
import 'package:revitool/features/ms_store/store_service.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.test'));
    registerFallbackValue(Options());
  });

  group('MS Store network services', () {
    late _MockApiClient apiClient;

    setUp(() {
      UwpStoreRepository.clearSession();
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

      final List<SearchProduct> products = await _uwpRepository(
        apiClient,
      ).searchProducts('test');
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

      final ProductDetails details = await _uwpRepository(
        apiClient,
      ).getProductDetails('9TEST');

      expect(details.title, 'Test App');
    });

    test('UWP repository parses packages and resolves session URL', () async {
      final parser = _FakeUwpXmlParser();
      final repository = UwpStoreRepository(
        api: apiClient,
        cache: StoreCache(),
        xmlParser: parser,
      );
      var unsecurePostCalls = 0;
      var downloadUriCalls = 0;

      when(
        () => apiClient.get<dynamic>(any<Uri>()),
      ).thenAnswer((_) async => _response(data: _uwpProductJson()));
      when(
        () => apiClient.post<dynamic>(
          any<Uri>(),
          data: any<Object?>(named: 'data'),
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments.first as Uri;
        if (uri.path.endsWith('/secured')) {
          downloadUriCalls++;
          return _response(data: '<download-url />');
        }

        unsecurePostCalls++;
        return _response(
          data: unsecurePostCalls == 1 ? '<cookie />' : _uwpPackageXml,
        );
      });

      final Set<PackageInfo> packages = await repository.getPackages(
        productId: '9TEST',
        ring: StoreRing.retail,
      );
      final PackageInfo package = packages.single;
      final String url = await repository.getPackageDownloadUrl(
        package: package,
        ring: StoreRing.retail,
      );

      expect(package.isDependency, isTrue);
      expect(package.arch, 'x64');
      expect(package.updateIdentity?.id, 'download-id');
      expect(package.fileModel?.verificationDigest, 'sha256-digest');
      expect(url, 'https://example.test/session.appx');
      expect(downloadUriCalls, 1);
    });

    test('UWP repository propagates category HTTP failure', () async {
      final repository = UwpStoreRepository(
        api: apiClient,
        cache: StoreCache(),
        xmlParser: _FakeUwpXmlParser(),
      );

      when(
        () => apiClient.post<dynamic>(
          any<Uri>(),
          data: any<Object?>(named: 'data'),
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async => _response(data: '<cookie />'));
      when(() => apiClient.get<dynamic>(any<Uri>())).thenAnswer(
        (_) async => _response(statusCode: 500, data: 'category failure'),
      );

      expect(
        () =>
            repository.getPackages(productId: '9TEST', ring: StoreRing.retail),
        throwsA(isA<HttpStatusException>()),
      );
    });

    test('UWP repository fails when product misses WU category ID', () async {
      final repository = UwpStoreRepository(
        api: apiClient,
        cache: StoreCache(),
        xmlParser: _FakeUwpXmlParser(),
      );

      when(
        () => apiClient.post<dynamic>(
          any<Uri>(),
          data: any<Object?>(named: 'data'),
          options: any<Options?>(named: 'options'),
        ),
      ).thenAnswer((_) async => _response(data: '<cookie />'));
      when(() => apiClient.get<dynamic>(any<Uri>())).thenAnswer(
        (_) async => _response(data: _uwpProductJson(wuCategoryId: null)),
      );

      expect(
        () =>
            repository.getPackages(productId: '9TEST', ring: StoreRing.retail),
        throwsA(isA<UnexpectedNetworkException>()),
      );
    });

    test('Win32 repository uses product details installer first', () async {
      final Win32StoreRepository repository = _win32Repository(apiClient);
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
            data: _win32DetailsJson,
          ),
        ),
      );

      final Set<PackageInfo> packages = await repository.getPackages(
        productId: 'XPTEST',
        ring: StoreRing.retail,
      );
      final PackageInfo package = packages.single;

      expect(package.uri, 'https://example.test/app.exe');
      expect(package.arch, 'x64');
      expect(package.fileModel?.digest, 'abcdef');
      expect(package.fileModel?.digestAlgorithm, 'SHA256');
      expect(package.commandLines, '/quiet');
    });

    test('Win32 repository falls back to manifest API', () async {
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
            data: {'productId': 'XPTEST'},
          ),
        ),
      );
      when(() => apiClient.get<dynamic>(any<Uri>())).thenAnswer(
        (_) async => Result<Response<dynamic>>.success(
          Response<dynamic>(
            requestOptions: RequestOptions(),
            statusCode: 200,
            data: _win32ManifestJson,
          ),
        ),
      );

      final Set<PackageInfo> packages = await _win32Repository(
        apiClient,
      ).getPackages(productId: 'XPTEST', ring: StoreRing.retail);
      final PackageInfo package = packages.single;

      expect(package.uri, 'https://example.test/manifest.msi');
      expect(package.arch, 'x64');
      expect(package.fileModel?.digest, 'feedface');
      expect(package.commandLines, '/silent');
    });

    test('Win32 repository propagates manifest API failure', () async {
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
            data: {'productId': 'XPTEST'},
          ),
        ),
      );
      when(() => apiClient.get<dynamic>(any<Uri>())).thenAnswer(
        (_) async =>
            const Result<Response<dynamic>>.failure(NetworkException()),
      );

      expect(
        () => _win32Repository(
          apiClient,
        ).getPackages(productId: 'XPTEST', ring: StoreRing.retail),
        throwsA(isA<NetworkException>()),
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
            .download(
              'https://example.test/package.msix',
              path,
              onProgress: (count, total) => progress.add(count / total),
            );

        expect(result, isA<Success<void>>());
        expect(progress, [0.5]);

        tempDir.deleteSync(recursive: true);
      },
    );

    test('service package download delegates to ApiClient', () async {
      final StoreService service = _service(
        apiClient,
        uwpRepository: _FakeStoreRepository({
          '9TEST': {_sharedPackage(digest: 'digest', size: 12)},
        }),
      );
      final progress = <double>[];

      when(
        () => apiClient.downloadFile(
          any<Uri>(),
          any<String>(),
          onReceiveProgress: any<ProgressCallback?>(named: 'onReceiveProgress'),
          cancelToken: any<CancelToken?>(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final callback =
            invocation.namedArguments[#onReceiveProgress] as ProgressCallback?;
        callback?.call(6, 12);
        return Result<Response<dynamic>>.success(
          Response<dynamic>(requestOptions: RequestOptions(), statusCode: 200),
        );
      });

      try {
        final Result<Set<StorePackageFileDownload>> result = await service
            .download(
              ring: StoreRing.retail,
              packagesByProductId: {
                '9TEST': [_sharedPackage(digest: 'digest', size: 12)],
              },
              cancelToken: CancelToken(),
              onProgress: (value) => progress.add(value.fileProgress),
            );

        expect(result, isA<Success<Set<StorePackageFileDownload>>>());
        expect(progress, [0.5, 1]);
      } finally {
        await service.cleanup();
      }
    });

    test('single download skips a valid existing file', () async {
      final List<int> bytes = utf8.encode('downloaded package');
      final String digest = base64.encode(sha256.convert(bytes).bytes);
      final StoreService service = _service(apiClient);
      final PackageInfo package = _sharedPackage(digest: digest, size: 0);
      final packagesByProductId = {
        '9TEST': [package],
      };

      when(
        () => apiClient.downloadFile(
          any<Uri>(),
          any<String>(),
          onReceiveProgress: any<ProgressCallback?>(named: 'onReceiveProgress'),
          cancelToken: any<CancelToken?>(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final path = invocation.positionalArguments[1] as String;
        final callback =
            invocation.namedArguments[#onReceiveProgress] as ProgressCallback?;
        final file = File(path)..parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        callback?.call(bytes.length, bytes.length);
        return Result<Response<dynamic>>.success(
          Response<dynamic>(requestOptions: RequestOptions(), statusCode: 200),
        );
      });

      try {
        await service.download(
          ring: StoreRing.retail,
          packagesByProductId: packagesByProductId,
          cancelToken: CancelToken(),
          onProgress: (_) {},
        );
        await service.download(
          ring: StoreRing.retail,
          packagesByProductId: packagesByProductId,
          cancelToken: CancelToken(),
          onProgress: (_) {},
        );

        verify(
          () => apiClient.downloadFile(
            any<Uri>(),
            any<String>(),
            onReceiveProgress: any<ProgressCallback?>(
              named: 'onReceiveProgress',
            ),
            cancelToken: any<CancelToken?>(named: 'cancelToken'),
          ),
        ).called(1);
      } finally {
        await service.cleanup();
      }
    });

    test('batch download shares package paths between products', () async {
      final List<int> bytes = utf8.encode('shared dependency');
      final String digest = base64.encode(sha256.convert(bytes).bytes);
      final PackageInfo firstPackage = _sharedPackage(
        id: 'first',
        fileName: 'shared-a',
        digest: digest,
        size: bytes.length,
      );
      final PackageInfo secondPackage = _sharedPackage(
        id: 'second',
        fileName: 'shared-a',
        digest: digest,
        size: bytes.length,
      );
      final PackageInfo firstMainPackage = _mainPackage(
        id: 'first-main',
        fileName: 'first-main',
        digest: digest,
        size: bytes.length,
      );
      final PackageInfo secondMainPackage = _mainPackage(
        id: 'second-main',
        fileName: 'second-main',
        digest: digest,
        size: bytes.length,
      );
      final StoreService service = _service(
        apiClient,
        uwpRepository: _FakeStoreRepository({
          '9FIRST': {firstPackage, firstMainPackage},
          '9SECOND': {secondPackage, secondMainPackage},
        }),
      );
      final progress = <int>[];
      final downloadPaths = <String>[];

      when(
        () => apiClient.downloadFile(
          any<Uri>(),
          any<String>(),
          onReceiveProgress: any<ProgressCallback?>(named: 'onReceiveProgress'),
          cancelToken: any<CancelToken?>(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final path = invocation.positionalArguments[1] as String;
        downloadPaths.add(path);
        final callback =
            invocation.namedArguments[#onReceiveProgress] as ProgressCallback?;
        final file = File(path)..parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        callback?.call(bytes.length, bytes.length);
        return Result<Response<dynamic>>.success(
          Response<dynamic>(requestOptions: RequestOptions(), statusCode: 200),
        );
      });

      try {
        final StorePackagesByProductId packagesByProductId = await service
            .getPackages(
              productIds: ['9FIRST', '9SECOND'],
              ring: StoreRing.retail,
              arch: StoreArch.all,
            )
            .then(
              (result) => result.when(
                success: (value) => value,
                failure: (exception) => throw exception,
              ),
            );
        final Result<Set<StorePackageFileDownload>> result = await service
            .download(
              ring: StoreRing.retail,
              packagesByProductId: packagesByProductId,
              cancelToken: CancelToken(),
              onProgress: (value) => progress.add(value.completedCount),
            );

        expect(result, isA<Success<Set<StorePackageFileDownload>>>());
        verify(
          () => apiClient.downloadFile(
            any<Uri>(),
            any<String>(),
            onReceiveProgress: any<ProgressCallback?>(
              named: 'onReceiveProgress',
            ),
            cancelToken: any<CancelToken?>(named: 'cancelToken'),
          ),
        ).called(3);
        expect(
          downloadPaths,
          contains(endsWith(r'Retail\Dependencies\shared-a.appx')),
        );
        expect(downloadPaths, contains(endsWith(r'Retail\first-main.appx')));
        expect(downloadPaths, contains(endsWith(r'Retail\second-main.appx')));
        expect(progress.last, 4);
      } finally {
        await service.cleanup();
      }
    });

    test('mixed app type batch fails clearly', () async {
      final StoreService service = _service(apiClient);
      final Result<Set<StorePackageFileDownload>> result = await service
          .download(
            ring: StoreRing.retail,
            packagesByProductId: {
              '9TEST': [_sharedPackage(digest: 'digest', size: 12)],
              'XPTEST': [_win32Package()],
            },
            cancelToken: CancelToken(),
            onProgress: (_) {},
          );

      expect(result, isA<Failure<Set<StorePackageFileDownload>>>());
      expect(
        (result as Failure<Set<StorePackageFileDownload>>).exception.toString(),
        contains('Batch downloads must use one Store app type'),
      );
    });

    test('install delegates selected packages', () async {
      final recording = _RecordingPackageFileService(apiClient);
      final PackageInfo package = _win32Package();
      final StoreService service = _service(
        apiClient,
        win32Repository: _FakeStoreRepository({
          'XPTEST': {package},
        }),
        fileService: recording,
      );

      when(
        () => apiClient.downloadFile(
          any<Uri>(),
          any<String>(),
          onReceiveProgress: any<ProgressCallback?>(named: 'onReceiveProgress'),
          cancelToken: any<CancelToken?>(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Result<Response<dynamic>>.success(
          Response<dynamic>(requestOptions: RequestOptions(), statusCode: 200),
        ),
      );

      try {
        final Set<StorePackageFileDownload> downloads = await service
            .download(
              ring: StoreRing.retail,
              packagesByProductId: {
                'XPTEST': [package],
              },
              cancelToken: CancelToken(),
              onProgress: (_) {},
            )
            .then(
              (result) => result.when(
                success: (value) => value,
                failure: (exception) => throw exception,
              ),
            );
        final Result<Map<String, ProcessResult>> installResult = await service
            .install(
          downloads: downloads,
        );

        expect(installResult, isA<Success<Map<String, ProcessResult>>>());
        expect(recording.win32InstallPaths, isNotEmpty);
      } finally {
        await service.cleanup();
      }
    });

    test('UWP parser stores SHA256 AdditionalDigest for verification', () {
      const packageDigest = 'h2VpDinRGUSRY9f04ZJbJoQDWD8=';
      const packageSha256 = 'WWxxdcCw+iftKSpE9GgfaHcgp3404Ae/bEA9GUDkYAU=';
      final UwpPackageResponse response = UwpXmlParser.parsePackageListXml('''
<Root>
  <SyncUpdatesResult>
    <ExtendedUpdateInfo>
      <Updates>
        <Update>
          <ID>update-id</ID>
          <Xml>
            <Files>
              <File FileName="2a0007f4.appx" Digest="$packageDigest" DigestAlgorithm="SHA1" Size="6050794" Modified="2024-03-29T23:22:35.0330032Z" InstallerSpecificIdentifier="Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x86__8wekyb3d8bbwe">
                <AdditionalDigest Algorithm="SHA256">$packageSha256</AdditionalDigest>
              </File>
            </Files>
            <ExtendedProperties IsAppxFramework="true" PackageIdentityName="Microsoft.VCLibs.140.00.UWPDesktop" />
          </Xml>
        </Update>
      </Updates>
    </ExtendedUpdateInfo>
    <NewUpdates>
      <UpdateInfo>
        <ID>update-id</ID>
        <Xml>
          <UpdateIdentity UpdateID="download-id" RevisionNumber="1" />
          <ApplicabilityRules>
            <Metadata>
              <AppxPackageMetadata>
                <AppxMetadata PackageMoniker="Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x86__8wekyb3d8bbwe" />
              </AppxPackageMetadata>
            </Metadata>
          </ApplicabilityRules>
        </Xml>
      </UpdateInfo>
    </NewUpdates>
  </SyncUpdatesResult>
</Root>
''');

      final FileModel file = response.updates.single.xml.fileModel.single;
      expect(file.digest, packageDigest);
      expect(file.digestAlgorithm, 'SHA1');
      expect(file.additionalDigest, packageSha256);
      expect(file.additionalDigestAlgorithm, 'SHA256');
      expect(file.verificationDigest, packageSha256);
      expect(file.verificationDigestAlgorithm, 'SHA256');
    });

    test(
      'file digest verifier supports Store SHA1 and SHA256 base64',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync(
          'ms_store_digest_test_',
        );
        final file = File('${tempDir.path}\\package.appx')
          ..writeAsStringSync('store-digest');
        final List<int> bytes = file.readAsBytesSync();
        final String sha1Base64 = base64.encode(sha1.convert(bytes).bytes);
        final String sha256Base64 = base64.encode(sha256.convert(bytes).bytes);
        final sha256Hex = sha256.convert(bytes).toString();

        final service = PackageFileService(apiClient);

        expect(
          await service.verifyFileDigest(
            file: file,
            digest: sha1Base64,
            algorithm: 'SHA1',
          ),
          isTrue,
        );
        expect(
          await service.verifyFileDigest(
            file: file,
            digest: sha256Base64,
            algorithm: 'SHA256',
          ),
          isTrue,
        );
        expect(
          await service.verifyFileDigest(
            file: file,
            digest: sha256Hex,
            algorithm: 'SHA256',
          ),
          isTrue,
        );

        tempDir.deleteSync(recursive: true);
      },
    );
  });
}

final class _MockApiClient extends Mock implements ApiClient {}

Result<Response<dynamic>> _response({Object? data, int statusCode = 200}) {
  return Result<Response<dynamic>>.success(
    Response<dynamic>(
      requestOptions: RequestOptions(),
      statusCode: statusCode,
      data: data,
    ),
  );
}

Map<String, Object?> _uwpProductJson({String? wuCategoryId = 'category-id'}) {
  return <String, Object?>{
    'ExpiryUtc': DateTime.now()
        .add(const Duration(minutes: 5))
        .toIso8601String(),
    'Payload': <String, Object?>{
      'Skus': <Object?>[
        <String, Object?>{
          'SkuType': 'full',
          'FulfillmentData': jsonEncode(<String, Object?>{
            'WuCategoryId': wuCategoryId,
          }),
        },
      ],
    },
  };
}

final class _FakeStoreRepository extends StoreRepository {
  _FakeStoreRepository(this._packagesById)
    : super(api: _MockApiClient(), cache: StoreCache());

  final Map<String, Set<PackageInfo>> _packagesById;
  static const String _downloadUrl = 'https://example.test/package.appx';

  @override
  Future<Set<PackageInfo>> getPackages({
    required String productId,
    required StoreRing ring,
  }) async {
    return _packagesById[productId] ?? <PackageInfo>{};
  }

  @override
  Future<String> getPackageDownloadUrl({
    required PackageInfo package,
    required StoreRing ring,
  }) async {
    return package.uri.isEmpty ? _downloadUrl : package.uri;
  }
}

final class _FakeUwpXmlParser extends UwpXmlParser {
  @override
  Future<String> getTemplate(String name) async => name;

  @override
  String parseCookieResponse(String xmlString) => 'cookie';

  @override
  String parseDownloadUrl(String xmlString, [String? digest]) {
    return 'https://example.test/session.appx';
  }
}

/// Intercepts install calls without executing real processes.
final class _RecordingPackageFileService extends PackageFileService {
  _RecordingPackageFileService(super.api);

  final win32InstallPaths = <String>[];

  @override
  Future<bool> verifyFileDigest({
    required File file,
    required String digest,
    required String algorithm,
  }) async => true;

  @override
  Future<ProcessResult> runWin32Install(String path, List<String> args) async {
    win32InstallPaths.add(path);
    return ProcessResult(0, 0, '', '');
  }
}

UwpStoreRepository _uwpRepository(ApiClient apiClient) {
  return UwpStoreRepository(
    api: apiClient,
    cache: StoreCache(),
    xmlParser: const UwpXmlParser(),
  );
}

Win32StoreRepository _win32Repository(ApiClient apiClient) {
  return Win32StoreRepository(
    api: apiClient,
    cache: StoreCache(),
    xmlParser: const UwpXmlParser(),
  );
}

StoreService _service(
  ApiClient apiClient, {
  StoreRepository? uwpRepository,
  StoreRepository? win32Repository,
  PackageFileService? fileService,
}) => StoreService(
  uwpRepository:
      uwpRepository ?? _FakeStoreRepository(<String, Set<PackageInfo>>{}),
  win32Repository:
      win32Repository ?? _FakeStoreRepository(<String, Set<PackageInfo>>{}),
  fileService: fileService ?? PackageFileService(apiClient),
);

PackageInfo _sharedPackage({
  String id = 'package',
  String fileName = 'shared',
  required String digest,
  required int size,
}) {
  return PackageInfo(
    id: id,
    isDependency: true,
    uri: 'https://example.test/$fileName.appx',
    arch: 'x64',
    fileModel: FileModel(
      fileName: fileName,
      fileType: 'appx',
      digest: digest,
      digestAlgorithm: 'SHA256',
      size: size,
    ),
  );
}

PackageInfo _mainPackage({
  required String id,
  required String fileName,
  required String digest,
  required int size,
}) {
  return PackageInfo(
    id: id,
    isDependency: false,
    uri: 'https://example.test/$fileName.appx',
    arch: 'x64',
    fileModel: FileModel(
      fileName: fileName,
      fileType: 'appx',
      digest: digest,
      digestAlgorithm: 'SHA256',
      size: size,
    ),
  );
}

PackageInfo _win32Package() {
  return PackageInfo(
    id: 'XPTEST',
    isDependency: false,
    uri: 'https://example.test/app.exe',
    arch: 'x64',
    fileModel: const FileModel(
      fileName: 'app.exe',
      fileType: 'exe',
      digest: 'digest',
      digestAlgorithm: 'SHA256',
    ),
  );
}

const String _uwpPackageXml = '''
<Root>
  <SyncUpdatesResult>
    <ExtendedUpdateInfo>
      <Updates>
        <Update>
          <ID>update-id</ID>
          <Xml>
            <Files>
              <File FileName="package.appx" Digest="sha1-digest" DigestAlgorithm="SHA1" Size="10" Modified="2024-03-29T23:22:35.0330032Z" InstallerSpecificIdentifier="Microsoft.App_1.0.0.0_x64__test">
                <AdditionalDigest Algorithm="SHA256">sha256-digest</AdditionalDigest>
              </File>
            </Files>
            <ExtendedProperties IsAppxFramework="true" PackageIdentityName="Microsoft.App" />
          </Xml>
        </Update>
      </Updates>
    </ExtendedUpdateInfo>
    <NewUpdates>
      <UpdateInfo>
        <ID>update-id</ID>
        <Xml>
          <UpdateIdentity UpdateID="download-id" RevisionNumber="1" />
          <ApplicabilityRules>
            <Metadata>
              <AppxPackageMetadata>
                <AppxMetadata PackageMoniker="Microsoft.App_1.0.0.0_x64__test" />
              </AppxPackageMetadata>
            </Metadata>
          </ApplicabilityRules>
        </Xml>
      </UpdateInfo>
    </NewUpdates>
  </SyncUpdatesResult>
</Root>
''';

final Map<String, Object?> _win32ManifestJson = <String, Object?>{
  'Data': <String, Object?>{
    'Versions': <Object?>[
      <String, Object?>{
        'Installers': <Object?>[
          <String, Object?>{
            'InstallerSha256': 'FEEDFACE',
            'InstallerUrl': 'https://example.test/manifest.msi',
            'InstallerLocale': 'en-US',
            'InstallerSwitches': <String, Object?>{'Silent': '/silent'},
            'Architecture': 'x64',
            'InstallerType': 'msi',
          },
        ],
      },
    ],
  },
};

final Map<String, Object?> _win32DetailsJson = <String, Object?>{
  'productId': 'XPTEST',
  'installer': <String, Object?>{
    'architectures': <String, Object?>{
      'x64': <String, Object?>{
        'sourceUri': 'https://example.test/app.exe',
        'args': '/quiet',
        'hash': 'ABCDEF',
      },
    },
  },
};
