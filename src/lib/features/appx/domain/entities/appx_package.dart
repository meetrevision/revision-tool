import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../data/appx_repository.dart';

/// Installed or provisioned AppX package identity.
final class const AppxPackage({
  /// Full package identity (`Name.Version.Architecture_PublisherId`).
  required final String fullName,

  /// Package family name (`Name_PublisherId`).
  required final String familyName,

  /// Whether the package is currently installed for any user.
  required final bool installed,
});

/// User installation state for an AppX package.
final class const AppxPackageUser({
  /// Security identifier of the user account.
  required final String sid,

  /// Installation state for the user.
  required final InstallStateModel installState,
});

/// Outcome of an AppX removal or deprovisioning operation.
final class const AppxRemovalResult({
  /// Identifier of the targeted package or package family.
  required final String identifier,

  /// HRESULT or Win32 error code, zero on success.
  required final int extendedErrorCode,

  /// Error description returned by deployment operations.
  required final String errorText,
});

/// Converts [PackageIdentityModel] to [AppxPackage].
extension PackageIdentityModelMapper on PackageIdentityModel {
  AppxPackage toDomain({required bool installed}) =>
      AppxPackage(fullName: fullName, familyName: familyName, installed: installed);
}

/// Converts [PackageUserStateModel] to [AppxPackageUser].
extension PackageUserStateModelMapper on PackageUserStateModel {
  AppxPackageUser toDomain() => AppxPackageUser(sid: sid, installState: installState);
}

/// Converts [RemovalOutcomeModel] to [AppxRemovalResult].
extension RemovalOutcomeModelMapper on RemovalOutcomeModel {
  AppxRemovalResult toDomain() => AppxRemovalResult(
    identifier: identifier,
    extendedErrorCode: extendedErrorCode,
    errorText: errorText,
  );
}

/// Returns the bare package name from [fullName], stripping version and publisher.
String appxBareName(String fullName) => fullName.split('_').first;

// Service accounts and null SIDs excluded from per-user removals.
const Set<String> _nonRemovableSids = {'S-1-0-0', 'S-1-5-18', 'S-1-5-19', 'S-1-5-20'};

/// Whether [sid] corresponds to a removable user account.
bool isRemovableAppxSid(String sid) => !_nonRemovableSids.contains(sid);

/// Filters [users] to only removable user accounts.
IList<AppxPackageUser> removableAppxUsers(IList<AppxPackageUser> users) =>
    users.where((u) => isRemovableAppxSid(u.sid)).toIList();
