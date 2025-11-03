import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../shared/win_registry_service.dart';

part 'updates_service.g.dart';

/// Abstract interface for Windows Updates operations
abstract class WinUpdatesService {
  bool get statusPauseUpdatesWU;
  Future<void> enablePauseUpdatesWU();
  Future<void> disablePauseUpdatesWU();
  bool get statusVisibilityWU;
  Future<void> enableVisibilityWU();
  Future<void> disableVisibilityWU();
  bool get statusDriversWU;
  Future<void> enableDriversWU();
  Future<void> disableDriversWU();
}

/// Implementation of WinUpdatesService
class WinUpdatesServiceImpl implements WinUpdatesService {
  const WinUpdatesServiceImpl();

  @override
  bool get statusPauseUpdatesWU {
    return WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
          "PauseUpdatesExpiryTime",
        )?.contains("2038-01-19T03:14:07Z") ??
        false;
  }

  @override
  Future<void> enablePauseUpdatesWU() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "FlightSettingsMaxPauseDays",
        5269,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseFeatureUpdatesStartTime",
        "2023-08-17T12:47:51Z",
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseFeatureUpdatesEndTime",
        "2038-01-19T03:14:07Z",
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseQualityUpdatesStartTime",
        "2023-08-17T12:47:51Z",
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseQualityUpdatesEndTime",
        "2038-01-19T03:14:07Z",
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseUpdatesStartTime",
        "2023-08-17T12:47:51Z",
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseUpdatesExpiryTime",
        "2038-01-19T03:14:07Z",
      ),
    ]);
  }

  @override
  Future<void> disablePauseUpdatesWU() async {
    await Future.wait([
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'FlightSettingsMaxPauseDays',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseFeatureUpdatesStartTime',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseFeatureUpdatesEndTime',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseQualityUpdatesStartTime',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseQualityUpdatesEndTime',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseUpdatesStartTime',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseUpdatesExpiryTime',
      ),
    ]);
  }

  @override
  bool get statusVisibilityWU {
    return WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
        )?.contains("windowsupdate") ??
        false;
  }

  @override
  Future<void> enableVisibilityWU() async {
    await WinRegistryService.unhidePageVisibilitySettings("windowsupdate");
  }

  @override
  Future<void> disableVisibilityWU() async {
    await WinRegistryService.hidePageVisibilitySettings("windowsupdate");
  }

  @override
  bool get statusDriversWU {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
          'PreventDeviceMetadataFromNetwork',
        ) ==
        0;
  }

  @override
  Future<void> enableDriversWU() async {
    await Future.wait([
      WinRegistryService.deleteKey(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
      ),
      WinRegistryService.deleteKey(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        0,
      ),
    ]);
  }

  @override
  Future<void> disableDriversWU() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'SearchOrderConfig',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1,
      ),
    ]);
  }
}

@Riverpod(keepAlive: true)
WinUpdatesService winUpdatesService(Ref ref) {
  return const WinUpdatesServiceImpl();
}

// Riverpod Providers
@riverpod
bool pauseUpdatesWUStatus(Ref ref) {
  return ref.watch(winUpdatesServiceProvider).statusPauseUpdatesWU;
}

@riverpod
bool visibilityWUStatus(Ref ref) {
  return ref.watch(winUpdatesServiceProvider).statusVisibilityWU;
}

@riverpod
bool driversWUStatus(Ref ref) {
  return ref.watch(winUpdatesServiceProvider).statusDriversWU;
}
