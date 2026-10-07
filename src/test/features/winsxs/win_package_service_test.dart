import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/error/result.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/features/winsxs/winsxs.dart';

class MockWinPackageRepository() extends Mock implements WinPackageRepository;

void main() {
  setUpAll(() {
    registerFallbackValue(const CabAsset(name: '', downloadUrl: ''));
    registerFallbackValue(WinPackageType.systemComponentsRemoval);
  });
  group('win_package versions', () {
    test('parses the version after the final double separator', () {
      expect(
        parsePackageVersion('Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~1.0.0.0'),
        equals((1, 0, 0, 0)),
      );
    });

    test('rejects package names without a four-part version', () {
      expect(parsePackageVersion('Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~1.0'), isNull);
    });

    test('compares version components numerically', () {
      expect(comparePackageVersions((1, 10, 0, 0), (1, 2, 0, 0)), greaterThan(0));
      expect(comparePackageVersions((1, 0, 0, 0), (1, 0, 0, 0)), equals(0));
    });
  });

  group('ReleaseModel', () {
    test('maps the release payload to domain entities', () {
      final model = ReleaseModel.fromJson(<String, dynamic>{
        'tag_name': '10.0.26200.6725',
        'assets': [
          {
            'name': 'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab',
            'browser_download_url': 'https://example.com/ai.cab',
          },
        ],
      });

      final WinPackageRelease release = model.toDomain();

      expect(release.tagName, equals('10.0.26200.6725'));
      expect(release.assets, hasLength(1));
      expect(
        release.assets.first.name,
        equals('Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab'),
      );
      expect(release.assets.first.downloadUrl, equals('https://example.com/ai.cab'));
    });
  });

  group('WinSxS asset matching', () {
    test('selects the telemetry removal cab on amd64', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-Telemetry-Removal.31bf3856ad364e35.amd64.2.4.0.0.cab',
          .telemetryRemoval,
          'amd64',
        ),
        isTrue,
      );
    });

    test('selects the dot-named cab for ai-removal on amd64', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.3.1.0.cab',
          .aiRemoval,
          'amd64',
        ),
        isTrue,
      );
    });

    test('rejects the txt checksum beside the cab', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.3.1.0.txt',
          .aiRemoval,
          'amd64',
        ),
        isFalse,
      );
    });

    test('rejects other architectures and packages', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal.31bf3856ad364e35.arm64.2.3.1.0.cab',
          .aiRemoval,
          'amd64',
        ),
        isFalse,
      );
      expect(
        isWinPackageFile(
          'Revision-ReviOS-Defender-Removal.31bf3856ad364e35.amd64.2.3.1.0.cab',
          .aiRemoval,
          'amd64',
        ),
        isFalse,
      );
    });

    test('keeps accepting legacy tilde-named cabs', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab',
          .aiRemoval,
          'amd64',
        ),
        isTrue,
      );
    });

    test('parses versions from dot-named bundled files', () {
      expect(
        parsePackageVersion('Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.3.1.0'),
        equals((2, 3, 1, 0)),
      );
    });
  });

  group('WinPackageService.install', () {
    late MockWinPackageRepository repository;
    late SystemPackagesRemovalService service;

    final releaseModel = ReleaseModel.fromJson(<String, dynamic>{
      'tag_name': '2.3.1.0',
      'assets': [
        {
          'name':
              'Revision-ReviOS-SystemPackages-Removal.31bf3856ad364e35.${WinRegistryService.cpuArch}.2.3.1.0.cab',
          'browser_download_url': 'https://example.com/system.cab',
        },
      ],
    });

    setUp(() {
      repository = MockWinPackageRepository();
      service = SystemPackagesRemovalService(repository: repository);

      when(() => repository.ensureDirectory(any())).thenReturn(null);
      when(() => repository.fetchRelease()).thenAnswer((_) async => releaseModel);
      when(
        () => repository.downloadAsset(
          asset: any(named: 'asset'),
          filePath: any(named: 'filePath'),
        ),
      ).thenAnswer((_) async {});
      when(() => repository.fileExists(any())).thenReturn(true);
      when(() => repository.fetchSignatureUsage(any()))
          .thenAnswer((_) async => '1.3.6.1.4.1.311.10.3.6');
      when(() => repository.addPackage(any())).thenAnswer((_) async {});
      when(() => repository.removePackageByName(any())).thenAnswer((_) async {});
      when(() => repository.deleteTempPackage(any())).thenReturn(null);
    });

    test('does not remove anything when no packages are installed', () async {
      when(() => repository.fetchInstalledPackageNames(.systemComponentsRemoval))
          .thenAnswer((_) async => const <String>[].lock);

      final Result<void> result = await service.install();

      expect(result, isA<Success<void>>());
      verify(() => repository.addPackage(any())).called(1);
      verifyNever(() => repository.removePackageByName(any()));
    });

    test('removes only older packages by exact CBS name', () async {
      const olderName = 'Revision-ReviOS-SystemPackages-Removal~31bf3856ad364e35~amd64~~2.3.0.0';
      when(() => repository.fetchInstalledPackageNames(.systemComponentsRemoval))
          .thenAnswer((_) async => <String>[olderName].lock);

      final Result<void> result = await service.install();

      expect(result, isA<Success<void>>());
      verify(() => repository.addPackage(any())).called(1);
      verify(() => repository.removePackageByName(olderName)).called(1);
    });

    test('does not remove anything when force reinstalling same version', () async {
      const sameName = 'Revision-ReviOS-SystemPackages-Removal~31bf3856ad364e35~amd64~~2.3.1.0';
      when(() => repository.fetchInstalledPackageNames(.systemComponentsRemoval))
          .thenAnswer((_) async => <String>[sameName].lock);

      await expectLater(service.install(force: true), completion(isA<Success<void>>()));
      verify(() => repository.addPackage(any())).called(1);
      verifyNever(() => repository.removePackageByName(any()));
    });
  });

  group('WinPackageService.uninstall', () {
    late MockWinPackageRepository repository;
    late SystemPackagesRemovalService service;

    setUp(() {
      repository = MockWinPackageRepository();
      service = SystemPackagesRemovalService(repository: repository);
      when(() => repository.removePackages(any())).thenAnswer((_) async {});
    });

    test('calls repository.removePackages with package type', () async {
      await expectLater(service.uninstall(), completion(isA<Success<void>>()));

      verify(() => repository.removePackages(.systemComponentsRemoval)).called(1);
    });
  });
}
