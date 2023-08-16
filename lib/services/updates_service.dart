import 'package:revitool/services/setup_service.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';

class UpdatesService implements SetupService {
  static final UpdatesService _instance = UpdatesService._private();

  final RegistryUtilsService _registryUtilsService = RegistryUtilsService();

  factory UpdatesService() {
    return _instance;
  }

  UpdatesService._private();

  @override
  void recommendation() {}

  bool get statusVisibilityWU {
    return _registryUtilsService
            .readString(
                RegistryHive.localMachine,
                r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
                'SettingsPageVisibility')
            ?.contains("windowsupdate") ??
        false;
  }

  void enableVisibilityWU() {
    _registryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;windowsinsider-optin;windowsinsider;windowsupdate");
  }

  void disableVisibilityWU() {
    _registryUtilsService.writeString(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        "hide:cortana;privacy-automaticfiledownloads;privacy-feedback;");
  }

  bool get statusDriversWU {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
            'PreventDeviceMetadataFromNetwork') ==
        0;
  }

  void enableDriversWU() {
    _registryUtilsService.deleteKey(Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching');
    _registryUtilsService.deleteKey(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching');

    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate');
    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork');
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        0);
  }

  void disableDriversWU() {
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'DontPromptForWindowsUpdate',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\DriverSearching',
        'SearchOrderConfig',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\WindowsUpdate',
        'ExcludeWUDriversInQualityUpdate',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Device Metadata',
        'PreventDeviceMetadataFromNetwork',
        1);
  }
}
