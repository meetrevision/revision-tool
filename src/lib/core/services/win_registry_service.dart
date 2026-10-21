import 'dart:io';
import 'dart:typed_data';

import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

import '../cli_generator/annotations.dart';
import '../trusted_installer/trusted_installer_service.dart';

// @CliCommand(name: 'registry', description: 'Windows registry utilities')
abstract class const WinRegistryService._private() {
  static const tag = 'await WinRegistryService';

  // @CliAction(name: 'hide-page', run: 'hideSettingsPage')
  Future<void> hideSettingsPage(String pageName);

  // @CliAction(name: 'unhide-page', run: 'unhideSettingsPage')
  Future<void> unhideSettingsPage(String pageName);

  static Future<void> initialize() async {
    currentUserSid = await runPSCommand(
      '[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value',
      loggerInfoOutput: false,
    ).then((result) => result.stdout.toString().trim());
  }

  static int get buildNumber => _buildNumber;
  static final int _buildNumber = int.parse(
    WinRegistryService.readString(
      LOCAL_MACHINE,
      r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
      'CurrentBuildNumber',
    )!,
  );

  static final BaseRegistryKey currentUser = CURRENT_USER;
  static late final String currentUserSid;
  static const defaultUser = 'DefaultUserHive';
  static const defaultUserHivePath = r'C:\Users\Default\NTUSER.DAT';
  static const _settingsPageVisibilityPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer';
  static const _settingsPageVisibilityName = 'SettingsPageVisibility';

  static final bool isW11 = buildNumber > 19045;

  static final String cpuArch = readString(
    LOCAL_MACHINE,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'PROCESSOR_ARCHITECTURE',
  )!.toLowerCase();

  static final String _cpuVendorIdentifier =
      (readString(
                LOCAL_MACHINE,
                r'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
                'VendorIdentifier',
              ) ??
              '')
          .toLowerCase();

  static final bool isIntelCpu = _cpuVendorIdentifier.contains('intel');
  static final bool isAmdCpu = _cpuVendorIdentifier.contains('amd');

  static final bool isAmePlaybook = Directory(
    '${Directory.systemTemp.path}\\AME\\Playbooks\\Revision-ReviOS',
  ).existsSync();

  static bool get isSupported {
    return _validate() ||
        readString(
              LOCAL_MACHINE,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubVersion',
            ) ==
            'ReviOS' ||
        readString(
              LOCAL_MACHINE,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubManufacturer',
            ) ==
            'MeetRevision';
  }

  static bool _validate() {
    final RegistryKey key = LOCAL_MACHINE.open(
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages',
    );

    try {
      return key.keys.lastWhere((element) => element.startsWith('Revision-ReviOS')).isNotEmpty;
    } catch (e) {
      if (!isAmePlaybook) {
        logger.w('Error validating ReviOS');
      }
      return false;
    } finally {
      key.close();
    }
  }

  static Future<void> hidePageVisibilitySettings(String pageNames) async {
    final List<String> pages = pageNames
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    for (final page in pages) {
      await _hidePageVisibilitySettingsSingle(page);
    }
  }

  static Future<void> _hidePageVisibilitySettingsSingle(String pageName) async {
    final String? currentValue = readString(
      LOCAL_MACHINE,
      _settingsPageVisibilityPath,
      _settingsPageVisibilityName,
    );

    if (currentValue == null || currentValue.isEmpty) {
      await writeRegistryValue(
        LOCAL_MACHINE,
        _settingsPageVisibilityPath,
        _settingsPageVisibilityName,
        'hide:$pageName',
      );
      return;
    }
    if (!currentValue.contains(pageName)) {
      await writeRegistryValue(
        LOCAL_MACHINE,
        _settingsPageVisibilityPath,
        _settingsPageVisibilityName,
        currentValue.endsWith(';') || currentValue.endsWith(':')
            ? '$currentValue$pageName;'
            : '$currentValue;$pageName;',
      );
      return;
    }
  }

  static Future<void> unhidePageVisibilitySettings(String pageNames) async {
    final List<String> pages = pageNames
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    for (final page in pages) {
      await _unhidePageVisibilitySettingsSingle(page);
    }
  }

