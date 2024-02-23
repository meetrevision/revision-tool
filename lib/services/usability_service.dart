import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import 'registry_utils_service.dart';
import 'setup_service.dart';

class UsabilityService implements SetupService {
  
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
    return RegistryUtilsService.readInt(
            RegistryHive.currentUser,
            r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
            'ToastEnabled') !=
        0;
  }

  Future<void> enableNotification() async {
    RegistryUtilsService.deleteKey(
      Registry.currentUser,
      r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
    );
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND');
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK');
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK');
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED');
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    RegistryUtilsService.deleteValue(Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer', 'ToastEnabled');
    RegistryUtilsService.deleteValue(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\Explorer', 'ToastEnabled');
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        1);
    RegistryUtilsService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled');
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification');
    RegistryUtilsService.deleteValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoTileApplicationNotification');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNotification() async {
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1);
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
    RegistryUtilsService.writeDword(Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  bool get statusLegacyBalloon {
    return RegistryUtilsService.readInt(
            RegistryHive.currentUser,
            r'Software\Policies\Microsoft\Windows\Explorer',
            'EnableLegacyBalloonNotifications') !=
        0;
  }

  Future<void> enableLegacyBalloon() async {
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'EnableLegacyBalloonNotifications',
        1);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableLegacyBalloon() async {
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'EnableLegacyBalloonNotifications',
        0);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  bool get statusInputPersonalization {
    return RegistryUtilsService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Policies\Microsoft\InputPersonalization',
            'AllowInputPersonalization') ==
        1;
  }

  void enableInputPersonalization() {
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        1);
  }

  void disableInputPersonalization() {
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        0);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    RegistryUtilsService.writeDword(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    RegistryUtilsService.writeDword(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        0);
  }

  bool get statusCapsLock {
    Uint8List? value;
    try {
      value = RegistryUtilsService.readBinary(RegistryHive.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Keyboard Layout', 'Scancode Map');
    } catch (e) {
      //
    }

    return _listEquality.equals(_cplValue, value);
  }

  void enableCapsLock() {
    RegistryUtilsService.deleteValue(Registry.localMachine,
        r"SYSTEM\CurrentControlSet\Control\Keyboard Layout", "Scancode Map");
  }

  void disableCapsLock() {
    RegistryUtilsService.writeBinary(
        Registry.localMachine,
        r"SYSTEM\CurrentControlSet\Control\Keyboard Layout",
        "Scancode Map",
        _cplValue);
  }

  bool get statusScreenEdgeSwipe {
    return RegistryUtilsService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', 'AllowEdgeSwipe') !=
        0;
  }

  void enableScreenEdgeSwipe() {
    RegistryUtilsService.deleteValue(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', "AllowEdgeSwipe");
  }

  void disableScreenEdgeSwipe() {
    RegistryUtilsService.writeDword(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', "AllowEdgeSwipe", 0);
  }

  //Windows 11

  bool get statusNewContextMenu {
    return RegistryUtilsService
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
    // RegistryUtilsService.deleteValueKey(Registry.currentUser,
    // r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNewContextMenu() async {
    RegistryUtilsService.createKey(Registry.currentUser,
        r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32');
    RegistryUtilsService.writeString(
        Registry.currentUser,
        r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32',
        '',
        '');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }
}
