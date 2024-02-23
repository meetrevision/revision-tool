import 'package:revitool/services/setup_service.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';

class UpdatesService implements SetupService {
  

  static const _instance = UpdatesService._private();
  factory UpdatesService() {
    return _instance;
  }
  const UpdatesService._private();

  @override
  void recommendation() {}

  bool get statusPauseUpdatesWU {
    return RegistryUtilsService
            .readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
                "PauseUpdatesExpiryTime")
            ?.contains("2038-01-19T03:14:07Z") ??
        false;
  }

  void enablePauseUpdatesWU() {
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "FlightSettingsMaxPauseDays",
        5269);

    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseFeatureUpdatesStartTime",
        "2023-08-17T12:47:51Z");

    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseFeatureUpdatesEndTime",
        "2038-01-19T03:14:07Z");

    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseQualityUpdatesStartTime",
        "2023-08-17T12:47:51Z");

    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseQualityUpdatesEndTime",
        "2038-01-19T03:14:07Z");

    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseUpdatesStartTime",
        "2023-08-17T12:47:51Z");

    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        "PauseUpdatesExpiryTime",
        "2038-01-19T03:14:07Z");
  }

  void disablePauseUpdatesWU() {
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'FlightSettingsMaxPauseDays');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseFeatureUpdatesStartTime');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseFeatureUpdatesEndTime');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseQualityUpdatesStartTime');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseQualityUpdatesEndTime');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseUpdatesStartTime');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'PauseUpdatesExpiryTime');
  }

  bool get statusVisibilityWU {
    return RegistryUtilsService
            .readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
                'SettingsPageVisibility')
            ?.contains("windowsupdate") ??
        false;
  }

  void enableVisibilityWU() {
    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;windowsinsider-optin;windowsinsider;windowsupdate");
  }

  void disableVisibilityWU() {
    RegistryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;");
  }

  bool get statusDriversWU {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
            'PreventDeviceMetadataFromNetwork') ==
        0;
  }

  void enableDriversWU() {
    RegistryUtilsService.deleteKey(Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching');
    RegistryUtilsService.deleteKey(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching');

    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate');
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork');
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        0);
  }

  void disableDriversWU() {
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'SearchOrderConfig',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1);
  }
}
