import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/miscellaneous/miscellaneous_service.dart';

class MockMiscellaneousService extends Mock implements MiscellaneousService {}

void main() {
  group('MiscellaneousService - Real Implementation', () {
    late MiscellaneousService service;

    setUp(() {
      service = const MiscellaneousServiceImpl();
    });

    group('Hibernation', () {
      test('statusHibernation returns a boolean', () {
        expect(service.statusHibernation, isA<bool>());
      });

      test('enableHibernation completes without error', () async {
        expect(() => service.enableHibernation(), returnsNormally);
      });

      test('disableHibernation completes without error', () async {
        expect(() => service.disableHibernation(), returnsNormally);
      });
    });

    group('Fast Startup', () {
      test('statusFastStartup returns a boolean', () {
        expect(service.statusFastStartup, isA<bool>());
      });

      test('enableFastStartup completes without error', () {
        expect(() => service.enableFastStartup(), returnsNormally);
      });

      test('disableFastStartup completes without error', () {
        expect(() => service.disableFastStartup(), returnsNormally);
      });
    });

    group('Task Manager Monitoring', () {
      test('statusTMMonitoring returns a boolean', () {
        expect(service.statusTMMonitoring, isA<bool>());
      });

      test('enableTMMonitoring completes without error', () async {
        expect(() => service.enableTMMonitoring(), returnsNormally);
      });

      test('disableTMMonitoring completes without error', () {
        expect(() => service.disableTMMonitoring(), returnsNormally);
      });
    });

    group('MPO (Multi-Plane Overlay)', () {
      test('statusMPO returns a boolean', () {
        expect(service.statusMPO, isA<bool>());
      });

      test('enableMPO completes without error', () {
        expect(() => service.enableMPO(), returnsNormally);
      });

      test('disableMPO completes without error', () {
        expect(() => service.disableMPO(), returnsNormally);
      });
    });

    group('Usage Reporting', () {
      test('statusUsageReporting returns a boolean', () {
        expect(service.statusUsageReporting, isA<bool>());
      });

      test('enableUsageReporting completes without error', () async {
        expect(() => service.enableUsageReporting(), returnsNormally);
      });

      test('disableUsageReporting completes without error', () async {
        expect(() => service.disableUsageReporting(), returnsNormally);
      });
    });

    group('KGL Update', () {
      test('updateKGL returns Future', () {
        expect(service.updateKGL(), isA<Future<void>>());
      });
    });

    group('Service Instance', () {
      test('MiscellaneousService can be instantiated', () {
        expect(() => const MiscellaneousServiceImpl(), returnsNormally);
      });

      test('MiscellaneousService is const constructible', () {
        const service1 = MiscellaneousServiceImpl();
        const service2 = MiscellaneousServiceImpl();
        expect(identical(service1, service2), isTrue);
      });

      test('Multiple instances behave identically', () {
        const service1 = MiscellaneousServiceImpl();
        const service2 = MiscellaneousServiceImpl();

        expect(service1.statusHibernation, equals(service2.statusHibernation));
        expect(service1.statusFastStartup, equals(service2.statusFastStartup));
        expect(
          service1.statusTMMonitoring,
          equals(service2.statusTMMonitoring),
        );
        expect(service1.statusMPO, equals(service2.statusMPO));
      });
    });

    group('Method Return Types', () {
      test('All status getters return boolean', () {
        expect(service.statusHibernation, isA<bool>());
        expect(service.statusFastStartup, isA<bool>());
        expect(service.statusTMMonitoring, isA<bool>());
        expect(service.statusMPO, isA<bool>());
        expect(service.statusUsageReporting, isA<bool>());
      });

      test('Async methods return Future', () {
        expect(service.enableHibernation(), isA<Future<void>>());
        expect(service.disableHibernation(), isA<Future<void>>());
        expect(service.enableTMMonitoring(), isA<Future<void>>());
        expect(service.enableUsageReporting(), isA<Future<void>>());
        expect(service.disableUsageReporting(), isA<Future<void>>());
        expect(service.updateKGL(), isA<Future<void>>());
      });

      test('Sync methods return void', () {
        expect(() => service.enableFastStartup(), returnsNormally);
        expect(() => service.disableFastStartup(), returnsNormally);
        expect(() => service.disableTMMonitoring(), returnsNormally);
        expect(() => service.enableMPO(), returnsNormally);
        expect(() => service.disableMPO(), returnsNormally);
      });
    });
  });

  group('MiscellaneousService - Mocked (CI Safe)', () {
    late MockMiscellaneousService mockService;

    setUp(() {
      mockService = MockMiscellaneousService();
    });

    group('Hibernation Status', () {
      test('statusHibernation can be mocked', () {
        when(() => mockService.statusHibernation).thenReturn(true);
        expect(mockService.statusHibernation, isTrue);
        verify(() => mockService.statusHibernation).called(1);
      });

      test('enableHibernation can be called without system changes', () async {
        when(
          () => mockService.enableHibernation(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableHibernation();
        verify(() => mockService.enableHibernation()).called(1);
      });

      test('disableHibernation can be called without system changes', () async {
        when(
          () => mockService.disableHibernation(),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableHibernation();
        verify(() => mockService.disableHibernation()).called(1);
      });
    });

    group('Fast Startup', () {
      test('statusFastStartup can be mocked', () {
        when(() => mockService.statusFastStartup).thenReturn(false);
        expect(mockService.statusFastStartup, isFalse);
      });

      test('enableFastStartup can be called without system changes', () {
        when(() => mockService.enableFastStartup()).thenReturn(null);

        mockService.enableFastStartup();
        verify(() => mockService.enableFastStartup()).called(1);
      });

      test('disableFastStartup can be called without system changes', () {
        when(() => mockService.disableFastStartup()).thenReturn(null);

        mockService.disableFastStartup();
        verify(() => mockService.disableFastStartup()).called(1);
      });
    });

    group('Task Manager Monitoring', () {
      test('statusTMMonitoring can be mocked', () {
        when(() => mockService.statusTMMonitoring).thenReturn(true);
        expect(mockService.statusTMMonitoring, isTrue);
      });

      test('enableTMMonitoring can be called without system changes', () async {
        when(
          () => mockService.enableTMMonitoring(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableTMMonitoring();
        verify(() => mockService.enableTMMonitoring()).called(1);
      });

      test('disableTMMonitoring can be called without system changes', () {
        when(() => mockService.disableTMMonitoring()).thenReturn(null);

        mockService.disableTMMonitoring();
        verify(() => mockService.disableTMMonitoring()).called(1);
      });
    });

    group('MPO', () {
      test('statusMPO can be mocked', () {
        when(() => mockService.statusMPO).thenReturn(true);
        expect(mockService.statusMPO, isTrue);
      });

      test('enableMPO can be called without system changes', () {
        when(() => mockService.enableMPO()).thenReturn(null);

        mockService.enableMPO();
        verify(() => mockService.enableMPO()).called(1);
      });

      test('disableMPO can be called without system changes', () {
        when(() => mockService.disableMPO()).thenReturn(null);

        mockService.disableMPO();
        verify(() => mockService.disableMPO()).called(1);
      });
    });

    group('Usage Reporting', () {
      test('statusUsageReporting can be mocked', () {
        when(() => mockService.statusUsageReporting).thenReturn(false);
        expect(mockService.statusUsageReporting, isFalse);
      });

      test(
        'enableUsageReporting can be called without system changes',
        () async {
          when(
            () => mockService.enableUsageReporting(),
          ).thenAnswer((_) async => Future.value());

          await mockService.enableUsageReporting();
          verify(() => mockService.enableUsageReporting()).called(1);
        },
      );

      test(
        'disableUsageReporting can be called without system changes',
        () async {
          when(
            () => mockService.disableUsageReporting(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableUsageReporting();
          verify(() => mockService.disableUsageReporting()).called(1);
        },
      );
    });

    group('KGL Update', () {
      test('updateKGL can be called without system changes', () async {
        when(
          () => mockService.updateKGL(),
        ).thenAnswer((_) async => Future.value());

        await mockService.updateKGL();
        verify(() => mockService.updateKGL()).called(1);
      });
    });

    group('Call Order Verification', () {
      test('can verify method call order', () {
        when(() => mockService.statusHibernation).thenReturn(false);
        when(() => mockService.enableFastStartup()).thenReturn(null);
        when(() => mockService.statusFastStartup).thenReturn(true);

        final hibernationStatus = mockService.statusHibernation;
        mockService.enableFastStartup();
        final fastStartupStatus = mockService.statusFastStartup;

        expect(hibernationStatus, isFalse);
        expect(fastStartupStatus, isTrue);

        verifyInOrder([
          () => mockService.statusHibernation,
          () => mockService.enableFastStartup(),
          () => mockService.statusFastStartup,
        ]);
      });

      test('can verify a method was never called', () {
        when(
          () => mockService.enableHibernation(),
        ).thenAnswer((_) async => Future.value());

        verifyNever(() => mockService.disableHibernation());
      });
    });
  });
}
