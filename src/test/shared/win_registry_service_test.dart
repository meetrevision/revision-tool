import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:win32_registry/win32_registry.dart';

const String testRegistryPath = r'SOFTWARE\Revision\RevitoolTest';

void main() {
  const skipIntegration = bool.fromEnvironment(
    'SKIP_INTEGRATION',
    defaultValue: true,
  );

  setUpAll(() {
    if (skipIntegration) return;
    try {
      Registry.currentUser.createKey(testRegistryPath);
    } catch (_) {}
  });
  tearDownAll(() {
    if (skipIntegration) return;
    try {
      Registry.currentUser.deleteKey(testRegistryPath, recursive: true);
    } catch (_) {}
  });

  group(
    'WinRegistryService - Static Properties',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('buildNumber is initialized and non-zero', () {
        expect(WinRegistryService.buildNumber, greaterThan(0));
        expect(WinRegistryService.buildNumber, isA<int>());
      });

      test('isW11 returns boolean based on buildNumber', () {
        expect(WinRegistryService.isW11, isA<bool>());
        if (WinRegistryService.buildNumber > 19045) {
          expect(WinRegistryService.isW11, isTrue);
        } else {
          expect(WinRegistryService.isW11, isFalse);
        }
      });

      test('cpuArch is not null and is lowercase', () {
        expect(WinRegistryService.cpuArch, isNotNull);
        expect(WinRegistryService.cpuArch, isNotEmpty);
        expect(
          WinRegistryService.cpuArch,
          equals(WinRegistryService.cpuArch.toLowerCase()),
        );
        expect(
          WinRegistryService.cpuArch,
          anyOf(['amd64', 'x86', 'arm64', 'arm']),
        );
      });

      test('CPU vendor flags are mutually exclusive', () {
        if (WinRegistryService.isIntelCpu) {
          expect(WinRegistryService.isAmdCpu, isFalse);
        }
        if (WinRegistryService.isAmdCpu) {
          expect(WinRegistryService.isIntelCpu, isFalse);
        }
      });

      test('currentUser is accessible', () {
        expect(WinRegistryService.currentUser, isNotNull);
        expect(WinRegistryService.currentUser, isA<RegistryKey>());
      });

      test('defaultUser constant is defined', () {
        expect(WinRegistryService.defaultUser, equals('DefaultUserHive'));
      });

      test('defaultUserHivePath is valid path', () {
        expect(
          WinRegistryService.defaultUserHivePath,
          equals(r'C:\Users\Default\NTUSER.DAT'),
        );
        expect(WinRegistryService.defaultUserHivePath, contains(r':\'));
      });

      test('isSupported returns boolean', () {
        expect(WinRegistryService.isSupported, isA<bool>());
      });

      test('themeTransparencyEffect returns boolean', () {
        expect(WinRegistryService.themeTransparencyEffect, isA<bool>());
      });

      test('themeModeReg returns nullable string', () {
        final themeMode = WinRegistryService.themeModeReg;
        expect(themeMode, anyOf([isNull, isA<String>()]));
      });
    },
  );

  group(
    'WinRegistryService - Read Operations',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('readString returns null for non-existent key', () {
        final result = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\NonExistentKey\SubKey',
          'NonExistentValue',
        );
        expect(result, isNull);
      });

      test('readString returns null for non-existent value', () {
        final result = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'NonExistentValue12345',
        );
        expect(result, isNull);
      });

      test('readString returns string for existing value', () {
        final result = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'CurrentBuildNumber',
        );
        expect(result, isNotNull);
        expect(result, isA<String>());
        expect(result, isNotEmpty);
        expect(int.parse(result!), greaterThan(0));
      });

      test('readInt returns null for non-existent key', () {
        final result = WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\NonExistentKey\SubKey',
          'NonExistentValue',
        );
        expect(result, isNull);
      });

      test('readInt returns null for non-existent value', () {
        final result = WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'NonExistentIntValue12345',
        );
        expect(result, isNull);
      });

      test('readInt returns integer for existing value', () {
        // Test with a known integer registry value
        final result = WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
          'EnableTransparency',
        );
        // Result could be null if value doesn't exist, or 0 or 1
        expect(result, anyOf([isNull, 0, 1]));
        if (result != null) {
          expect(result, isA<int>());
        }
      });

      test('readBinary returns null for non-existent key', () {
        final result = WinRegistryService.readBinary(
          RegistryHive.localMachine,
          r'SOFTWARE\NonExistentKey\SubKey',
          'NonExistentValue',
        );
        expect(result, isNull);
      });

      test('readBinary returns null for non-existent value', () {
        final result = WinRegistryService.readBinary(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'NonExistentBinaryValue12345',
        );
        expect(result, isNull);
      });

      test('readBinary returns Uint8List when value exists', () {
        final result = WinRegistryService.readBinary(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'DigitalProductId',
        );
        if (result != null) {
          expect(result, isA<Uint8List>());
          expect(result.isNotEmpty, isTrue);
        }
      });

      test('read operations handle different registry hives', () {
        final lmResult = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'ProductName',
        );
        expect(lmResult, isNotNull);

        final cuResult = WinRegistryService.readString(
          RegistryHive.currentUser,
          r'Environment',
          'TEMP',
        );
        expect(cuResult, anyOf([isNull, isA<String>()]));
      });
    },
  );

  group(
    'WinRegistryService - Null Safety',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('readString handles null safely', () {
        String? result;
        expect(
          () => result = WinRegistryService.readString(
            RegistryHive.localMachine,
            r'SOFTWARE\NonExistent',
            'Value',
          ),
          returnsNormally,
        );
        expect(result, isNull);
      });

      test('readInt handles null safely', () {
        int? result;
        expect(
          () => result = WinRegistryService.readInt(
            RegistryHive.localMachine,
            r'SOFTWARE\NonExistent',
            'Value',
          ),
          returnsNormally,
        );
        expect(result, isNull);
      });

      test('readBinary handles null safely', () {
        Uint8List? result;
        expect(
          () => result = WinRegistryService.readBinary(
            RegistryHive.localMachine,
            r'SOFTWARE\NonExistent',
            'Value',
          ),
          returnsNormally,
        );
        expect(result, isNull);
      });

      test(
        'null checks prevent crashes when accessing build-dependent values',
        () {
          expect(() => WinRegistryService.buildNumber, returnsNormally);
          expect(WinRegistryService.buildNumber, isNotNull);
          expect(WinRegistryService.buildNumber, isA<int>());
          expect(WinRegistryService.buildNumber, greaterThan(0));
        },
      );

      test('CPU architecture never returns null', () {
        expect(WinRegistryService.cpuArch, isNotNull);
        expect(WinRegistryService.cpuArch, isNotEmpty);
      });
    },
  );

  group(
    'WinRegistryService - getUserServices',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('getUserServices returns iterable', () {
        final result = WinRegistryService.getUserServices('WpnUserService');
        expect(result, isA<Iterable<String>>());
      });

      test('getUserServices filters by prefix', () {
        final result = WinRegistryService.getUserServices('WpnUserService');
        for (final service in result) {
          expect(service, startsWith('WpnUserService'));
        }
      });

      test('getUserServices returns empty for non-existent service', () {
        final result = WinRegistryService.getUserServices(
          'NonExistentService12345',
        );
        expect(result, isEmpty);
      });

      test('getUserServices handles common services', () {
        final wpnServices = WinRegistryService.getUserServices(
          'WpnUserService',
        );
        expect(wpnServices, isA<Iterable<String>>());
      });
    },
  );

  group(
    'WinRegistryService - Page Visibility Methods',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('hidePageVisibilitySettings handles null current value', () async {
        await expectLater(
          WinRegistryService.hidePageVisibilitySettings('test-page'),
          completes,
        );
      });

      test('unhidePageVisibilitySettings handles null current value', () async {
        await expectLater(
          WinRegistryService.unhidePageVisibilitySettings('test-page'),
          completes,
        );
      });

      test('hidePageVisibilitySettings handles empty string', () async {
        await expectLater(
          WinRegistryService.hidePageVisibilitySettings(''),
          completes,
        );
      });

      test('unhidePageVisibilitySettings handles empty string', () async {
        await expectLater(
          WinRegistryService.unhidePageVisibilitySettings(''),
          completes,
        );
      });
    },
  );

  group(
    'WinRegistryService - Write Operations',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('writeRegistryValue accepts int type', () async {
        await expectLater(
          WinRegistryService.writeRegistryValue(
            Registry.currentUser,
            testRegistryPath,
            'TestIntValue',
            123,
          ),
          completes,
        );
      });

      test('writeRegistryValue accepts String type', () async {
        await expectLater(
          WinRegistryService.writeRegistryValue(
            Registry.currentUser,
            testRegistryPath,
            'TestStringValue',
            'test',
          ),
          completes,
        );
      });

      test('writeRegistryValue accepts List<String> type', () async {
        await expectLater(
          WinRegistryService.writeRegistryValue(
            Registry.currentUser,
            testRegistryPath,
            'TestStringArrayValue',
            ['test1', 'test2'],
          ),
          completes,
        );
      });

      test('writeRegistryValue accepts Uint8List type', () async {
        await expectLater(
          WinRegistryService.writeRegistryValue(
            Registry.currentUser,
            testRegistryPath,
            'TestBinaryValue',
            Uint8List.fromList([1, 2, 3, 4]),
          ),
          completes,
        );
      });

      test('deleteValue handles non-existent value gracefully', () async {
        await expectLater(
          WinRegistryService.deleteValue(
            Registry.currentUser,
            testRegistryPath,
            'NonExistentValue12345',
          ),
          completes,
        );
      });

      test('deleteKey handles non-existent key gracefully', () async {
        await expectLater(
          WinRegistryService.deleteKey(
            Registry.currentUser,
            r'SOFTWARE\Revision\NonExistentKey12345',
          ),
          completes,
        );
      });

      test('createKey creates key without crashing', () {
        expect(
          () => WinRegistryService.createKey(
            Registry.currentUser,
            '$testRegistryPath\\SubKey',
          ),
          returnsNormally,
        );
      });

      test('read back written values', () async {
        await WinRegistryService.writeRegistryValue(
          Registry.currentUser,
          testRegistryPath,
          'TestReadBackInt',
          456,
        );

        await WinRegistryService.writeRegistryValue(
          Registry.currentUser,
          testRegistryPath,
          'TestReadBackString',
          'hello',
        );

        final intValue = WinRegistryService.readInt(
          RegistryHive.currentUser,
          testRegistryPath,
          'TestReadBackInt',
        );
        expect(intValue, equals(456));

        final stringValue = WinRegistryService.readString(
          RegistryHive.currentUser,
          testRegistryPath,
          'TestReadBackString',
        );
        expect(stringValue, equals('hello'));
      });
    },
  );

  group(
    'WinRegistryService - Error Handling',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('read operations never throw exceptions', () {
        expect(
          () => WinRegistryService.readString(
            RegistryHive.currentUser,
            r'SOFTWARE\Revision\INVALID\PATH\THAT\DOES\NOT\EXIST',
            'Value',
          ),
          returnsNormally,
        );

        expect(
          () => WinRegistryService.readInt(
            RegistryHive.currentUser,
            r'SOFTWARE\Revision\INVALID\PATH\THAT\DOES\NOT\EXIST',
            'Value',
          ),
          returnsNormally,
        );

        expect(
          () => WinRegistryService.readBinary(
            RegistryHive.currentUser,
            r'SOFTWARE\Revision\INVALID\PATH\THAT\DOES\NOT\EXIST',
            'Value',
          ),
          returnsNormally,
        );
      });

      test('write operations handle errors gracefully', () async {
        await expectLater(
          WinRegistryService.deleteValue(
            Registry.currentUser,
            r'SOFTWARE\Revision\NonExistent\Path\That\Does\Not\Exist',
            'Value',
          ),
          completes,
        );

        await expectLater(
          WinRegistryService.deleteKey(
            Registry.currentUser,
            r'SOFTWARE\Revision\NonExistent\Path\That\Does\Not\Exist',
          ),
          completes,
        );
      });

      test('getUserServices handles invalid service names', () {
        expect(() => WinRegistryService.getUserServices(''), returnsNormally);

        expect(
          () => WinRegistryService.getUserServices('Invalid\\Service\\Name'),
          returnsNormally,
        );
      });
    },
  );

  group(
    'WinRegistryService - Integration Tests',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('buildNumber matches CurrentBuildNumber in registry', () {
        final registryBuildNumber = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          'CurrentBuildNumber',
        );
        expect(registryBuildNumber, isNotNull);
        expect(
          WinRegistryService.buildNumber,
          equals(int.parse(registryBuildNumber!)),
        );
      });

      test('cpuArch matches registry value', () {
        final registryArch = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
          'PROCESSOR_ARCHITECTURE',
        );
        expect(registryArch, isNotNull);
        expect(WinRegistryService.cpuArch, equals(registryArch!.toLowerCase()));
      });

      test('themeTransparencyEffect matches registry EnableTransparency', () {
        final registryValue = WinRegistryService.readInt(
          RegistryHive.currentUser,
          r'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
          'EnableTransparency',
        );

        if (registryValue != null) {
          expect(
            WinRegistryService.themeTransparencyEffect,
            equals(registryValue == 1),
          );
        }
      });

      test('static properties are consistent across multiple accesses', () {
        final build1 = WinRegistryService.buildNumber;
        final build2 = WinRegistryService.buildNumber;
        expect(build1, equals(build2));

        final arch1 = WinRegistryService.cpuArch;
        final arch2 = WinRegistryService.cpuArch;
        expect(arch1, equals(arch2));

        final w11_1 = WinRegistryService.isW11;
        final w11_2 = WinRegistryService.isW11;
        expect(w11_1, equals(w11_2));
      });
    },
  );

  group(
    'WinRegistryService - Regression Tests for Null Issues',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      test('REGRESSION: buildNumber never returns null', () {
        expect(WinRegistryService.buildNumber, isNotNull);
        expect(WinRegistryService.buildNumber, isA<int>());
        expect(WinRegistryService.buildNumber, greaterThan(0));
      });

      test('REGRESSION: cpuArch never returns null or empty', () {
        expect(WinRegistryService.cpuArch, isNotNull);
        expect(WinRegistryService.cpuArch, isNotEmpty);
        expect(WinRegistryService.cpuArch, isA<String>());
      });

      test('REGRESSION: read methods return null instead of throwing', () {
        // Ensure null is returned, not an exception
        final stringResult = WinRegistryService.readString(
          RegistryHive.localMachine,
          r'SOFTWARE\NonExistent',
          'Value',
        );
        expect(stringResult, isNull);

        final intResult = WinRegistryService.readInt(
          RegistryHive.localMachine,
          r'SOFTWARE\NonExistent',
          'Value',
        );
        expect(intResult, isNull);

        final binaryResult = WinRegistryService.readBinary(
          RegistryHive.localMachine,
          r'SOFTWARE\NonExistent',
          'Value',
        );
        expect(binaryResult, isNull);
      });

      test('REGRESSION: static initializers handle missing registry keys', () {
        expect(() => WinRegistryService.buildNumber, returnsNormally);
        expect(() => WinRegistryService.cpuArch, returnsNormally);
        expect(() => WinRegistryService.isW11, returnsNormally);
        expect(() => WinRegistryService.isIntelCpu, returnsNormally);
        expect(() => WinRegistryService.isAmdCpu, returnsNormally);
        expect(() => WinRegistryService.isSupported, returnsNormally);
        expect(() => WinRegistryService.currentUser, returnsNormally);
      });

      test('REGRESSION: null-related operations never crash the app', () async {
        expect(() async {
          WinRegistryService.readString(RegistryHive.localMachine, '', '');
          WinRegistryService.readInt(RegistryHive.localMachine, '', '');
          WinRegistryService.readBinary(RegistryHive.localMachine, '', '');
          WinRegistryService.getUserServices('');
          await WinRegistryService.hidePageVisibilitySettings('');
          await WinRegistryService.unhidePageVisibilitySettings('');
        }, returnsNormally);
      });
    },
  );
}
