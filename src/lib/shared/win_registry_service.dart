import 'dart:typed_data';

import 'package:revitool/utils.dart';
import 'package:win32_registry/win32_registry.dart';

class WinRegistryService {
  static const tag = 'WinRegistryService';
  const WinRegistryService._private();

  static int get buildNumber => _buildNumber;
  static final int _buildNumber = int.parse(
    WinRegistryService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
      'CurrentBuildNumber',
    )!,
  );

  static final currentUser = Registry.currentUser;
  static const defaultUser = 'DefaultUserHive';
  static const defaultUserHivePath = "C:\\Users\\Default\\NTUSER.DAT";

  static bool get isW11 => _w11;
  static final bool _w11 = buildNumber > 19045;

  static final String cpuArch = WinRegistryService.readString(
    RegistryHive.localMachine,
    r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'PROCESSOR_ARCHITECTURE',
  )!.toLowerCase();

  // CPU vendor identification via registry only (no external dependencies)
  static final String _cpuVendorIdentifier =
      (WinRegistryService.readString(
                RegistryHive.localMachine,
                r'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
                'VendorIdentifier',
              ) ??
              '')
          .toLowerCase();

  // Convenience flags
  static bool get isIntelCpu => _cpuVendorIdentifier.contains('intel');
  static bool get isAmdCpu => _cpuVendorIdentifier.contains('amd');

  static bool get isSupported {
    return _validate() ||
        readString(
              RegistryHive.localMachine,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubVersion',
            ) ==
            'ReviOS' ||
        readString(
              RegistryHive.localMachine,
              r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
              'EditionSubManufacturer',
            ) ==
            'MeetRevision';
  }

  static bool _validate() {
    final key = Registry.openPath(
      RegistryHive.localMachine,
      path:
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages',
    );

    try {
      return key.subkeyNames
          .lastWhere((element) => element.startsWith("Revision-ReviOS"))
          .isNotEmpty;
    } catch (e) {
      logger.w('Error validating ReviOS');
      return false;
    }
  }

  static void hidePageVisibilitySettings(String pageName) {
    final currentValue = readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
      'SettingsPageVisibility',
    );

    if (currentValue == null || currentValue.isEmpty) {
      writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        "hide:$pageName",
      );
      return;
    }
    if (!currentValue.contains(pageName)) {
      writeRegistryValue(
        Registry.localMachine,
        r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'SettingsPageVisibility',
        currentValue.endsWith(";") || currentValue.endsWith(":")
            ? "$currentValue$pageName;"
            : "$currentValue;$pageName;",
      );
      return;
    }
  }

  static void unhidePageVisibilitySettings(String pageName) {
    final currentValue = readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
      'SettingsPageVisibility',
    );

    if (currentValue == null || currentValue.isEmpty) return;

    if (currentValue.contains(pageName)) {
      String newValue = currentValue;

      if (currentValue == "hide:$pageName") {
        deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
        );
        return;
      } else if (currentValue.contains("$pageName;")) {
        newValue = newValue.replaceAll("$pageName;", "");
      } else if (currentValue.contains(";$pageName")) {
        newValue = newValue.replaceAll(";$pageName", "");
      }

      if (newValue == "hide:" || newValue.isEmpty) {
        deleteValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
        );
      } else {
        writeRegistryValue(
          Registry.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
          'SettingsPageVisibility',
          newValue,
        );
      }
    }
  }

  static Iterable<String> getUserServices(String subkey) {
    return Registry.openPath(
      RegistryHive.localMachine,
      path: r'SYSTEM\ControlSet001\Services',
    ).subkeyNames.where((final e) => e.startsWith(subkey));
  }

  static String? get themeModeReg => WinRegistryService.readString(
    RegistryHive.localMachine,
    r'SOFTWARE\Revision\Revision Tool',
    'ThemeMode',
  );

  static bool get themeTransparencyEffect =>
      WinRegistryService.readInt(
        RegistryHive.currentUser,
        r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
        'EnableTransparency',
      ) ==
      1;

  static int? readInt(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(hive, path: path).getIntValue(value);
    } catch (_) {
      return null;
    }
  }

  static String? readString(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(hive, path: path).getStringValue(value);
    } catch (_) {
      return null;
    }
  }

  static Uint8List? readBinary(RegistryHive hive, String path, String value) {
    try {
      return Registry.openPath(hive, path: path).getBinaryValue(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeRegistryValue<T extends Object>(
    RegistryKey key,
    String path,
    String name,
    T value,
  ) async {
    bool shouldClose = key != WinRegistryService.currentUser;

    try {
      final registryValue = switch (value) {
        final int v => RegistryValue.int32(name, v),
        final String v => RegistryValue.string(name, v),
        final List<String> v => RegistryValue.stringArray(name, v),
        // final List<int> v => RegistryValue.binary(name, Uint8List.fromList(v)),
        final Uint8List v => RegistryValue.binary(name, v),
        final _ => throw ArgumentError(
          '$tag(writeRegistryValue): Unsupported type: ${value.runtimeType}',
        ),
      };
      key.createKey(path).createValue(registryValue);
      logger.i('$tag(writeRegistryValue): $path\\$name = $value');

      if (key == WinRegistryService.currentUser) {
        await shell.run(
          '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /c "reg load HKU\\$defaultUser $defaultUserHivePath"',
        );
        final reg = Registry.allUsers;
        reg.createKey('$defaultUser\\$path').createValue(registryValue);
        logger.i(
          '$tag(writeRegistryValue): $defaultUser\\$path\\$name = $value',
        );
        reg.close();
      }
    } catch (e) {
      logger.e(
        '$tag(writeRegistryValue): $path\\$name',
        error: e,
        stackTrace: StackTrace.current,
      );
    } finally {
      if (shouldClose) {
        key.close();
      }
    }
  }

  static void deleteValue(RegistryKey key, String path, String name) {
    try {
      key.createKey(path).deleteValue(name);
      logger.i('$tag(deleteValue): $path\\$name');
    } catch (e) {
      logger.e(
        '$tag(deleteValue): $path\\$name',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  static void deleteKey(RegistryKey key, String path) {
    try {
      key.deleteKey(path);
      logger.i('$tag(deleteKey): $path');
    } catch (e) {
      logger.e(
        '$tag(deleteKey): $path',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  static void createKey(RegistryKey key, String path) {
    try {
      key.createKey(path);
      logger.i('$tag(createKey): $path');
    } catch (e) {
      logger.e(
        '$tag(createKey): $path',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }
}
