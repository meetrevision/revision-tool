import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/win_updates/updates_service.dart';

class MockWinUpdatesService extends Mock implements WinUpdatesService {}

void main() {
  const skipIntegration = bool.fromEnvironment(
    'SKIP_INTEGRATION',
    defaultValue: true,
  );

  group(
    'WinUpdatesService - Real Implementation',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      late WinUpdatesService service;

      setUp(() {
        service = const WinUpdatesServiceImpl();
      });

      group('Pause Updates', () {
        test('statusPauseUpdatesWU returns a boolean', () {
          expect(service.statusPauseUpdatesWU, isA<bool>());
        });

        test('enablePauseUpdatesWU completes without error', () async {
          await expectLater(service.enablePauseUpdatesWU(), completes);
        });

        test('disablePauseUpdatesWU completes without error', () async {
          await expectLater(service.disablePauseUpdatesWU(), completes);
        });
      });

      group('Visibility', () {
        test('statusVisibilityWU returns a boolean', () {
          expect(service.statusVisibilityWU, isA<bool>());
        });

        test('enableVisibilityWU completes without error', () async {
          await expectLater(service.enableVisibilityWU(), completes);
        });

        test('disableVisibilityWU completes without error', () async {
          await expectLater(service.disableVisibilityWU(), completes);
        });
      });

      group('Drivers', () {
        test('statusDriversWU returns a boolean', () {
          expect(service.statusDriversWU, isA<bool>());
        });

        test('enableDriversWU completes without error', () async {
          await expectLater(service.enableDriversWU(), completes);
        });

        test('disableDriversWU completes without error', () async {
          await expectLater(service.disableDriversWU(), completes);
        });
      });

      group('Service Instance', () {
        test('WinUpdatesService can be instantiated', () {
          expect(() => const WinUpdatesServiceImpl(), returnsNormally);
        });

        test('WinUpdatesService is const constructible', () {
          const service1 = WinUpdatesServiceImpl();
          const service2 = WinUpdatesServiceImpl();
          expect(identical(service1, service2), isTrue);
        });

        test('Multiple instances behave identically', () {
          const service1 = WinUpdatesServiceImpl();
          const service2 = WinUpdatesServiceImpl();

          expect(
            service1.statusPauseUpdatesWU,
            equals(service2.statusPauseUpdatesWU),
          );
          expect(
            service1.statusVisibilityWU,
            equals(service2.statusVisibilityWU),
          );
          expect(service1.statusDriversWU, equals(service2.statusDriversWU));
        });
      });

      group('Method Return Types', () {
        test('All status getters return boolean', () {
          expect(service.statusPauseUpdatesWU, isA<bool>());
          expect(service.statusVisibilityWU, isA<bool>());
          expect(service.statusDriversWU, isA<bool>());
        });

        test('All methods return Future<void>', () async {
          await expectLater(service.enablePauseUpdatesWU(), completes);
          await expectLater(service.disablePauseUpdatesWU(), completes);
          await expectLater(service.enableVisibilityWU(), completes);
          await expectLater(service.disableVisibilityWU(), completes);
          await expectLater(service.enableDriversWU(), completes);
          await expectLater(service.disableDriversWU(), completes);
        });
      });

      group('Feature Coverage', () {
        test('All enable methods are callable', () async {
          await expectLater(service.enablePauseUpdatesWU(), completes);
          await expectLater(service.enableVisibilityWU(), completes);
          await expectLater(service.enableDriversWU(), completes);
        });

        test('All disable methods are callable', () async {
          await expectLater(service.disablePauseUpdatesWU(), completes);
          await expectLater(service.disableVisibilityWU(), completes);
          await expectLater(service.disableDriversWU(), completes);
        });

        test('All status getters are readable', () {
          expect(() => service.statusPauseUpdatesWU, returnsNormally);
          expect(() => service.statusVisibilityWU, returnsNormally);
          expect(() => service.statusDriversWU, returnsNormally);
        });
      });
    },
  );

  group('WinUpdatesService - Mocked (CI Safe)', () {
    late MockWinUpdatesService mockService;

    setUp(() {
      mockService = MockWinUpdatesService();
    });

    group('Pause Updates', () {
      test('statusPauseUpdatesWU can be mocked', () {
        when(() => mockService.statusPauseUpdatesWU).thenReturn(true);
        expect(mockService.statusPauseUpdatesWU, isTrue);
        verify(() => mockService.statusPauseUpdatesWU).called(1);
      });

      test(
        'enablePauseUpdatesWU can be called without system changes',
        () async {
          when(
            () => mockService.enablePauseUpdatesWU(),
          ).thenAnswer((_) async => Future.value());

          await mockService.enablePauseUpdatesWU();
          verify(() => mockService.enablePauseUpdatesWU()).called(1);
        },
      );

      test(
        'disablePauseUpdatesWU can be called without system changes',
        () async {
          when(
            () => mockService.disablePauseUpdatesWU(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disablePauseUpdatesWU();
          verify(() => mockService.disablePauseUpdatesWU()).called(1);
        },
      );
    });

    group('Visibility', () {
      test('statusVisibilityWU can be mocked', () {
        when(() => mockService.statusVisibilityWU).thenReturn(false);
        expect(mockService.statusVisibilityWU, isFalse);
      });

      test('enableVisibilityWU can be called without system changes', () async {
        when(
          () => mockService.enableVisibilityWU(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableVisibilityWU();
        verify(() => mockService.enableVisibilityWU()).called(1);
      });

      test(
        'disableVisibilityWU can be called without system changes',
        () async {
          when(
            () => mockService.disableVisibilityWU(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableVisibilityWU();
          verify(() => mockService.disableVisibilityWU()).called(1);
        },
      );
    });

    group('Drivers', () {
      test('statusDriversWU can be mocked', () {
        when(() => mockService.statusDriversWU).thenReturn(true);
        expect(mockService.statusDriversWU, isTrue);
      });

      test('enableDriversWU can be called without system changes', () async {
        when(
          () => mockService.enableDriversWU(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableDriversWU();
        verify(() => mockService.enableDriversWU()).called(1);
      });

      test('disableDriversWU can be called without system changes', () async {
        when(
          () => mockService.disableDriversWU(),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableDriversWU();
        verify(() => mockService.disableDriversWU()).called(1);
      });
    });

    group('Call Order Verification', () {
      test('can verify method call order', () async {
        when(() => mockService.statusPauseUpdatesWU).thenReturn(true);
        when(
          () => mockService.disableVisibilityWU(),
        ).thenAnswer((_) async => Future.value());
        when(() => mockService.statusDriversWU).thenReturn(false);

        final pauseStatus = mockService.statusPauseUpdatesWU;
        await mockService.disableVisibilityWU();
        final driverStatus = mockService.statusDriversWU;

        expect(pauseStatus, isTrue);
        expect(driverStatus, isFalse);

        verifyInOrder([
          () => mockService.statusPauseUpdatesWU,
          () => mockService.disableVisibilityWU(),
          () => mockService.statusDriversWU,
        ]);
      });

      test('can verify a method was never called', () {
        when(
          () => mockService.enablePauseUpdatesWU(),
        ).thenAnswer((_) async => Future.value());

        verifyNever(() => mockService.disablePauseUpdatesWU());
      });

      test('can verify multiple calls to same method', () {
        when(() => mockService.statusVisibilityWU).thenReturn(true);

        mockService.statusVisibilityWU;
        mockService.statusVisibilityWU;
        mockService.statusVisibilityWU;

        verify(() => mockService.statusVisibilityWU).called(3);
      });
    });

    group('State Transitions', () {
      test('can simulate enable/disable cycle for pause updates', () async {
        when(() => mockService.statusPauseUpdatesWU).thenReturn(false);
        when(
          () => mockService.enablePauseUpdatesWU(),
        ).thenAnswer((_) async => Future.value());

        expect(mockService.statusPauseUpdatesWU, isFalse);
        await mockService.enablePauseUpdatesWU();

        when(() => mockService.statusPauseUpdatesWU).thenReturn(true);
        expect(mockService.statusPauseUpdatesWU, isTrue);
      });

      test('can simulate enable/disable cycle for visibility', () async {
        when(() => mockService.statusVisibilityWU).thenReturn(true);
        when(
          () => mockService.disableVisibilityWU(),
        ).thenAnswer((_) async => Future.value());

        expect(mockService.statusVisibilityWU, isTrue);
        await mockService.disableVisibilityWU();

        when(() => mockService.statusVisibilityWU).thenReturn(false);
        expect(mockService.statusVisibilityWU, isFalse);
      });

      test('can simulate enable/disable cycle for drivers', () async {
        when(() => mockService.statusDriversWU).thenReturn(false);
        when(
          () => mockService.enableDriversWU(),
        ).thenAnswer((_) async => Future.value());

        expect(mockService.statusDriversWU, isFalse);
        await mockService.enableDriversWU();

        when(() => mockService.statusDriversWU).thenReturn(true);
        expect(mockService.statusDriversWU, isTrue);
      });
    });
  });
}
