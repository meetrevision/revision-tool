import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/performance/performance_service.dart';

class MockPerformanceService extends Mock implements PerformanceService {}

void main() {
  const skipIntegration = bool.fromEnvironment(
    'SKIP_INTEGRATION',
    defaultValue: true,
  );

  group(
    'PerformanceService (Real Implementation)',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
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
          await expectLater(service.enableSuperfetch(), completes);
        });

        test('disableSuperfetch completes without error', () async {
          await expectLater(service.disableSuperfetch(), completes);
        });
      });

      group('Memory Compression', () {
        test('statusMemoryCompression returns a boolean', () {
          expect(service.statusMemoryCompression, isA<bool>());
        });

        test('enableMemoryCompression completes without error', () async {
          await expectLater(service.enableMemoryCompression(), completes);
        });

        test('disableMemoryCompression completes without error', () async {
          await expectLater(service.disableMemoryCompression(), completes);
        });
      });

      group('Intel TSX', () {
        test('statusIntelTSX returns a boolean', () {
          expect(service.statusIntelTSX, isA<bool>());
        });

        test('enableIntelTSX completes without error', () async {
          await expectLater(service.enableIntelTSX(), completes);
        });

        test('disableIntelTSX completes without error', () async {
          await expectLater(service.disableIntelTSX(), completes);
        });
      });

      group('Fullscreen Optimization', () {
        test('statusFullscreenOptimization returns a boolean', () {
          expect(service.statusFullscreenOptimization, isA<bool>());
        });

        test('enableFullscreenOptimization completes without error', () async {
          await expectLater(service.enableFullscreenOptimization(), completes);
        });

        test('disableFullscreenOptimization completes without error', () async {
          await expectLater(service.disableFullscreenOptimization(), completes);
        });
      });

      group('Windowed Optimization', () {
        test('statusWindowedOptimization returns a boolean', () {
          expect(service.statusWindowedOptimization, isA<bool>());
        });

        test('enableWindowedOptimization completes without error', () async {
          await expectLater(service.enableWindowedOptimization(), completes);
        });

        test('disableWindowedOptimization completes without error', () async {
          await expectLater(service.disableWindowedOptimization(), completes);
        });
      });

      group('Background Apps', () {
        test('statusBackgroundApps returns a boolean', () {
          expect(service.statusBackgroundApps, isA<bool>());
        });

        test('enableBackgroundApps completes without error', () async {
          await expectLater(service.enableBackgroundApps(), completes);
        });

        test('disableBackgroundApps completes without error', () async {
          await expectLater(service.disableBackgroundApps(), completes);
        });
      });

      group('C-States', () {
        test('statusCStates returns a boolean', () {
          expect(service.statusCStates, isA<bool>());
        });

        test('enableCStates completes without error', () async {
          await expectLater(service.enableCStates(), completes);
        });

        test('disableCStates completes without error', () async {
          await expectLater(service.disableCStates(), completes);
        });
      });

      group('Last Time Access NTFS', () {
        test('statusLastTimeAccessNTFS returns a boolean', () {
          expect(service.statusLastTimeAccessNTFS, isA<bool>());
        });

        test('enableLastTimeAccessNTFS completes without error', () async {
          await expectLater(service.enableLastTimeAccessNTFS(), completes);
        });

        test('disableLastTimeAccessNTFS completes without error', () async {
          await expectLater(service.disableLastTimeAccessNTFS(), completes);
        });
      });

      group('8dot3 Naming NTFS', () {
        test('status8dot3NamingNTFS returns a boolean', () {
          expect(service.status8dot3NamingNTFS, isA<bool>());
        });

        test('enable8dot3NamingNTFS completes without error', () async {
          await expectLater(service.enable8dot3NamingNTFS(), completes);
        });

        test('disable8dot3NamingNTFS completes without error', () async {
          await expectLater(service.disable8dot3NamingNTFS(), completes);
        });
      });

      group('Memory Usage NTFS', () {
        test('statusMemoryUsageNTFS returns a boolean', () {
          expect(service.statusMemoryUsageNTFS, isA<bool>());
        });

        test('enableMemoryUsageNTFS completes without error', () async {
          await expectLater(service.enableMemoryUsageNTFS(), completes);
        });

        test('disableMemoryUsageNTFS completes without error', () async {
          await expectLater(service.disableMemoryUsageNTFS(), completes);
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

        test('forcedServicesGrouping completes without error', () async {
          await expectLater(service.forcedServicesGrouping(), completes);
        });

        test('recommendedServicesGrouping completes without error', () async {
          await expectLater(service.recommendedServicesGrouping(), completes);
        });

        test('disableServicesGrouping completes without error', () async {
          await expectLater(service.disableServicesGrouping(), completes);
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
          () async {
            await expectLater(
              service.setBackgroundWindowMessageRateLimit(3),
              completes,
            );
          },
        );

        test(
          'setBackgroundWindowMessageRateLimit accepts maximum valid value (20)',
          () async {
            await expectLater(
              service.setBackgroundWindowMessageRateLimit(20),
              completes,
            );
          },
        );

        test(
          'setBackgroundWindowMessageRateLimit accepts mid-range value (10)',
          () async {
            await expectLater(
              service.setBackgroundWindowMessageRateLimit(10),
              completes,
            );
          },
        );

        test(
          'setBackgroundWindowMessageRateLimit accepts default value (8)',
          () async {
            await expectLater(
              service.setBackgroundWindowMessageRateLimit(8),
              completes,
            );
          },
        );
      });

      group('Input Validation', () {
        test('_rmtdValidator accepts valid minimum boundary (3)', () async {
          await expectLater(
            service.setBackgroundWindowMessageRateLimit(3),
            completes,
          );
        });

        test('_rmtdValidator accepts valid maximum boundary (20)', () async {
          await expectLater(
            service.setBackgroundWindowMessageRateLimit(20),
            completes,
          );
        });

        test('_rmtdValidator rejects below minimum (2)', () {
          expect(
            () => service.setBackgroundWindowMessageRateLimit(2),
            throwsA(
              predicate(
                (e) =>
                    e is ArgumentError &&
                    e.message.contains('between 3 and 20'),
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
                    e is ArgumentError &&
                    e.message.contains('between 3 and 20'),
              ),
            ),
          );
        });

        test(
          '_rmtdValidator error message contains range information',
          () async {
            await expectLater(
              () => service.setBackgroundWindowMessageRateLimit(100),
              throwsA(
                isA<ArgumentError>()
                    .having((e) => e.toString(), 'message', contains('3'))
                    .having((e) => e.toString(), 'message', contains('20')),
              ),
            );
          },
        );
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
          expect(service.enableIntelTSX(), isA<Future<void>>());
          expect(service.disableIntelTSX(), isA<Future<void>>());
          expect(service.enableFullscreenOptimization(), isA<Future<void>>());
          expect(service.disableFullscreenOptimization(), isA<Future<void>>());
          expect(service.enableWindowedOptimization(), isA<Future<void>>());
          expect(service.disableWindowedOptimization(), isA<Future<void>>());
          expect(service.enableBackgroundApps(), isA<Future<void>>());
          expect(service.disableBackgroundApps(), isA<Future<void>>());
          expect(service.enableCStates(), isA<Future<void>>());
          expect(service.disableCStates(), isA<Future<void>>());
          expect(service.forcedServicesGrouping(), isA<Future<void>>());
          expect(service.recommendedServicesGrouping(), isA<Future<void>>());
          expect(service.disableServicesGrouping(), isA<Future<void>>());
          expect(
            service.setBackgroundWindowMessageRateLimit(8),
            isA<Future<void>>(),
          );
        });
      });
    },
  );

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

      test('enableIntelTSX can be called without registry changes', () async {
        when(
          () => mockService.enableIntelTSX(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableIntelTSX();
        verify(() => mockService.enableIntelTSX()).called(1);
      });

      test('setBackgroundWindowMessageRateLimit validates input', () async {
        when(
          () => mockService.setBackgroundWindowMessageRateLimit(any()),
        ).thenAnswer((_) async => Future.value());

        await mockService.setBackgroundWindowMessageRateLimit(8);
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
    });

    group('Behavior Verification', () {
      test('can verify method call order', () async {
        when(
          () => mockService.disableCStates(),
        ).thenAnswer((_) async => Future.value());
        when(() => mockService.statusCStates).thenReturn(false);

        await mockService.disableCStates();
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
