import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../shared/win_registry_service.dart';

part 'updates_service.g.dart';

abstract final class WinUpdatesService {
  static bool get statusPauseUpdatesWU {
    return WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
          "PauseUpdatesExpiryTime",
        )?.contains("2038-01-19T03:14:07Z") ??
        false;
  }

  static void enablePauseUpdatesWU() {
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "FlightSettingsMaxPauseDays",
      5269,
    );

    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "PauseFeatureUpdatesStartTime",
      "2023-08-17T12:47:51Z",
    );

    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "PauseFeatureUpdatesEndTime",
      "2038-01-19T03:14:07Z",
    );

    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "PauseQualityUpdatesStartTime",
      "2023-08-17T12:47:51Z",
    );

    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "PauseQualityUpdatesEndTime",
      "2038-01-19T03:14:07Z",
    );

    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "PauseUpdatesStartTime",
      "2023-08-17T12:47:51Z",
    );

    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      "PauseUpdatesExpiryTime",
      "2038-01-19T03:14:07Z",
    );
  }

  static void disablePauseUpdatesWU() {
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'FlightSettingsMaxPauseDays',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'PauseFeatureUpdatesStartTime',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'PauseFeatureUpdatesEndTime',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'PauseQualityUpdatesStartTime',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'PauseQualityUpdatesEndTime',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'PauseUpdatesStartTime',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
      'PauseUpdatesExpiryTime',
    );
  }

  static bool get statusVisibilityWU {
    return WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
        )?.contains("windowsupdate") ??
        false;
  }

  static void enableVisibilityWU() {
    WinRegistryService.unhidePageVisibilitySettings("windowsupdate");
  }

  static void disableVisibilityWU() {
    WinRegistryService.hidePageVisibilitySettings("windowsupdate");
  }

  static bool get statusDriversWU {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
          'PreventDeviceMetadataFromNetwork',
        ) ==
        0;
  }

  static void enableDriversWU() {
    WinRegistryService.deleteKey(
      WinRegistryService.currentUser,
      r'Software\Policies\Microsoft\Windows\DriverSearching',
    );
    WinRegistryService.deleteKey(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\DriverSearching',
    );

    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\WindowsUpdate',
      'ExcludeWUDriversInQualityUpdate',
    );
    WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
      'PreventDeviceMetadataFromNetwork',
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
      'PreventDeviceMetadataFromNetwork',
      0,
    );
  }

  static void disableDriversWU() {
    WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Policies\Microsoft\Windows\DriverSearching',
      'DontPromptForWindowsUpdate',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\DriverSearching',
      'DontPromptForWindowsUpdate',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\DriverSearching',
      'SearchOrderConfig',
      0,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'Software\Policies\Microsoft\Windows\WindowsUpdate',
      'ExcludeWUDriversInQualityUpdate',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
      'PreventDeviceMetadataFromNetwork',
      1,
    );
    WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
      'PreventDeviceMetadataFromNetwork',
      1,
    );
  }
}

// Riverpod Providers
@riverpod
bool pauseUpdatesWUStatus(Ref ref) {
  return WinUpdatesService.statusPauseUpdatesWU;
}

@riverpod
bool visibilityWUStatus(Ref ref) {
  return WinUpdatesService.statusVisibilityWU;
}

@riverpod
bool driversWUStatus(Ref ref) {
  return WinUpdatesService.statusDriversWU;
}
