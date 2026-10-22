import 'dart:io';
import 'dart:typed_data';

import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

import '../cli_generator/annotations.dart';
import '../trusted_installer/trusted_installer_service.dart';
import 'nt_feature_helper.dart';

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

  /// Sets Windows feature overrides across Boot (Registry), Runtime (ntdll), and BootStatus (BSD).
  static Future<void> setFeatures(
    Iterable<int> featureIds, {
    required bool enabled,
    int retryCount = 0,
  }) async {
    final List<int> ids = featureIds.toList(growable: false);
    if (ids.isEmpty) return;

    final stateVal = enabled ? 2 : 1;
    final policyVal = enabled ? 1 : 0;

    final registryTasks = <Future<void>>[
      for (final featureId in ids) ...[
        () async {
          final controlPath = '$_featureOverridesControlPath\\${obfuscateFeatureId(featureId)}';
          try {
            final RegistryKey subKey = LOCAL_MACHINE.create(controlPath);
            try {
              subKey.setValue('EnabledState', .dword(stateVal));
              subKey.setValue('EnabledStateOptions', const .dword(0));
              subKey.setValue('Variant', const .dword(0));
              subKey.setValue('VariantPayload', const .dword(0));
              subKey.setValue('VariantPayloadKind', const .dword(0));
            } finally {
              subKey.close();
            }
            logger.i('$tag(setFeatures): $controlPath EnabledState = $stateVal');
          } on WindowsException catch (e) {
            // 0x80070005 = ERROR_ACCESS_DENIED
            if (e.hr == -2147024891) {
              logger.w(
                '$tag(setFeatures): Access denied, retrying with TrustedInstaller: $controlPath',
              );
              if (retryCount > 0) rethrow;
              return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
                () => setFeatures([featureId], enabled: enabled, retryCount: retryCount + 1),
              );
            }
            logger.e('$tag(setFeatures): $controlPath', error: e, stackTrace: .current);
          } catch (e, st) {
            logger.e('$tag(setFeatures): $controlPath', error: e, stackTrace: st);
          }
        }(),
        writeRegistryValue(
          LOCAL_MACHINE,
          _featureOverridesPolicyPath,
          obfuscateFeatureId(featureId).toString(),
          policyVal,
        ),
      ],
    ];

    await Future.wait(registryTasks);

    // Apply runtime in-memory feature configuration so active processes immediately recognize the state.
    await NtFeatureHelper.setRuntimeFeatures({for (final id in ids) id: enabled});

    // Flag BootPending in system boot status data so Windows commits the overrides across reboot.
    await NtFeatureHelper.updateBootStatusPending();
  }

  /// Enables Windows feature overrides via their Feature IDs.
  static Future<void> enableFeatures(Iterable<int> featureIds) =>
      setFeatures(featureIds, enabled: true);

  /// Disables Windows feature overrides via their Feature IDs.
  static Future<void> disableFeatures(Iterable<int> featureIds) =>
      setFeatures(featureIds, enabled: false);

  /// Resets overrides for [featureIds] to Windows defaults (deletes the overrides).
  static Future<void> resetFeatures(Iterable<int> featureIds) async {
    final List<int> ids = featureIds.toList();
    if (ids.isEmpty) return;

    final registryTasks = <Future<void>>[
      for (final int featureId in ids) ...[
        deleteKey(LOCAL_MACHINE, '$_featureOverridesControlPath\\${obfuscateFeatureId(featureId)}'),
        deleteValue(
          LOCAL_MACHINE,
          _featureOverridesPolicyPath,
          obfuscateFeatureId(featureId).toString(),
        ),
      ],
    ];

    await Future.wait(registryTasks);

    // Reset runtime in-memory feature configuration.
    await NtFeatureHelper.resetRuntimeFeatures(ids);

    // Flag BootPending in system boot status data.
    await NtFeatureHelper.updateBootStatusPending();
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
