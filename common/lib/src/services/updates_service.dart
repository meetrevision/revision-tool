import 'package:common/src/services/setup_service.dart';
import 'package:win32_registry/win32_registry.dart';

import 'win_registry_service.dart';

class UpdatesService implements SetupService {
  static const _instance = UpdatesService._private();
  factory UpdatesService() {
    return _instance;
  }
  const UpdatesService._private();

  @override
  void recommendation() {}

  bool get statusPauseUpdatesWU {
    return WinRegistryService.readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
                "PauseUpdatesExpiryTime")
            ?.contains("2038-01-19T03:14:07Z") ??
        false;
  }

  void enablePauseUpdatesWU() {
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "FlightSettingsMaxPauseDays",
        5269);

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseFeatureUpdatesStartTime",
        "2023-08-17T12:47:51Z");

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseFeatureUpdatesEndTime",
        "2038-01-19T03:14:07Z");

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseQualityUpdatesStartTime",
        "2023-08-17T12:47:51Z");

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseQualityUpdatesEndTime",
        "2038-01-19T03:14:07Z");

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseUpdatesStartTime",
        "2023-08-17T12:47:51Z");

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseUpdatesExpiryTime",
        "2038-01-19T03:14:07Z");
  }

  void disablePauseUpdatesWU() {
    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'FlightSettingsMaxPauseDays');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseFeatureUpdatesStartTime');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseFeatureUpdatesEndTime');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseQualityUpdatesStartTime');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseQualityUpdatesEndTime');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseUpdatesStartTime');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseUpdatesExpiryTime');
  }

  bool get statusVisibilityWU {
    return WinRegistryService.readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
                'SettingsPageVisibility')
            ?.contains("windowsupdate") ??
        false;
  }

  void enableVisibilityWU() {
    final currentValue = WinRegistryService.readString(
        RegistryHive.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility');

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        currentValue!.endsWith(";")
            ? currentValue.replaceAll("windowsupdate;", "")
            : currentValue.replaceAll("windowsupdate", ""));
  }

  void disableVisibilityWU() {
    WinRegistryService.hidePageVisibilitySettings("windowsupdate");
  }

  bool get statusDriversWU {
    return WinRegistryService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
            'PreventDeviceMetadataFromNetwork') ==
        0;
  }

  void enableDriversWU() {
    WinRegistryService.deleteKey(Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching');
    WinRegistryService.deleteKey(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching');

    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate');
    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork');
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        0);
  }

  void disableDriversWU() {
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'SearchOrderConfig',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1);
  }
}
