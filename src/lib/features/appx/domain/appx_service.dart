import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/base_service.dart';
import '../../../utils.dart';
import '../data/appx_repository.dart';
import 'appx_exceptions.dart';
import 'entities/appx_package.dart';

/// Manages AppX packages through the native bridge and Windows registry.
final class const AppxService({required final AppxRepository repository}) with BaseService {
  @override
  ErrorMapper get errorMapper => (error, stackTrace) {
    if (error is AppException) return error;
    if (error is AppxException) {
      return UnexpectedNetworkException(message: error.message, cause: error);
    }
    return UnexpectedNetworkException(cause: error);
  };

  @override
  String get logTag => 'AppxService';

  /// Lists all packages installed for any user.
  Future<Result<IList<AppxPackage>>> listPackages() => run(() async {
    final List<PackageIdentityModel> rows = await repository.listPackages();
    return rows.map((r) => r.toDomain(installed: true)).toIList();
  });

  /// Lists machine-wide provisioned packages.
  Future<Result<IList<AppxPackage>>> listProvisionedPackages() => run(() async {
    final List<PackageIdentityModel> rows = await repository.listProvisionedPackages();
    return rows.map((r) => r.toDomain(installed: false)).toIList();
  });

  /// Lists removable users for [fullName].
  Future<Result<IList<AppxPackageUser>>> findUsers({required String fullName}) => run(() async {
    final List<PackageUserStateModel> rows = await repository.findUsers(fullName: fullName);
    return removableAppxUsers(rows.map((r) => r.toDomain()).toIList());
  });

  /// Removes all installed packages matching [prefixes], excluding [exclude].
  ///
  /// Matches against package full names or bare names starting with any of [prefixes].
  Future<Result<IList<AppxRemovalResult>>> removePackages({
    required Set<String> prefixes,
    Set<String> exclude = const {},
    bool allUsers = false,
    bool preserveRoaming = false,
  }) => run(() async {
    // Windows rejects preserveRoaming with allUsers; preserveRoaming applies per-user.
    final Set<String> cleanPrefixes = prefixes
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    if (cleanPrefixes.isEmpty) return const <AppxRemovalResult>[].toIList();

    final List<PackageIdentityModel> allPackages = await repository.listPackages();
    final Set<String> cleanExclude = exclude
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final IList<PackageIdentityModel> targets = allPackages.where((p) {
      final String bare = appxBareName(p.fullName);
      final bool matches = cleanPrefixes.any(
        (prefix) => p.fullName.startsWith(prefix) || bare.startsWith(prefix),
      );
      if (!matches) return false;
      final bool isExcluded = cleanExclude.any(
        (ex) => p.fullName.startsWith(ex) || bare.startsWith(ex),
      );
      return !isExcluded;
    }).toIList();

    return [
      for (final package in targets)
        await _removePackage(
          fullName: package.fullName,
          allUsers: allUsers,
          preserveRoaming: preserveRoaming,
        ),
    ].toIList();
  });

  /// Runs the removal pipeline for [fullName].
  Future<AppxRemovalResult> _removePackage({
    required String fullName,
    bool allUsers = false,
    bool preserveRoaming = false,
  }) async {
    if (await _familyOf(fullName) case final familyName?) {
      await _markDeprovisioned(familyName);
      if (allUsers) {
        await _deprovision(familyName);
      }
    }

    await _removeInboxApp(fullName);

    if (preserveRoaming) {
      final RemovalOutcomeModel outcome = await repository.removePackage(
        fullName: fullName,
        allUsers: allUsers,
        preserveRoamable: true,
      );
      return _accepted(outcome);
    }

    // Attempt 1: Standard removal.
    RemovalOutcomeModel outcome = await repository.removePackage(
      fullName: fullName,
      allUsers: allUsers,
    );
    if (_isSuccess(outcome)) return outcome.toDomain();

    // Attempt 2: Mark EndOfLife keys for system packages and retry.
    final bool eolMarked = await _markEndOfLife(fullName);
    if (eolMarked) {
      outcome = await repository.removePackage(fullName: fullName, allUsers: allUsers);
      if (_isSuccess(outcome)) return outcome.toDomain();
    }

    // Attempt 3: Guaranteed unregistration fallback (preserveRoamable requires per-user).
    if (!allUsers) {
      outcome = await repository.removePackage(fullName: fullName, preserveRoamable: true);
      if (_isSuccess(outcome)) return outcome.toDomain();
    }

    return _accepted(outcome);
  }

  /// Deprovisions [familyName] machine-wide if supported.
  Future<void> _deprovision(String familyName) async {
    try {
      await repository.deprovision(familyName: familyName);
    } on Object catch (error) {
      logger.w('[AppX] Could not deprovision $familyName', error: error);
    }
  }

  /// Finds the package family of [fullName], if installed.
  Future<String?> _familyOf(String fullName) async {
    final List<PackageIdentityModel> rows = await repository.listPackages();
    for (final row in rows) {
      if (row.fullName == fullName) return row.familyName;
    }
    return null;
  }

  /// Writes the `Deprovisioned` key for [familyName].
  Future<void> _markDeprovisioned(String familyName) async {
    try {
      await repository.markDeprovisioned(familyName: familyName);
    } on AppxStoreKeysException {
      rethrow;
    } on Object catch (error) {
      throw AppxStoreKeysException('Could not mark $familyName deprovisioned', error);
    }
  }

  /// Removes the `InboxApplications` key for [fullName] if present.
  Future<void> _removeInboxApp(String fullName) async {
    try {
      await repository.removeInboxApplication(fullName: fullName);
    } on Object catch (error) {
      logger.w('[AppX] Could not remove InboxApplications for $fullName', error: error);
    }
  }

  /// Marks [fullName] as end-of-life for all removable users.
  Future<bool> _markEndOfLife(String fullName) async {
    final List<PackageUserStateModel> rows = await repository.findUsers(fullName: fullName);
    final IList<AppxPackageUser> users = removableAppxUsers(
      rows.map((r) => r.toDomain()).toIList(),
    );
    if (users.isEmpty) return false;
    for (final user in users) {
      try {
        await repository.markEndOfLife(sid: user.sid, fullName: fullName);
      } on AppxStoreKeysException {
        rethrow;
      } on Object catch (error) {
        throw AppxStoreKeysException('Could not mark $fullName end-of-life for ${user.sid}', error);
      }
    }
    return true;
  }

  static bool _isSuccess(RemovalOutcomeModel outcome) =>
      outcome.extendedErrorCode == 0 && outcome.errorText.isEmpty;

  /// Throws [AppxRemovalRefusedException] if [outcome] reports an error.
  static AppxRemovalResult _accepted(RemovalOutcomeModel outcome) {
    final AppxRemovalResult result = outcome.toDomain();
    if (result.extendedErrorCode != 0 || result.errorText.isNotEmpty) {
      throw AppxRemovalRefusedException(result);
    }
    return result;
  }
}
