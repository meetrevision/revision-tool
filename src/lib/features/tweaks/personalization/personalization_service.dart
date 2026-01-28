import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../../core/services/win_registry_service.dart';

part 'personalization_service.g.dart';

enum NotificationMode { on, offMinimal, offFull }

abstract class PersonalizationService {
  // Desktop
  NotificationMode get statusNotification;
  Future<void> enableNotification();
  Future<void> disableNotification();
  Future<void> disableNotificationAggressive();
  bool get statusLegacyBalloon;
  Future<void> enableLegacyBalloon();
  Future<void> disableLegacyBalloon();
  bool get statusScreenEdgeSwipe;
  Future<void> enableScreenEdgeSwipe();
  Future<void> disableScreenEdgeSwipe();
  bool get statusNewContextMenu;
  Future<void> enableNewContextMenu();
  Future<void> disableNewContextMenu();

  // Input & Typing
  bool get statusInputPersonalization;
  Future<void> enableInputPersonalization();
  Future<void> disableInputPersonalization();
  bool get statusCapsLock;
  Future<void> enableCapsLock();
  Future<void> disableCapsLock();
}

class PersonalizationServiceImpl implements PersonalizationService {
  const PersonalizationServiceImpl();

  static const ListEquality<dynamic> _listEquality = ListEquality();
  static final _cplValue = Uint8List.fromList([
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    0,
    0,
    0,
    0,
    0,
    58,
    0,
    0,
    0,
    0,
    0,
  ]);

