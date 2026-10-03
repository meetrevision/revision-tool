import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/error/app_exception.dart';
import 'package:revitool/core/error/result.dart';
import 'package:revitool/features/appx/appx.dart';

import '../../helpers/fake_appx_repository.dart';

void main() {
  group('appxBareName', () {
    test('drops the version and publisher', () {
      expect(
        appxBareName('Microsoft.XboxGamingOverlay_1.0.0.0_x64__cw5n1h2txyewy'),
        equals('Microsoft.XboxGamingOverlay'),
      );
    });
  });

  group('removableAppxUsers', () {
    test('drops the service accounts and the null SID', () {
      final IList<AppxPackageUser> users = <AppxPackageUser>[
        const AppxPackageUser(sid: 'S-1-5-18', installState: InstallStateModel.installed()),
        const AppxPackageUser(sid: 'S-1-0-0', installState: InstallStateModel.installed()),
        const AppxPackageUser(sid: 'S-1-5-21-1234', installState: InstallStateModel.paused()),
        const AppxPackageUser(sid: 'S-1-5-19', installState: InstallStateModel.notInstalled()),
      ].toIList();

      expect(
        removableAppxUsers(users).map((u) => u.sid),
        equals(['S-1-5-21-1234']),
        reason: 'S-1-0-0 is what Windows reports for a package registered with no user',
      );
    });
  });

  group('AppxService', () {
    test('maps a bridge row onto a domain package', () async {
      final service = AppxService(
        repository: FakeAppxRepository(rows: const [desktopInstallerRow]),
      );

      final IList<AppxPackage> packages =
          (await service.listPackages() as Success<IList<AppxPackage>>).value;

      expect(
        packages.single,
        isA<AppxPackage>()
            .having((p) => p.fullName, 'fullName', desktopInstallerRow.fullName)
            .having((p) => p.familyName, 'familyName', desktopInstallerRow.familyName)
            .having((p) => p.installed, 'installed', isTrue),
      );
    });

    test('marks a provisioned package as not installed', () async {
      final service = AppxService(
        repository: FakeAppxRepository(rows: const [desktopInstallerRow]),
      );

      final IList<AppxPackage> packages =
          (await service.listProvisionedPackages() as Success<IList<AppxPackage>>).value;

      expect(packages.single.installed, isFalse);
    });

    test('filters the non-removable SIDs out of findUsers', () async {
      final service = AppxService(
        repository: FakeAppxRepository(
          users: const [
            PackageUserStateModel(sid: 'S-1-5-18', installState: InstallStateModel.installed()),
            PackageUserStateModel(sid: 'S-1-0-0', installState: InstallStateModel.installed()),
            PackageUserStateModel(
              sid: 'S-1-5-21-1000-2000-3000-1001',
              installState: InstallStateModel.paused(),
            ),
          ],
        ),
      );

      final IList<AppxPackageUser> users = (await service.findUsers(
        fullName: desktopInstallerRow.fullName,
      ) as Success<IList<AppxPackageUser>>).value;

      expect(users.map((u) => u.sid), equals(['S-1-5-21-1000-2000-3000-1001']));
      expect(users.single.installState, const InstallStateModel.paused());
    });

    test('reports read failure as a Failure result', () async {
      final service = AppxService(repository: FakeAppxRepository(readError: FakeReadFailed()));

      final Result<IList<AppxPackage>> result = await service.listPackages();
      expect(result, isA<Failure<IList<AppxPackage>>>());
      final AppException failure = (result as Failure<IList<AppxPackage>>).exception;

      expect(failure.cause, isA<FakeReadFailed>());
    });

    test('turns a zero code with refusal text into a failure when all attempts fail', () async {
      final service = AppxService(
        repository: FakeAppxRepository(
          rows: const [
            PackageIdentityModel(
              fullName: 'Microsoft.Nope_1.0.0.0_x64__abc',
              name: 'Microsoft.Nope',
              familyName: 'Microsoft.Nope_abc',
              publisherId: 'abc',
              isFramework: false,
            ),
          ],
          outcome: const RemovalOutcomeModel(
            identifier: 'Microsoft.Nope_1.0.0.0_x64__abc',
            extendedErrorCode: 0,
            errorText: 'Package was not found.',
          ),
        ),
      );

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft.Nope_1.0.0.0_x64__abc'},
      );
      final AppException failure = (result as Failure<IList<AppxRemovalResult>>).exception;

      expect(failure.message, contains('Package was not found.'));
      expect(appxCause(failure), isA<AppxRemovalRefusedException>());
    });

    test('surfaces the HRESULT on a refusal when all attempts fail', () async {
      final service = AppxService(
        repository: FakeAppxRepository(
          rows: const [
            PackageIdentityModel(
              fullName: 'Microsoft.Nope_1.0.0.0_x64__abc',
              name: 'Microsoft.Nope',
              familyName: 'Microsoft.Nope_abc',
              publisherId: 'abc',
              isFramework: false,
            ),
          ],
          outcome: const RemovalOutcomeModel(
            identifier: 'Microsoft.Nope_1.0.0.0_x64__abc',
            extendedErrorCode: 0x80073CFA,
            errorText: 'Operation cancelled by the user.',
          ),
        ),
      );

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft.Nope'},
        allUsers: true,
      );
      final AppException failure = (result as Failure<IList<AppxRemovalResult>>).exception;
      final refused = appxCause(failure)! as AppxRemovalRefusedException;

      expect(refused.result.extendedErrorCode, equals(0x80073CFA));
    });

    test('reports a missing bridge without throwing out of the Result', () async {
      final service = AppxService(repository: FakeAppxRepository(bridgeError: FakeBridgeMissing()));

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: {desktopInstallerRow.fullName},
      );
      final AppException failure = (result as Failure<IList<AppxRemovalResult>>).exception;

      expect(failure.message, contains('native bridge could not be loaded'));
      expect(appxCause(failure), isA<AppxBridgeUnavailableException>());
    });
  });

  group('Removal pipeline', () {
    test('succeeds on standard removal without marking EOL keys', () async {
      final repository = FakeAppxRepository(rows: const [desktopInstallerRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: {desktopInstallerRow.fullName},
        allUsers: true,
      );

      expect(result, isA<Success<IList<AppxRemovalResult>>>());
      expect(repository.markedDeprovisioned, [desktopInstallerRow.familyName]);
      expect(repository.removedInboxApps, [desktopInstallerRow.fullName]);
      expect(repository.markedSids, isEmpty);
      expect(repository.removedFullNames, [desktopInstallerRow.fullName]);
    });

    test('preserves roaming directly without EOL when preserveRoaming is true', () async {
      final repository = FakeAppxRepository(rows: const [desktopInstallerRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: {desktopInstallerRow.fullName},
        preserveRoaming: true,
      );

      expect(result, isA<Success<IList<AppxRemovalResult>>>());
      expect(repository.markedDeprovisioned, [desktopInstallerRow.familyName]);
      expect(repository.removedInboxApps, [desktopInstallerRow.fullName]);
      expect(repository.markedSids, isEmpty);
      expect(repository.preserveRoamingCalls, [true]);
    });

    test('applies EndOfLife trick when standard removal is refused, then retries', () async {
      const refusedOutcome = RemovalOutcomeModel(
        identifier: 'x',
        extendedErrorCode: 0x80073CFA,
        errorText: 'System package removal failed',
      );
      final repository = FakeAppxRepository(
        rows: const [desktopInstallerRow],
        users: const [
          PackageUserStateModel(
            sid: 'S-1-5-21-1000-2000-3000-1001',
            installState: InstallStateModel.installed(),
          ),
        ],
        outcomes: const [refusedOutcome, acceptedOutcome],
      );
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: {desktopInstallerRow.fullName},
        allUsers: true,
      );

      expect(result, isA<Success<IList<AppxRemovalResult>>>());
      expect(repository.markedSids, ['S-1-5-21-1000-2000-3000-1001']);
      expect(repository.markedFullNames, [desktopInstallerRow.fullName]);
      expect(repository.removedFullNames, hasLength(2));
    });

    test('falls back to preserveRoamable when standard and EOL both refuse', () async {
      const refusedOutcome = RemovalOutcomeModel(
        identifier: 'x',
        extendedErrorCode: 0x80073CFA,
        errorText: 'Package in use',
      );
      final repository = FakeAppxRepository(
        rows: const [desktopInstallerRow],
        users: const [
          PackageUserStateModel(
            sid: 'S-1-5-21-1000-2000-3000-1001',
            installState: InstallStateModel.installed(),
          ),
        ],
        outcomes: const [refusedOutcome, refusedOutcome, acceptedOutcome],
      );
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: {desktopInstallerRow.fullName},
      );

      expect(result, isA<Success<IList<AppxRemovalResult>>>());
      expect(repository.preserveRoamingCalls, [false, false, true]);
    });

    test('fails without removing when marking deprovisioned throws', () async {
      final repository = FakeAppxRepository(
        rows: const [desktopInstallerRow],
        storeKeyError: FakeReadFailed(),
      );
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: {desktopInstallerRow.fullName},
        allUsers: true,
      );
      final AppException failure = (result as Failure<IList<AppxRemovalResult>>).exception;

      expect(appxCause(failure), isA<AppxStoreKeysException>());
      expect(repository.removedFullNames, isEmpty);
    });
  });

  group('removePackages', () {
    test('removes all packages matching prefixes and leaves the rest alone', () async {
      final repository = FakeAppxRepository(rows: const [copilotRow, calculatorRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft.Copilot'},
        preserveRoaming: true,
      );

      final IList<AppxRemovalResult> removed = (result as Success<IList<AppxRemovalResult>>).value;
      expect(removed, hasLength(1));
      expect(repository.removedFullNames, [copilotRow.fullName]);
      expect(repository.preserveRoamingCalls, [true]);
    });

    test('removes for every user when asked', () async {
      final repository = FakeAppxRepository(rows: const [copilotRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft.Copilot'},
        allUsers: true,
      );

      expect(result, isA<Success<IList<AppxRemovalResult>>>());
      expect(repository.allUsersCalls, [true]);
    });

    test('excludes packages matching exclude patterns', () async {
      final repository = FakeAppxRepository(rows: const [copilotRow, calculatorRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft'},
        exclude: const {'Microsoft.WindowsCalculator'},
      );

      final IList<AppxRemovalResult> removed = (result as Success<IList<AppxRemovalResult>>).value;
      expect(removed, hasLength(1));
      expect(repository.removedFullNames, [copilotRow.fullName]);
    });

    test('returns empty list when no packages match prefixes', () async {
      final repository = FakeAppxRepository(rows: const [calculatorRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft.Copilot'},
      );

      final IList<AppxRemovalResult> removed = (result as Success<IList<AppxRemovalResult>>).value;
      expect(removed, isEmpty);
      expect(repository.removedFullNames, isEmpty);
    });

    test('returns empty list immediately when prefixes set is empty', () async {
      final repository = FakeAppxRepository(rows: const [copilotRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {},
      );

      final IList<AppxRemovalResult> removed = (result as Success<IList<AppxRemovalResult>>).value;
      expect(removed, isEmpty);
      expect(repository.removedFullNames, isEmpty);
    });

    test('does not duplicate removal when multiple prefixes match same package', () async {
      final repository = FakeAppxRepository(rows: const [copilotRow]);
      final service = AppxService(repository: repository);

      final Result<IList<AppxRemovalResult>> result = await service.removePackages(
        prefixes: const {'Microsoft', 'Microsoft.Copilot'},
      );

      final IList<AppxRemovalResult> removed = (result as Success<IList<AppxRemovalResult>>).value;
      expect(removed, hasLength(1));
      expect(repository.removedFullNames, [copilotRow.fullName]);
    });

    test('does not pass preserveRoamable when allUsers is true', () async {
      const failedOutcome = RemovalOutcomeModel(
        identifier: 'fail',
        extendedErrorCode: 0x80073CFA,
        errorText: 'System package removal failed',
      );
      final repository = FakeAppxRepository(
        rows: const [desktopInstallerRow],
        users: const [
          PackageUserStateModel(
            sid: 'S-1-5-21-1000-2000-3000-1001',
            installState: InstallStateModel.installed(),
          ),
        ],
        outcomes: const [failedOutcome, failedOutcome],
      );
      final service = AppxService(repository: repository);

      await service.removePackages(prefixes: {desktopInstallerRow.fullName}, allUsers: true);

      expect(repository.preserveRoamingCalls, isNot(contains(true)));
    });
  });
}
