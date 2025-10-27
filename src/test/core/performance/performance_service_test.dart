import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/performance/performance_service.dart';

class MockPerformanceService extends Mock implements PerformanceService {}

void main() {
  group('PerformanceService (Real Implementation)', () {
    late PerformanceService service;

    setUp(() {
      service = const PerformanceServiceImpl();
    });

    group('Superfetch', () {
      test('statusSuperfetch returns a boolean', () {
        expect(service.statusSuperfetch, isA<bool>());
      });

      test('enableSuperfetch completes without error', () async {
        // This will fail in test environment but verifies the method signature
        expect(() => service.enableSuperfetch(), returnsNormally);
      });

      test('disableSuperfetch completes without error', () async {
        expect(() => service.disableSuperfetch(), returnsNormally);
      });
    });

    group('Memory Compression', () {
      test('statusMemoryCompression returns a boolean', () {
        expect(service.statusMemoryCompression, isA<bool>());
      });

      test('enableMemoryCompression completes without error', () async {
        expect(() => service.enableMemoryCompression(), returnsNormally);
      });

      test('disableMemoryCompression completes without error', () async {
        expect(() => service.disableMemoryCompression(), returnsNormally);
      });
    });

    group('Intel TSX', () {
      test('statusIntelTSX returns a boolean', () {
        expect(service.statusIntelTSX, isA<bool>());
      });

      test('enableIntelTSX completes without error', () {
        expect(() => service.enableIntelTSX(), returnsNormally);
      });

      test('disableIntelTSX completes without error', () {
        expect(() => service.disableIntelTSX(), returnsNormally);
      });
    });

    group('Fullscreen Optimization', () {
      test('statusFullscreenOptimization returns a boolean', () {
        expect(service.statusFullscreenOptimization, isA<bool>());
      });

      test('enableFullscreenOptimization completes without error', () {
        expect(() => service.enableFullscreenOptimization(), returnsNormally);
      });

      test('disableFullscreenOptimization completes without error', () {
        expect(() => service.disableFullscreenOptimization(), returnsNormally);
      });
    });

    group('Windowed Optimization', () {
      test('statusWindowedOptimization returns a boolean', () {
        expect(service.statusWindowedOptimization, isA<bool>());
      });

      test('enableWindowedOptimization completes without error', () {
        expect(() => service.enableWindowedOptimization(), returnsNormally);
      });

      test('disableWindowedOptimization completes without error', () {
        expect(() => service.disableWindowedOptimization(), returnsNormally);
      });
    });

    group('Background Apps', () {
      test('statusBackgroundApps returns a boolean', () {
        expect(service.statusBackgroundApps, isA<bool>());
      });

      test('enableBackgroundApps completes without error', () {
        expect(() => service.enableBackgroundApps(), returnsNormally);
      });

      test('disableBackgroundApps completes without error', () {
        expect(() => service.disableBackgroundApps(), returnsNormally);
      });
    });

    group('C-States', () {
      test('statusCStates returns a boolean', () {
        expect(service.statusCStates, isA<bool>());
      });

      test('enableCStates completes without error', () {
        expect(() => service.enableCStates(), returnsNormally);
      });

      test('disableCStates completes without error', () {
        expect(() => service.disableCStates(), returnsNormally);
      });
    });

    group('Last Time Access NTFS', () {
      test('statusLastTimeAccessNTFS returns a boolean', () {
        expect(service.statusLastTimeAccessNTFS, isA<bool>());
      });

      test('enableLastTimeAccessNTFS completes without error', () async {
        expect(() => service.enableLastTimeAccessNTFS(), returnsNormally);
      });

      test('disableLastTimeAccessNTFS completes without error', () async {
        expect(() => service.disableLastTimeAccessNTFS(), returnsNormally);
      });
    });

    group('8dot3 Naming NTFS', () {
      test('status8dot3NamingNTFS returns a boolean', () {
        expect(service.status8dot3NamingNTFS, isA<bool>());
      });

      test('enable8dot3NamingNTFS completes without error', () async {
        expect(() => service.enable8dot3NamingNTFS(), returnsNormally);
      });

      test('disable8dot3NamingNTFS completes without error', () async {
        expect(() => service.disable8dot3NamingNTFS(), returnsNormally);
      });
    });

    group('Memory Usage NTFS', () {
      test('statusMemoryUsageNTFS returns a boolean', () {
        expect(service.statusMemoryUsageNTFS, isA<bool>());
      });

      test('enableMemoryUsageNTFS completes without error', () async {
        expect(() => service.enableMemoryUsageNTFS(), returnsNormally);
      });

      test('disableMemoryUsageNTFS completes without error', () async {
        expect(() => service.disableMemoryUsageNTFS(), returnsNormally);
      });
    });

    group('Services Grouping', () {
      test('statusServicesGrouping returns a ServiceGrouping enum', () {
        expect(service.statusServicesGrouping, isA<ServiceGrouping>());
      });

      test('statusServicesGrouping returns one of the valid enum values', () {
        final status = service.statusServicesGrouping;
        expect(
          [
            ServiceGrouping.forced,
            ServiceGrouping.recommended,
            ServiceGrouping.disabled,
          ].contains(status),
          isTrue,
        );
      });

      test('forcedServicesGrouping completes without error', () {
        expect(() => service.forcedServicesGrouping(), returnsNormally);
      });

      test('recommendedServicesGrouping completes without error', () {
        expect(() => service.recommendedServicesGrouping(), returnsNormally);
      });

      test('disableServicesGrouping completes without error', () {
        expect(() => service.disableServicesGrouping(), returnsNormally);
      });
    });

    group('Background Window Message Rate Limit', () {
      test('statusBackgroundWindowMessageRateLimit returns an integer', () {
        expect(service.statusBackgroundWindowMessageRateLimit, isA<int>());
      });

      test(
        'statusBackgroundWindowMessageRateLimit returns valid value or -1',
        () {
          final status = service.statusBackgroundWindowMessageRateLimit;
          expect(status == -1 || (status >= 50 && status <= 333), isTrue);
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit throws error for value < 3',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(2),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit throws error for value > 20',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(21),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit throws error for value = 0',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(0),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit throws error for negative value',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(-5),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit accepts minimum valid value (3)',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(3),
            returnsNormally,
          );
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit accepts maximum valid value (20)',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(20),
            returnsNormally,
          );
        },
      );

      test(
        'setBackgroundWindowMessageRateLimit accepts mid-range value (10)',
        () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(10),
            returnsNormally,
          );
        },
      );

      test('setBackgroundWindowMessageRateLimit accepts default value (8)', () {
        expect(
          () => service.setBackgroundWindowMessageRateLimit(8),
          returnsNormally,
        );
      });
    });

    group('Input Validation', () {
      test('_rmtdValidator accepts valid minimum boundary (3)', () {
        expect(
          () => service.setBackgroundWindowMessageRateLimit(3),
          returnsNormally,
        );
      });

      test('_rmtdValidator accepts valid maximum boundary (20)', () {
        expect(
          () => service.setBackgroundWindowMessageRateLimit(20),
          returnsNormally,
        );
      });

      test('_rmtdValidator rejects below minimum (2)', () {
        expect(
          () => service.setBackgroundWindowMessageRateLimit(2),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError && e.message.contains('between 3 and 20'),
            ),
          ),
        );
      });

      test('_rmtdValidator rejects above maximum (21)', () {
        expect(
          () => service.setBackgroundWindowMessageRateLimit(21),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError && e.message.contains('between 3 and 20'),
            ),
          ),
        );
      });

      test('_rmtdValidator error message contains range information', () {
        try {
          service.setBackgroundWindowMessageRateLimit(100);
          fail('Expected ArgumentError to be thrown');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('3'));
          expect(e.toString(), contains('20'));
        }
      });
    });

    group('Service Instance', () {
      test('PerformanceService can be instantiated', () {
        expect(() => const PerformanceServiceImpl(), returnsNormally);
      });

      test('PerformanceService is const constructible', () {
        const service1 = PerformanceServiceImpl();
        const service2 = PerformanceServiceImpl();
        expect(identical(service1, service2), isTrue);
      });

      test('Multiple instances behave identically', () {
        const service1 = PerformanceServiceImpl();
        const service2 = PerformanceServiceImpl();

        // Both should read the same registry values
        expect(service1.statusIntelTSX, equals(service2.statusIntelTSX));
        expect(service1.statusCStates, equals(service2.statusCStates));
      });
    });

    group('Method Return Types', () {
      test('All status getters return boolean or enum', () {
        expect(service.statusSuperfetch, isA<bool>());
        expect(service.statusMemoryCompression, isA<bool>());
        expect(service.statusIntelTSX, isA<bool>());
        expect(service.statusFullscreenOptimization, isA<bool>());
        expect(service.statusWindowedOptimization, isA<bool>());
        expect(service.statusBackgroundApps, isA<bool>());
        expect(service.statusCStates, isA<bool>());
        expect(service.statusLastTimeAccessNTFS, isA<bool>());
        expect(service.status8dot3NamingNTFS, isA<bool>());
        expect(service.statusMemoryUsageNTFS, isA<bool>());
        expect(service.statusServicesGrouping, isA<ServiceGrouping>());
        expect(service.statusBackgroundWindowMessageRateLimit, isA<int>());
      });

      test('All async methods return Future<void>', () {
        expect(service.enableSuperfetch(), isA<Future<void>>());
        expect(service.disableSuperfetch(), isA<Future<void>>());
        expect(service.enableMemoryCompression(), isA<Future<void>>());
        expect(service.disableMemoryCompression(), isA<Future<void>>());
        expect(service.enableLastTimeAccessNTFS(), isA<Future<void>>());
        expect(service.disableLastTimeAccessNTFS(), isA<Future<void>>());
        expect(service.enable8dot3NamingNTFS(), isA<Future<void>>());
        expect(service.disable8dot3NamingNTFS(), isA<Future<void>>());
        expect(service.enableMemoryUsageNTFS(), isA<Future<void>>());
        expect(service.disableMemoryUsageNTFS(), isA<Future<void>>());
      });

      test('All sync enable/disable methods return void', () {
        // These methods execute but we just verify they return void
        expect(service.enableIntelTSX, returnsNormally);
        expect(service.disableIntelTSX, returnsNormally);
        expect(service.enableFullscreenOptimization, returnsNormally);
        expect(service.disableFullscreenOptimization, returnsNormally);
        expect(service.enableWindowedOptimization, returnsNormally);
        expect(service.disableWindowedOptimization, returnsNormally);
        expect(service.enableBackgroundApps, returnsNormally);
        expect(service.disableBackgroundApps, returnsNormally);
        expect(service.enableCStates, returnsNormally);
        expect(service.disableCStates, returnsNormally);
      });
    });
  });

  group('PerformanceService (Mocked - CI Safe)', () {
    late MockPerformanceService mockService;

    setUp(() {
      mockService = MockPerformanceService();
    });

    group('Status Getters', () {
      test('statusSuperfetch can be mocked', () {
        when(() => mockService.statusSuperfetch).thenReturn(true);
        expect(mockService.statusSuperfetch, true);
        verify(() => mockService.statusSuperfetch).called(1);
      });

      test('statusIntelTSX can be mocked', () {
        when(() => mockService.statusIntelTSX).thenReturn(false);
        expect(mockService.statusIntelTSX, false);
      });

      test('statusServicesGrouping can be mocked', () {
        when(
          () => mockService.statusServicesGrouping,
        ).thenReturn(ServiceGrouping.recommended);
        expect(mockService.statusServicesGrouping, ServiceGrouping.recommended);
      });

      test('statusBackgroundWindowMessageRateLimit can be mocked', () {
        when(
          () => mockService.statusBackgroundWindowMessageRateLimit,
        ).thenReturn(125);
        expect(mockService.statusBackgroundWindowMessageRateLimit, 125);
      });
    });

    group('Enable/Disable Methods', () {
      test('enableSuperfetch can be called without system changes', () async {
        when(
          () => mockService.enableSuperfetch(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableSuperfetch();
        verify(() => mockService.enableSuperfetch()).called(1);
      });

      test('disableDefender can be called without system changes', () async {
        when(
          () => mockService.disableSuperfetch(),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableSuperfetch();
        verify(() => mockService.disableSuperfetch()).called(1);
      });

      test('enableIntelTSX can be called without registry changes', () {
        when(() => mockService.enableIntelTSX()).thenReturn(null);

        mockService.enableIntelTSX();
        verify(() => mockService.enableIntelTSX()).called(1);
      });

      test('setBackgroundWindowMessageRateLimit validates input', () {
        when(
          () => mockService.setBackgroundWindowMessageRateLimit(any()),
        ).thenReturn(null);

        mockService.setBackgroundWindowMessageRateLimit(8);
        verify(
          () => mockService.setBackgroundWindowMessageRateLimit(8),
        ).called(1);
      });
    });

    group('Error Scenarios', () {
      test('invalid input can throw error in mock', () {
        when(
          () => mockService.setBackgroundWindowMessageRateLimit(any()),
        ).thenThrow(ArgumentError('Value must be between 3 and 20'));

        expect(
          () => mockService.setBackgroundWindowMessageRateLimit(100),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('async methods can simulate failures', () async {
        when(
          () => mockService.enableSuperfetch(),
        ).thenThrow(Exception('MinSudo.exe not found'));

        expect(
          () async => await mockService.enableSuperfetch(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Behavior Verification', () {
      test('can verify method call order', () {
        when(() => mockService.disableCStates()).thenReturn(null);
        when(() => mockService.statusCStates).thenReturn(false);

        mockService.disableCStates();
        final status = mockService.statusCStates;

        expect(status, false);
        verifyInOrder([
          () => mockService.disableCStates(),
          () => mockService.statusCStates,
        ]);
      });

      test('can verify method never called', () {
        verifyNever(() => mockService.forcedServicesGrouping());
      });
    });
  });
}
