import 'package:revitool/features/appx/appx.dart';

const RemovalOutcomeModel acceptedOutcome = RemovalOutcomeModel(
  identifier: 'x',
  extendedErrorCode: 0,
  errorText: '',
);

const PackageIdentityModel desktopInstallerRow = PackageIdentityModel(
  fullName: 'Microsoft.DesktopAppInstaller_2026.917.151.0_neutral_~_8wekyb3d8bbwe',
  name: 'Microsoft.DesktopAppInstaller',
  familyName: 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe',
  publisherId: '8wekyb3d8bbwe',
  isFramework: false,
);

const PackageIdentityModel copilotRow = PackageIdentityModel(
  fullName: 'Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe',
  name: 'Microsoft.Copilot',
  familyName: 'Microsoft.Copilot_8wekyb3d8bbwe',
  publisherId: '8wekyb3d8bbwe',
  isFramework: false,
);

const PackageIdentityModel calculatorRow = PackageIdentityModel(
  fullName: 'Microsoft.WindowsCalculator_1.0.0.0_x64__8wekyb3d8bbwe',
  name: 'Microsoft.WindowsCalculator',
  familyName: 'Microsoft.WindowsCalculator_8wekyb3d8bbwe',
  publisherId: '8wekyb3d8bbwe',
  isFramework: false,
);

/// An [AppxRepository] that records what it was asked to remove and mark.
final class FakeAppxRepository({
  final List<PackageIdentityModel> rows = const [],
  final List<PackageUserStateModel> users = const [],
  final RemovalOutcomeModel outcome = acceptedOutcome,
  final List<RemovalOutcomeModel>? outcomes,
  final Exception? bridgeError,
  final Exception? readError,
  final Exception? storeKeyError,
}) implements AppxRepository {
  final List<String> removedFullNames = [];
  final List<bool> preserveRoamingCalls = [];
  final List<bool> allUsersCalls = [];
  final List<String> markedSids = [];
  final List<String> markedFullNames = [];
  final List<String> markedDeprovisioned = [];
  final List<String> removedInboxApps = [];
  final List<Set<String>> scheduledRunOnce = [];
  int _outcomeIndex = 0;

  @override
  Future<void> loadBridge() async {
    if (bridgeError case final Exception error) {
      throw AppxBridgeUnavailableException(error);
    }
  }

  @override
  Future<List<PackageIdentityModel>> listPackages() async {
    await loadBridge();
    if (readError case final Exception error) throw error;
    return rows;
  }

  @override
  Future<List<PackageIdentityModel>> listProvisionedPackages() => listPackages();

  @override
  Future<List<PackageUserStateModel>> findUsers({required String fullName}) async {
    await loadBridge();
    if (readError case final Exception error) throw error;
    return users;
  }

  @override
  Future<RemovalOutcomeModel> removePackage({
    required String fullName,
    bool allUsers = false,
    bool preserveRoamable = false,
  }) async {
    await loadBridge();
    removedFullNames.add(fullName);
    preserveRoamingCalls.add(preserveRoamable);
    allUsersCalls.add(allUsers);
    if (outcomes != null && _outcomeIndex < outcomes!.length) {
      return outcomes![_outcomeIndex++];
    }
    return outcome;
  }

  @override
  Future<RemovalOutcomeModel> deprovision({required String familyName}) async {
    await loadBridge();
    return outcome;
  }

  @override
  Future<void> markDeprovisioned({required String familyName}) async {
    if (storeKeyError case final Exception e) throw e;
    markedDeprovisioned.add(familyName);
  }

  @override
  Future<void> markEndOfLife({required String sid, required String fullName}) async {
    if (storeKeyError case final Exception e) throw e;
    markedSids.add(sid);
    markedFullNames.add(fullName);
  }

  @override
  Future<void> removeInboxApplication({required String fullName}) async {
    if (storeKeyError case final Exception e) throw e;
    removedInboxApps.add(fullName);
  }

  @override
  Future<bool> hasInboxApplication({required String fullName}) async =>
      removedInboxApps.contains(fullName);

  @override
  Future<void> scheduleRunOnce({
    required Set<String> fullNames,
    bool allUsers = false,
  }) async {
    scheduledRunOnce.add(fullNames);
  }
}

/// Stands in for the loader error a missing `revitool_native.dll` produces.
// The class needs no constructor, so there is nothing to promote.
// ignore: use_primary_constructors
final class FakeBridgeMissing implements Exception {
  @override
  String toString() => 'Invalid argument(s): Failed to load dynamic library';
}

/// Stands in for a bridge read that rejected.
// The class needs no constructor, so there is nothing to promote.
// ignore: use_primary_constructors
final class FakeReadFailed implements Exception {
  @override
  String toString() => 'Invalid argument(s): FindPackages';
}
