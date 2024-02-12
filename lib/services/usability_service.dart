import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';
import 'setup_service.dart';

class UsabilityService implements SetupService {
  static final _registryUtilsService = RegistryUtilsService();
  static final _shell = Shell();
  static const _listEquality = ListEquality();

  static final _cplValue = Uint8List.fromList(
    [0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 58, 0, 0, 0, 0, 0],
  );

  static const _instance = UsabilityService._private();
  factory UsabilityService() {
    return _instance;
  }
  const UsabilityService._private();

  @override
  void recommendation() {}

  bool get statusNotification {
    return _registryUtilsService.readInt(
            RegistryHive.currentUser,
            r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
            'NoToastApplicationNotification') !=
        1;
  }

  Future<void> enableNotification() async {
    _registryUtilsService.deleteKey(
      Registry.currentUser,
      r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
    );
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND');
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK');
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK');
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED');
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    _registryUtilsService.deleteValue(Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer', 'ToastEnabled');
    _registryUtilsService.deleteValue(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\Explorer', 'ToastEnabled');
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        1);
    _registryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled');
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification');
    _registryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoTileApplicationNotification');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNotification() async {
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1);
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
    _registryUtilsService.writeDword(Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  bool get statusLegacyBalloon {
    return _registryUtilsService.readInt(
            RegistryHive.currentUser,
            r'Software\Policies\Microsoft\Windows\Explorer',
            'EnableLegacyBalloonNotifications') !=
        0;
  }

  Future<void> enableLegacyBalloon() async {
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'EnableLegacyBalloonNotifications',
        1);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableLegacyBalloon() async {
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'EnableLegacyBalloonNotifications',
        0);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  bool get statusInputPersonalization {
    return _registryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Policies\Microsoft\InputPersonalization',
            'AllowInputPersonalization') ==
        1;
  }

  void enableInputPersonalization() {
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        1);
  }

  void disableInputPersonalization() {
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        0);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    _registryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    _registryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        0);
  }

  bool get statusCapsLock {
    Uint8List? value;
    try {
      value = _registryUtilsService.readBinary(RegistryHive.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Keyboard Layout', 'Scancode Map');
    } catch (e) {
      //
    }

    return _listEquality.equals(_cplValue, value);
  }

  void enableCapsLock() {
    _registryUtilsService.deleteValue(Registry.localMachine,
        r"SYSTEM\CurrentControlSet\Control\Keyboard Layout", "Scancode Map");
  }

  void disableCapsLock() {
    _registryUtilsService.writeBinary(
        Registry.localMachine,
        r"SYSTEM\CurrentControlSet\Control\Keyboard Layout",
        "Scancode Map",
        _cplValue);
  }

  bool get statusScreenEdgeSwipe {
    return _registryUtilsService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', 'AllowEdgeSwipe') !=
        0;
  }

  void enableScreenEdgeSwipe() {
    _registryUtilsService.deleteValue(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', "AllowEdgeSwipe");
  }

  void disableScreenEdgeSwipe() {
    _registryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', "AllowEdgeSwipe", 0);
  }

  //Windows 11

  bool get statusNewContextMenu {
    return _registryUtilsService
            .readString(
                RegistryHive.currentUser,
                r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32',
                '')
            ?.isNotEmpty ??
        true;
  }

  Future<void> enableNewContextMenu() async {
    _shell.run(
        r'reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f');
    // Error 0x80070005: Access is denied.
    // _registryUtilsService.deleteValueKey(Registry.currentUser,
    // r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNewContextMenu() async {
    _registryUtilsService.createKey(Registry.currentUser,
        r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32');
    _registryUtilsService.writeString(
        Registry.currentUser,
        r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32',
        '',
        '');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }
}
