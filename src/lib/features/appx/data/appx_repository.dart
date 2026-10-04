import 'dart:io';

import 'package:revitool_native/revitool_native.dart' as bridge;
import 'package:win32_registry/win32_registry.dart';

import '../../../core/services/win_registry_service.dart';
import '../domain/appx_exceptions.dart';

/// Package row reported by the native bridge.
typedef PackageIdentityModel = bridge.PackageIdentity;

/// User relationship with a package reported by the native bridge.
typedef PackageUserStateModel = bridge.PackageUserState;

/// Raw outcome of a package removal or deprovisioning request.
typedef RemovalOutcomeModel = bridge.RemovalOutcome;

/// Package registration progress for a user.
typedef InstallStateModel = bridge.InstallState;

/// Accesses AppX packages and manages store registry keys.
abstract interface class AppxRepository() {
  /// Loads the native bridge library.
  Future<void> loadBridge();

  /// Lists all packages installed for any user.
  Future<List<PackageIdentityModel>> listPackages();

  /// Lists packages provisioned machine-wide.
  Future<List<PackageIdentityModel>> listProvisionedPackages();

  /// Lists all users associated with [fullName].
  Future<List<PackageUserStateModel>> findUsers({required String fullName});

  /// Removes [fullName] for the current user or all users.
  Future<RemovalOutcomeModel> removePackage({
    required String fullName,
    bool allUsers = false,
    bool preserveRoamable = false,
  });

  /// Removes the provisioned package family [familyName].
  Future<RemovalOutcomeModel> deprovision({required String familyName});

  /// Creates the deprovisioned registry key for [familyName].
  Future<void> markDeprovisioned({required String familyName});

  /// Creates the end-of-life registry key for [fullName] under [sid].
  Future<void> markEndOfLife({required String sid, required String fullName});

  /// Removes the inbox application registry key for [fullName].
  Future<void> removeInboxApplication({required String fullName});

  /// Whether the inbox application registry key exists for [fullName].
  Future<bool> hasInboxApplication({required String fullName});

  /// Queues package removal to run once on the next reboot.
  ///
  /// Adds an entry to `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`
  /// with `--no-schedule-startup` so it will not try to queue itself again.
  Future<void> scheduleRunOnce({required Set<String> fullNames, bool allUsers = false});
}

final class NativeAppxRepository() implements AppxRepository {
  static const String _storeBase =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore';
  static const String _runOncePath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';
  static const String _runOnceValue = 'RevitoolAppxCleanup';

  // Cached initialization future.
  Future<void>? _init;

  @override
  Future<void> loadBridge() async {
    try {
      await (_init ??= bridge.RustLib.init());
    } on Object catch (error) {
      throw AppxBridgeUnavailableException(error);
    }
  }

  @override
  Future<List<PackageIdentityModel>> listPackages() async {
    await loadBridge();
    return bridge.listInstalled();
  }

  @override
  Future<List<PackageIdentityModel>> listProvisionedPackages() async {
    await loadBridge();
    return bridge.listProvisioned();
  }

  @override
  Future<List<PackageUserStateModel>> findUsers({required String fullName}) async {
    await loadBridge();
    return bridge.findUsers(fullName: fullName);
  }

  @override
  Future<RemovalOutcomeModel> removePackage({
    required String fullName,
    bool allUsers = false,
    bool preserveRoamable = false,
  }) async {
    await loadBridge();
    return bridge.removePackage(
      fullName: fullName,
      allUsers: allUsers,
      preserveRoamable: preserveRoamable,
    );
  }

  @override
  Future<RemovalOutcomeModel> deprovision({required String familyName}) async {
    await loadBridge();
    return bridge.deprovisionAllUsers(familyName: familyName);
  }

  @override
  Future<void> markDeprovisioned({required String familyName}) async {
    final path = '$_storeBase\\Deprovisioned\\$familyName';
    WinRegistryService.createKey(LOCAL_MACHINE, path);
    if (!WinRegistryService.keyExists(LOCAL_MACHINE, path)) {
      throw AppxStoreKeysException('Could not mark $familyName deprovisioned');
    }
  }

  @override
  Future<void> markEndOfLife({required String sid, required String fullName}) async {
    final path = '$_storeBase\\EndOfLife\\$sid\\$fullName';
    WinRegistryService.createKey(LOCAL_MACHINE, path);
    if (!WinRegistryService.keyExists(LOCAL_MACHINE, path)) {
      throw AppxStoreKeysException('Could not mark $fullName end-of-life for $sid');
    }
  }

  @override
  Future<void> removeInboxApplication({required String fullName}) async {
    final path = '$_storeBase\\InboxApplications\\$fullName';
    if (WinRegistryService.keyExists(LOCAL_MACHINE, path)) {
      await WinRegistryService.deleteKey(LOCAL_MACHINE, path, useTrustedInstaller: true);
    }
  }

  @override
  Future<bool> hasInboxApplication({required String fullName}) async {
    final path = '$_storeBase\\InboxApplications\\$fullName';
    return WinRegistryService.keyExists(LOCAL_MACHINE, path);
  }

  @override
  Future<void> scheduleRunOnce({required Set<String> fullNames, bool allUsers = false}) async {
    if (fullNames.isEmpty) return;
    final String exePath = Platform.resolvedExecutable;
    final allUsersFlag = allUsers ? ' --all-users' : '';
    final String namesArg = fullNames.join(',');
    final command =
        '"$exePath" appx$allUsersFlag --no-schedule-startup --remove "$namesArg"';
    await WinRegistryService.writeRegistryValue(
      LOCAL_MACHINE,
      _runOncePath,
      _runOnceValue,
      command,
    );
  }
}
