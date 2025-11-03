import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/security/security_service.dart';

class MockSecurityService extends Mock implements SecurityService {}

void main() {
  const skipIntegration = bool.fromEnvironment(
    'SKIP_INTEGRATION',
    defaultValue: true,
  );

  group(
    'SecurityService (Real Implementation)',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      late SecurityService service;

      setUp(() {
        service = const SecurityServiceImpl();
      });

      group('Windows Defender', () {
        test('statusDefender returns a boolean', () {
          expect(service.statusDefender, isA<bool>());
        });

        test('statusDefenderProtections returns a boolean', () {
          expect(service.statusDefenderProtections, isA<bool>());
        });

        test('statusDefenderProtectionTamper returns a boolean', () {
          expect(service.statusDefenderProtectionTamper, isA<bool>());
        });

        test('statusDefenderProtectionRealtime returns a boolean', () {
          expect(service.statusDefenderProtectionRealtime, isA<bool>());
        });

        test('enableDefender completes without error', () async {
          await expectLater(service.enableDefender(), completes);
        });

        test('disableDefender completes without error', () async {
          await expectLater(service.disableDefender(), completes);
        });

        test('openDefenderThreatSettings returns ProcessResult', () async {
          expect(service.openDefenderThreatSettings(), isA<Future<dynamic>>());
        });
      });

      group('UAC (User Account Control)', () {
        test('statusUAC returns a boolean', () {
          expect(service.statusUAC, isA<bool>());
        });

        test('enableUAC completes without error', () async {
          await expectLater(service.enableUAC(), completes);
        });

        test('disableUAC completes without error', () async {
          await expectLater(service.disableUAC(), completes);
        });
      });

      group('CPU Mitigations', () {
        test('isMitigationEnabled accepts Meltdown/Spectre mitigation', () {
          expect(
            service.isMitigationEnabled(Mitigation.meltdownSpectre),
            isA<bool>(),
          );
        });

        test('isMitigationEnabled accepts Downfall mitigation', () {
          expect(service.isMitigationEnabled(Mitigation.downfall), isA<bool>());
        });

        test('enableMitigation completes for Meltdown/Spectre', () async {
          await expectLater(
            service.enableMitigation(Mitigation.meltdownSpectre),
            completes,
          );
        });

        test('enableMitigation completes for Downfall', () async {
          await expectLater(
            service.enableMitigation(Mitigation.downfall),
            completes,
          );
        });

        test('disableMitigation completes for Meltdown/Spectre', () async {
          await expectLater(
            service.disableMitigation(Mitigation.meltdownSpectre),
            completes,
          );
        });

        test('disableMitigation completes for Downfall', () async {
          await expectLater(
            service.disableMitigation(Mitigation.downfall),
            completes,
          );
        });
      });

      group('Certificates', () {
        test('updateCertificates completes without error', () async {
          await expectLater(service.updateCertificates(), completes);
        });
      });

      group('Service Instance', () {
        test('SecurityService can be instantiated', () {
          expect(() => const SecurityServiceImpl(), returnsNormally);
        });

        test('SecurityService is const constructible', () {
          const service1 = SecurityServiceImpl();
          const service2 = SecurityServiceImpl();
          expect(identical(service1, service2), isTrue);
        });

        test('Multiple instances behave identically', () {
          const service1 = SecurityServiceImpl();
          const service2 = SecurityServiceImpl();

          // Both should read the same registry values
          expect(service1.statusDefender, equals(service2.statusDefender));
          expect(service1.statusUAC, equals(service2.statusUAC));
        });
      });

      group('Method Return Types', () {
        test('All status getters return boolean', () {
          expect(service.statusDefender, isA<bool>());
          expect(service.statusDefenderProtections, isA<bool>());
          expect(service.statusDefenderProtectionTamper, isA<bool>());
          expect(service.statusDefenderProtectionRealtime, isA<bool>());
          expect(service.statusUAC, isA<bool>());
          expect(
            service.isMitigationEnabled(Mitigation.meltdownSpectre),
            isA<bool>(),
          );
          expect(service.isMitigationEnabled(Mitigation.downfall), isA<bool>());
        });

        test('All methods return Future', () {
          expect(service.enableDefender(), isA<Future<void>>());
          expect(service.disableDefender(), isA<Future<void>>());
          expect(service.openDefenderThreatSettings(), isA<Future<dynamic>>());
          expect(service.updateCertificates(), isA<Future<void>>());
          expect(service.enableUAC(), isA<Future<void>>());
          expect(service.disableUAC(), isA<Future<void>>());
          expect(
            service.enableMitigation(Mitigation.meltdownSpectre),
            isA<Future<void>>(),
          );
          expect(
            service.disableMitigation(Mitigation.meltdownSpectre),
            isA<Future<void>>(),
          );
        });
      });

      group('Mitigation Enum', () {
        test('Mitigation enum has all expected values', () {
          expect(Mitigation.values.length, equals(2));
          expect(Mitigation.values, contains(Mitigation.meltdownSpectre));
          expect(Mitigation.values, contains(Mitigation.downfall));
        });

        test('Meltdown/Spectre bitmask is correct', () {
          expect(Mitigation.meltdownSpectre.bitmask, equals(0x00000003));
        });

        test('Downfall bitmask is correct', () {
          expect(Mitigation.downfall.bitmask, equals(0x02000000));
        });
      });
    },
  );

  group('SecurityService - Mocked (CI Safe)', () {
    late MockSecurityService mockService;

    setUp(() {
      mockService = MockSecurityService();
    });

    group('Windows Defender Status', () {
      test('statusDefender can be mocked', () {
        when(() => mockService.statusDefender).thenReturn(true);
        expect(mockService.statusDefender, isTrue);
        verify(() => mockService.statusDefender).called(1);
      });

      test('statusDefenderProtections can be mocked', () {
        when(() => mockService.statusDefenderProtections).thenReturn(false);
        expect(mockService.statusDefenderProtections, isFalse);
        verify(() => mockService.statusDefenderProtections).called(1);
      });

      test('statusDefenderProtectionTamper can be mocked', () {
        when(() => mockService.statusDefenderProtectionTamper).thenReturn(true);
        expect(mockService.statusDefenderProtectionTamper, isTrue);
      });

      test('statusDefenderProtectionRealtime can be mocked', () {
        when(
          () => mockService.statusDefenderProtectionRealtime,
        ).thenReturn(false);
        expect(mockService.statusDefenderProtectionRealtime, isFalse);
      });
    });

    group('Windows Defender Actions', () {
      test('enableDefender can be called without system changes', () async {
        when(
          () => mockService.enableDefender(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableDefender();
        verify(() => mockService.enableDefender()).called(1);
      });

      test('disableDefender can be called without system changes', () async {
        when(
          () => mockService.disableDefender(),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableDefender();
        verify(() => mockService.disableDefender()).called(1);
      });

      test('openDefenderThreatSettings returns mocked ProcessResult', () async {
        final mockResult = ProcessResult(0, 0, '', '');
        when(
          () => mockService.openDefenderThreatSettings(),
        ).thenAnswer((_) async => mockResult);

        final result = await mockService.openDefenderThreatSettings();
        expect(result, equals(mockResult));
        verify(() => mockService.openDefenderThreatSettings()).called(1);
      });
    });

    group('UAC Actions', () {
      test('statusUAC can be mocked', () {
        when(() => mockService.statusUAC).thenReturn(true);
        expect(mockService.statusUAC, isTrue);
      });

      test('enableUAC can be called without system changes', () async {
        when(
          () => mockService.enableUAC(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableUAC();
        verify(() => mockService.enableUAC()).called(1);
      });

      test('disableUAC can be called without system changes', () async {
        when(
          () => mockService.disableUAC(),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableUAC();
        verify(() => mockService.disableUAC()).called(1);
      });
    });

    group('CPU Mitigations', () {
      test('isMitigationEnabled can be mocked', () {
        when(
          () => mockService.isMitigationEnabled(Mitigation.meltdownSpectre),
        ).thenReturn(true);
        expect(
          mockService.isMitigationEnabled(Mitigation.meltdownSpectre),
          isTrue,
        );

        when(
          () => mockService.isMitigationEnabled(Mitigation.downfall),
        ).thenReturn(false);
        expect(mockService.isMitigationEnabled(Mitigation.downfall), isFalse);
      });

      test('enableMitigation can be called without system changes', () async {
        when(
          () => mockService.enableMitigation(Mitigation.meltdownSpectre),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableMitigation(Mitigation.meltdownSpectre);
        verify(
          () => mockService.enableMitigation(Mitigation.meltdownSpectre),
        ).called(1);
      });

      test('disableMitigation can be called without system changes', () async {
        when(
          () => mockService.disableMitigation(Mitigation.downfall),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableMitigation(Mitigation.downfall);
        verify(
          () => mockService.disableMitigation(Mitigation.downfall),
        ).called(1);
      });
    });

    group('Certificates', () {
      test('updateCertificates can be called without system changes', () async {
        when(
          () => mockService.updateCertificates(),
        ).thenAnswer((_) async => Future.value());

        await mockService.updateCertificates();
        verify(() => mockService.updateCertificates()).called(1);
      });
    });

    group('Call Order Verification', () {
      test('can verify method call order', () async {
        when(() => mockService.statusDefender).thenReturn(false);
        when(
          () => mockService.enableUAC(),
        ).thenAnswer((_) async => Future.value());
        when(() => mockService.statusUAC).thenReturn(true);

        // Execute in specific order
        final defenderStatus = mockService.statusDefender;
        await mockService.enableUAC();
        final uacStatus = mockService.statusUAC;

        expect(defenderStatus, isFalse);
        expect(uacStatus, isTrue);

        verifyInOrder([
          () => mockService.statusDefender,
          () => mockService.enableUAC(),
          () => mockService.statusUAC,
        ]);
      });

      test('can verify a method was never called', () {
        when(
          () => mockService.enableDefender(),
        ).thenAnswer((_) async => Future.value());

        // Don't call disableDefender
        verifyNever(() => mockService.disableDefender());
      });
    });
  });
}
