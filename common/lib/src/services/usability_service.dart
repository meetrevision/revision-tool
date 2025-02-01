import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import 'win_registry_service.dart';
import 'setup_service.dart';

enum NotificationMode { on, offMinimal, offFull }

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

  NotificationMode get statusNotification {
    final isToastEnabled = WinRegistryService.readInt(
            RegistryHive.currentUser,
            r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
            'ToastEnabled') !=
        0;
    final isNotificationCenterEnabled = WinRegistryService.readInt(
            RegistryHive.currentUser,
            r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
            'DisableNotificationCenter') !=
        1;

    if (!isNotificationCenterEnabled) {
      return NotificationMode.offFull;
    } else if (!isToastEnabled) {
      return NotificationMode.offMinimal;
    } else {
      return NotificationMode.on;
    }
  }

  Future<void> enableNotification() async {
    WinRegistryService.deleteKey(
      Registry.currentUser,
      r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
    );
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    WinRegistryService.deleteValue(Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer', 'ToastEnabled');
    WinRegistryService.deleteValue(Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\Explorer', 'ToastEnabled');
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        1);
    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoTileApplicationNotification');

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Allow');
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Allow');

    final wpnServices = WinRegistryService.getUserServices('Wpn');

    for (final service in wpnServices) {
      WinRegistryService.writeRegistryValue(Registry.localMachine,
          r'SYSTEM\ControlSet001\Services\' + service, 'Start', 2);
    }

    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNotification() async {
    WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');
    WinRegistryService.deleteValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter');

    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED',
        0);
    WinRegistryService.writeRegistryValue(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
    WinRegistryService.writeRegistryValue(Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0);

    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Deny');
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Deny');

    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNotificationAggressive() async {
    await disableNotification();
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1);

    final wpnServices = WinRegistryService.getUserServices('Wpn');

    for (final service in wpnServices) {
      WinRegistryService.writeRegistryValue(Registry.localMachine,
          r'SYSTEM\ControlSet001\Services\' + service, 'Start', 4);
    }
    for (final page in ["notifications", "privacy-notifications"]) {
      WinRegistryService.hidePageVisibilitySettings(page);
    }
  }

  bool get statusLegacyBalloon {
    return WinRegistryService.readInt(
            RegistryHive.currentUser,
            r'Software\Policies\Microsoft\Windows\Explorer',
            'EnableLegacyBalloonNotifications') !=
        0;
  }

  Future<void> enableLegacyBalloon() async {
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'EnableLegacyBalloonNotifications',
        1);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableLegacyBalloon() async {
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'EnableLegacyBalloonNotifications',
        0);
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  bool get statusInputPersonalization {
    return WinRegistryService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\Policies\Microsoft\InputPersonalization',
            'AllowInputPersonalization') ==
        1;
  }

  void enableInputPersonalization() {
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        1);
  }

  void disableInputPersonalization() {
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        0);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1);
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        0);
  }

  bool get statusCapsLock {
    Uint8List? value;
    try {
      value = WinRegistryService.readBinary(RegistryHive.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Keyboard Layout', 'Scancode Map');
    } catch (e) {
      //
    }

    return _listEquality.equals(_cplValue, value);
  }

  void enableCapsLock() {
    WinRegistryService.deleteValue(Registry.localMachine,
        r"SYSTEM\CurrentControlSet\Control\Keyboard Layout", "Scancode Map");
  }

  void disableCapsLock() {
    WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r"SYSTEM\CurrentControlSet\Control\Keyboard Layout",
        "Scancode Map",
        _cplValue);
  }

  bool get statusScreenEdgeSwipe {
    return WinRegistryService.readInt(RegistryHive.localMachine,
            r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', 'AllowEdgeSwipe') !=
        0;
  }

  void enableScreenEdgeSwipe() {
    WinRegistryService.deleteValue(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', "AllowEdgeSwipe");
  }

  void disableScreenEdgeSwipe() {
    WinRegistryService.writeRegistryValue(Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI', "AllowEdgeSwipe", 0);
  }

  //Windows 11

  bool get statusNewContextMenu {
    return WinRegistryService.readString(
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
    // WinRegistryService.deleteValueKey(Registry.currentUser,
    // r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  Future<void> disableNewContextMenu() async {
    WinRegistryService.createKey(Registry.currentUser,
        r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32');
    WinRegistryService.writeRegistryValue(
        Registry.currentUser,
        r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32',
        '',
        '');
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }
}