  static Future<void> _unhidePageVisibilitySettingsSingle(String pageName) async {
    final String? currentValue = readString(
      LOCAL_MACHINE,
      _settingsPageVisibilityPath,
      _settingsPageVisibilityName,
    );

    if (currentValue == null || currentValue.isEmpty) return;

    if (currentValue.contains(pageName)) {
      String newValue = currentValue;

      if (currentValue == 'hide:$pageName') {
        await deleteValue(LOCAL_MACHINE, _settingsPageVisibilityPath, _settingsPageVisibilityName);
        return;
      } else if (currentValue.contains('$pageName;')) {
        newValue = newValue.replaceAll('$pageName;', '');
      } else if (currentValue.contains(';$pageName')) {
        newValue = newValue.replaceAll(';$pageName', '');
      }

      if (newValue == 'hide:' || newValue.isEmpty) {
        await deleteValue(LOCAL_MACHINE, _settingsPageVisibilityPath, _settingsPageVisibilityName);
      } else {
        await writeRegistryValue(
          LOCAL_MACHINE,
          _settingsPageVisibilityPath,
          _settingsPageVisibilityName,
          newValue,
        );
      }
    }
  }

  static Iterable<String> getUserServices(String subkey) {
    final RegistryKey key = LOCAL_MACHINE.open(r'SYSTEM\ControlSet001\Services');
    try {
      return key.keys.where((String e) => e.startsWith(subkey)).toList();
    } finally {
      key.close();
    }
  }

  static String? get themeModeReg =>
      readString(LOCAL_MACHINE, r'SOFTWARE\Revision\Revision Tool', 'ThemeMode');

  static bool get themeTransparencyEffect =>
      readInt(
        CURRENT_USER,
        r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        'EnableTransparency',
      ) ==
      1;