  @override
  NotificationMode get statusNotification {
    final isToastEnabled =
        WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
          'ToastEnabled',
        ) !=
        0;
    final isNotificationCenterEnabled =
        WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
          'DisableNotificationCenter',
        ) !=
        1;

    if (!isNotificationCenterEnabled) {
      return NotificationMode.offFull;
    } else if (!isToastEnabled) {
      return NotificationMode.offMinimal;
    } else {
      return NotificationMode.on;
    }
  }

  @override
  Future<void> enableNotification() async {
    await Future.wait([
      WinRegistryService.deleteKey(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'ToastEnabled',
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Policies\Microsoft\Windows\Explorer',
        'ToastEnabled',
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        1,
      ),
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoTileApplicationNotification',
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Allow',
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Allow',
      ),
    ]);

    for (final page in ['notifications', 'privacy-notifications']) {
      await WinRegistryService.unhidePageVisibilitySettings(page);
    }

    final Iterable<String> wpnServices = WinRegistryService.getUserServices(
      'Wpn',
    );
    await Future.wait(
      wpnServices.map(
        (service) => WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Services\' + service,
          'Start',
          2,
        ),
      ),
    );

    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  @override
  Future<void> disableNotification() async {
    await Future.wait([
      WinRegistryService.deleteValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
      ),
      WinRegistryService.deleteValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications',
        'NoToastApplicationNotification',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings',
        'NOC_GLOBAL_SETTING_TOASTS_ENABLED',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'ToastEnabled',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'ToastEnabled',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Deny',
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener',
        'Value',
        'Deny',
      ),
    ]);

    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  @override
  Future<void> disableNotificationAggressive() async {
    await disableNotification();
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'DisableNotificationCenter',
        1,
      ),
    ]);

    final Iterable<String> wpnServices = WinRegistryService.getUserServices(
      'Wpn',
    );
    await Future.wait(
      wpnServices.map(
        (service) => WinRegistryService.writeRegistryValue(
          Registry.localMachine,
          r'SYSTEM\ControlSet001\Services\' + service,
          'Start',
          4,
        ),
      ),
    );

    for (final page in ['notifications', 'privacy-notifications']) {
      await WinRegistryService.hidePageVisibilitySettings(page);
    }
  }

  @override
  bool get statusLegacyBalloon {
    return WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Software\Policies\Microsoft\Windows\Explorer',
          'EnableLegacyBalloonNotifications',
        ) !=
        0;
  }

  @override
  Future<void> enableLegacyBalloon() async {
    await WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Policies\Microsoft\Windows\Explorer',
      'EnableLegacyBalloonNotifications',
      1,
    );
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  @override
  Future<void> disableLegacyBalloon() async {
    await WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Policies\Microsoft\Windows\Explorer',
      'EnableLegacyBalloonNotifications',
      0,
    );
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  @override
  bool get statusScreenEdgeSwipe {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI',
          'AllowEdgeSwipe',
        ) !=
        0;
  }

  @override
  Future<void> enableScreenEdgeSwipe() async {
    await WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI',
      'AllowEdgeSwipe',
    );
  }

  @override
  Future<void> disableScreenEdgeSwipe() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SOFTWARE\Policies\Microsoft\Windows\EdgeUI',
      'AllowEdgeSwipe',
      0,
    );
  }

  @override
  bool get statusNewContextMenu {
    return WinRegistryService.readString(
          RegistryHive.currentUser,
          r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32',
          '',
        )?.isNotEmpty ??
        true;
  }

  @override
  Future<void> enableNewContextMenu() async {
    await WinRegistryService.deleteKey(
      WinRegistryService.currentUser,
      r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}',
    );
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  @override
  Future<void> disableNewContextMenu() async {
    await WinRegistryService.writeRegistryValue(
      WinRegistryService.currentUser,
      r'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32',
      '',
      '',
    );
    await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
    await Process.run('explorer.exe', [], runInShell: true);
  }

  @override
  bool get statusInputPersonalization {
    return WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Policies\Microsoft\InputPersonalization',
          'AllowInputPersonalization',
        ) ==
        1;
  }

  @override
  Future<void> enableInputPersonalization() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        1,
      ),
    ]);
  }

  @override
  Future<void> disableInputPersonalization() async {
    await Future.wait([
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization\TrainedDataStore',
        'HarvestContacts',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'Software\Microsoft\InputPersonalization\Settings',
        'AcceptedPrivacyPolicy',
        0,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        WinRegistryService.currentUser,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitInkCollection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'RestrictImplicitTextCollection',
        1,
      ),
      WinRegistryService.writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Policies\Microsoft\InputPersonalization',
        'AllowInputPersonalization',
        0,
      ),
    ]);
  }

  @override
  bool get statusCapsLock {
    Uint8List? value;
    try {
      value = WinRegistryService.readBinary(
        RegistryHive.localMachine,
        r'SYSTEM\CurrentControlSet\Control\Keyboard Layout',
        'Scancode Map',
      );
    } catch (e) {
      //
    }

    return _listEquality.equals(_cplValue, value);
  }

  @override
  Future<void> enableCapsLock() async {
    await WinRegistryService.deleteValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Keyboard Layout',
      'Scancode Map',
    );
  }

  @override
  Future<void> disableCapsLock() async {
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\CurrentControlSet\Control\Keyboard Layout',
      'Scancode Map',
      _cplValue,
    );
  }
}

@Riverpod(keepAlive: true)
PersonalizationService personalizationService(Ref ref) {
  return const PersonalizationServiceImpl();
}

// Riverpod Providers
@riverpod
NotificationMode notificationStatus(Ref ref) {
  return ref.watch(personalizationServiceProvider).statusNotification;
}

@riverpod
bool legacyBalloonStatus(Ref ref) {
  return ref.watch(personalizationServiceProvider).statusLegacyBalloon;
}

@riverpod
bool screenEdgeSwipeStatus(Ref ref) {
  return ref.watch(personalizationServiceProvider).statusScreenEdgeSwipe;
}

@riverpod
bool newContextMenuStatus(Ref ref) {
  return ref.watch(personalizationServiceProvider).statusNewContextMenu;
}

@riverpod
bool inputPersonalizationStatus(Ref ref) {
  return ref.watch(personalizationServiceProvider).statusInputPersonalization;
}

@riverpod
bool capsLockStatus(Ref ref) {
  return ref.watch(personalizationServiceProvider).statusCapsLock;
}
