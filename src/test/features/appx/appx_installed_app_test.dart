import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/error/result.dart';
import 'package:revitool/features/appx/appx.dart';

import '../../helpers/fake_appx_repository.dart';

const PackageIdentityModel _vclibsRow = PackageIdentityModel(
  fullName: 'Microsoft.VCLibs.140.00_14.0.33519.0_x64__8wekyb3d8bbwe',
  name: 'Microsoft.VCLibs.140.00',
  familyName: 'Microsoft.WindowsCalculator_8wekyb3d8bbwe',
  publisherId: '8wekyb3d8bbwe',
  isFramework: true,
);

const String _calculatorFamily = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe';
const String _calculatorAppId = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe!App';

void main() {
  group('AppxService.findInstalled', () {
    test('returns the app installed for the current user', () async {
      final service = AppxService(
        repository: FakeAppxRepository(currentUserRows: const [calculatorRow]),
      );

      final Result<AppxPackage?> result = await service.findInstalled(
        familyName: _calculatorFamily,
      );

      expect(
        result,
        isA<Success<AppxPackage?>>().having(
          (s) => s.value?.fullName,
          'fullName',
          calculatorRow.fullName,
        ),
      );
    });

    test('skips frameworks', () async {
      final service = AppxService(
        repository: FakeAppxRepository(currentUserRows: const [_vclibsRow]),
      );

      final Result<AppxPackage?> result = await service.findInstalled(
        familyName: _calculatorFamily,
      );

      expect(result, isA<Success<AppxPackage?>>().having((s) => s.value, 'value', isNull));
    });

    test('returns null when the family is not installed', () async {
      final service = AppxService(repository: FakeAppxRepository());

      final Result<AppxPackage?> result = await service.findInstalled(
        familyName: _calculatorFamily,
      );

      expect(result, isA<Success<AppxPackage?>>().having((s) => s.value, 'value', isNull));
    });
  });

  group('AppxService.launch', () {
    test('starts the first app of the package', () async {
      final repository = FakeAppxRepository(
        currentUserRows: const [calculatorRow],
        appIds: const [_calculatorAppId, 'Microsoft.WindowsCalculator_8wekyb3d8bbwe!Other'],
      );
      final service = AppxService(repository: repository);

      final Result<void> result = await service.launch(familyName: _calculatorFamily);

      expect(result, isA<Success<void>>());
      expect(repository.launchedAppIds, [_calculatorAppId]);
    });

    test('fails when the package has no app', () async {
      final repository = FakeAppxRepository(currentUserRows: const [calculatorRow]);
      final service = AppxService(repository: repository);

      final Result<void> result = await service.launch(familyName: _calculatorFamily);

      expect(result, isA<Failure<void>>());
      expect(repository.launchedAppIds, isEmpty);
    });

    test('fails when the app is not installed', () async {
      final repository = FakeAppxRepository(appIds: const [_calculatorAppId]);
      final service = AppxService(repository: repository);

      final Result<void> result = await service.launch(familyName: _calculatorFamily);

      expect(result, isA<Failure<void>>());
      expect(repository.launchedAppIds, isEmpty);
    });
  });

  group('AppxService.uninstall', () {
    test('removes the package for the current user only', () async {
      final repository = FakeAppxRepository(currentUserRows: const [calculatorRow]);
      final service = AppxService(repository: repository);

      final Result<AppxRemovalResult> result = await service.uninstall(
        familyName: _calculatorFamily,
      );

      expect(result, isA<Success<AppxRemovalResult>>());
      expect(repository.removedFullNames, [calculatorRow.fullName]);
      expect(repository.allUsersCalls, [false]);
      expect(repository.markedDeprovisioned, isEmpty, reason: 'the app can be installed again');
    });

    test('fails when deployment refuses the removal', () async {
      final repository = FakeAppxRepository(
        currentUserRows: const [calculatorRow],
        outcome: const RemovalOutcomeModel(
          identifier: 'x',
          extendedErrorCode: 0x80073CFA,
          errorText: 'Removal failed',
        ),
      );
      final service = AppxService(repository: repository);

      final Result<AppxRemovalResult> result = await service.uninstall(
        familyName: _calculatorFamily,
      );

      expect(result, isA<Failure<AppxRemovalResult>>());
    });

    test('fails without removing anything when the app is not installed', () async {
      final repository = FakeAppxRepository();
      final service = AppxService(repository: repository);

      final Result<AppxRemovalResult> result = await service.uninstall(
        familyName: _calculatorFamily,
      );

      expect(result, isA<Failure<AppxRemovalResult>>());
      expect(repository.removedFullNames, isEmpty);
    });
  });
}