  static int? readInt(BaseRegistryKey hive, String path, String value) {
    try {
      final RegistryKey key = hive.open(path);
      try {
        return key.getInt(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static String? readString(BaseRegistryKey hive, String path, String value) {
    try {
      final RegistryKey key = hive.open(path);
      try {
        return key.getString(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static List<String>? getStringArrayValue(BaseRegistryKey hive, String path, String value) {
    try {
      final RegistryKey key = hive.open(path);
      try {
        return key.getMultiString(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Uint8List? readBinary(BaseRegistryKey hive, String path, String value) {
    try {
      final RegistryKey key = hive.open(path);
      try {
        return key.getBinary(value);
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeRegistryValue<T extends Object>(
    BaseRegistryKey key,
    String path,
    String name,
    T value, {
    int retryCount = 0,
    bool useTrustedInstaller = false,
  }) async {
    if (useTrustedInstaller) {
      return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
        () async => writeRegistryValue<T>(key, path, name, value, retryCount: retryCount),
      );
    }

    final shouldClose = key != WinRegistryService.currentUser;

    try {
      final RegistryValue registryValue = switch (value) {
        final RegistryValue v => v,
        final int v => RegistryValue.dword(v),
        final String v => RegistryValue.string(v),
        final List<String> v => RegistryValue.multiString(v),

        // final List<int> v => RegistryValue.binary(Uint8List.fromList(v)),
        final Uint8List v => RegistryValue.binary(v),
        final _ => throw ArgumentError(
          '$tag(writeRegistryValue): Unsupported type: ${value.runtimeType}',
        ),
      };

      final RegistryKey subKey = key.create(path);
      try {
        subKey.setValue(name, registryValue);
      } finally {
        subKey.close();
      }
      logger.i('$tag(writeRegistryValue): $path\\$name = $value');

      if (key == WinRegistryService.currentUser) {
        await TrustedInstallerServiceImpl().executeCommand('reg', [
          'load',
          'HKU\\$defaultUser',
          defaultUserHivePath,
        ]);

        final PredefinedRegistryKey reg = USERS;
        final RegistryKey subKey = reg.create('$defaultUser\\$path');
        try {
          subKey.setValue(name, registryValue);
        } finally {
          subKey.close();
        }
        logger.i('$tag(writeRegistryValue): $defaultUser\\$path\\$name = $value');
      }
    } on WindowsException catch (e) {
      // 0x80070005 = ERROR_ACCESS_DENIED
      if (e.hr == -2147024891) {
        logger.w(
          '$tag(writeRegistryValue): Access denied (0x80070005), retrying with TrustedInstaller: $path\\$name',
        );
        try {
          if (retryCount > 0) {
            logger.e(
              '$tag(writeRegistryValue): Retry limit reached for TrustedInstaller: $path\\$name',
            );
            rethrow;
          }

          await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () async => writeRegistryValue<T>(key, path, name, value, retryCount: retryCount + 1),
          );
          return;
        } catch (tiError) {
          logger.e(
            '$tag(writeRegistryValue): Failed even with TrustedInstaller: $path\\$name',
            error: tiError,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      }
      logger.e('$tag(writeRegistryValue): $path\\$name', error: e, stackTrace: StackTrace.current);
    } catch (e) {
      logger.e('$tag(writeRegistryValue): $path\\$name', error: e, stackTrace: StackTrace.current);
    } finally {
      if (shouldClose && key is RegistryKey) {
        key.close();
      }
    }
  }

  static Future<void> deleteValue(
    BaseRegistryKey key,
    String path,
    String name, {
    int retryCount = 0,
    bool useTrustedInstaller = false,
  }) async {
    if (useTrustedInstaller) {
      return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
        () async => deleteValue(key, path, name, retryCount: retryCount),
      );
    }

    try {
      final RegistryKey subKey = key.create(path);
      try {
        subKey.removeValue(name);
      } finally {
        subKey.close();
      }
      logger.i('$tag(deleteValue): $path\\$name');
    } on WindowsException catch (e) {
      // 0x80070005 = ERROR_ACCESS_DENIED
      if (e.hr == -2147024891) {
        logger.w(
          '$tag(deleteValue): Access denied (0x80070005), retrying with TrustedInstaller: $path\\$name',
        );
        try {
          if (retryCount > 0) {
            logger.e('$tag(deleteValue): Retry limit reached for TrustedInstaller: $path\\$name');
            rethrow;
          }

          await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () async => deleteValue(key, path, name, retryCount: retryCount + 1),
          );
          return;
        } catch (tiError) {
          logger.e(
            '$tag(deleteValue): Failed even with TrustedInstaller: $path\\$name',
            error: tiError,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      }
      logger.e('$tag(deleteValue): $path\\$name', error: e, stackTrace: StackTrace.current);
    } catch (e) {
      logger.e('$tag(deleteValue): $path\\$name', error: e, stackTrace: StackTrace.current);
    }
  }

  static Future<void> deleteKey(
    BaseRegistryKey key,
    String path, {
    int retryCount = 0,
    bool useTrustedInstaller = false,
  }) async {
    if (useTrustedInstaller) {
      return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
        () async => deleteKey(key, path, retryCount: retryCount),
      );
    }

    try {
      key.removeSubkey(path);
      logger.i('$tag(deleteKey): $path');
    } on WindowsException catch (e) {
      // 0x80070005 = ERROR_ACCESS_DENIED
      if (e.hr == -2147024891) {
        logger.w(
          '$tag(deleteKey): Access denied (0x80070005), retrying with TrustedInstaller: $path',
        );
        try {
          if (retryCount > 0) {
            logger.e('$tag(deleteKey): Retry limit reached for TrustedInstaller: $path');
            rethrow;
          }

          await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () async => deleteKey(key, path, retryCount: retryCount + 1),
          );
          return;
        } catch (tiError) {
          logger.e(
            '$tag(deleteKey): Failed even with TrustedInstaller: $path',
            error: tiError,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      }
      logger.e('$tag(deleteKey): $path', error: e, stackTrace: StackTrace.current);
    } catch (e) {
      logger.e('$tag(deleteKey): $path', error: e, stackTrace: StackTrace.current);
    }
  }

  /// Whether [path] exists under [hive].
  static bool keyExists(BaseRegistryKey hive, String path) {
    try {
      hive.open(path).close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void createKey(BaseRegistryKey key, String path) {
    try {
      final RegistryKey subKey = key.create(path);
      subKey.close();
      logger.i('$tag(createKey): $path');
    } catch (e) {
      logger.e('$tag(createKey): $path', error: e, stackTrace: StackTrace.current);
    }
  }

  static const int _featureSeed = 0x447F3700;

  /// Encodes Feature ID to Windows FeatureManagement registry representation.
  /// Direct bit-slice layout: b0[6:0]->[31:25], b0[7]->[0], b1->[24:17], b2->[16:9], b3->[8:1].
  static int obfuscateFeatureId(int featureId) {
    final int w = (featureId ^ _featureSeed) & 0xFFFFFFFF;
    final int b0 = w & 0xFF;
    final int b1 = (w >> 8) & 0xFF;
    final int b2 = (w >> 16) & 0xFF;
    final int b3 = (w >> 24) & 0xFF;

    return (((b0 & 0x7F) << 25) | (b0 >> 7) | (b1 << 17) | (b2 << 9) | (b3 << 1)) & 0xFFFFFFFF;
  }

  /// Decodes Windows FeatureManagement registry representation back to Feature ID.
  static int deobfuscateFeatureId(int obfuscatedValue) {
    final int v = obfuscatedValue & 0xFFFFFFFF;
    final int b0 = ((v >> 25) & 0x7F) | ((v & 1) << 7);
    final int b1 = (v >> 17) & 0xFF;
    final int b2 = (v >> 9) & 0xFF;
    final int b3 = (v >> 1) & 0xFF;

    final int w = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
    return (w ^ _featureSeed) & 0xFFFFFFFF;
  }

  static const String _featureOverridesControlPath =
      r'SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8';
  static const String _featureOverridesPolicyPath =
      r'SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides';

  /// Sets the state of a Windows feature override in both primary and fallback locations.
  ///
  /// Primary: `[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\<obfuscatedId>]`
  ///   - EnabledState: 1 = disabled, 2 = enabled
  ///   - EnabledStateOptions, Variant, VariantPayload, VariantPayloadKind: 0
  /// Fallback: `[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides]`
  ///   - `<obfuscatedId>`: 0 = disabled, 1 = enabled
  static Future<void> _setFeatureState(int featureId, {required bool enabled}) async {
    final int obfuscated = obfuscateFeatureId(featureId);
    final controlPath = '$_featureOverridesControlPath\\$obfuscated';
    final enabledState = enabled ? 2 : 1;
    final policyState = enabled ? 1 : 0;

    await Future.wait([
      writeRegistryValue(LOCAL_MACHINE, controlPath, 'EnabledState', enabledState),
      writeRegistryValue(LOCAL_MACHINE, controlPath, 'EnabledStateOptions', 0),
      writeRegistryValue(LOCAL_MACHINE, controlPath, 'Variant', 0),
      writeRegistryValue(LOCAL_MACHINE, controlPath, 'VariantPayload', 0),
      writeRegistryValue(LOCAL_MACHINE, controlPath, 'VariantPayloadKind', 0),
      writeRegistryValue(
        LOCAL_MACHINE,
        _featureOverridesPolicyPath,
        obfuscated.toString(),
        policyState,
      ),
    ]);
  }

  /// Enables a Windows feature override via its Feature ID.
  static Future<void> enableFeature(int featureId) => _setFeatureState(featureId, enabled: true);

  /// Disables a Windows feature override via its Feature ID.
  static Future<void> disableFeature(int featureId) => _setFeatureState(featureId, enabled: false);

  /// Resets overrides for [featureId] to Windows defaults (deletes the overrides).
  static Future<void> resetFeature(int featureId) async {
    final int obfuscated = obfuscateFeatureId(featureId);
    final controlPath = '$_featureOverridesControlPath\\$obfuscated';

    await Future.wait([
      deleteKey(LOCAL_MACHINE, controlPath),
      deleteValue(LOCAL_MACHINE, _featureOverridesPolicyPath, obfuscated.toString()),
    ]);
  }
}

class const WinRegistryCliService() implements WinRegistryService {
  @override
  Future<void> hideSettingsPage(String pageName) =>
      WinRegistryService.hidePageVisibilitySettings(pageName);

  @override
  Future<void> unhideSettingsPage(String pageName) =>
      WinRegistryService.unhidePageVisibilitySettings(pageName);
}
