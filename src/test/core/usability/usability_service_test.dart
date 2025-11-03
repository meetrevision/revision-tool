import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/usability/usability_service.dart';

class MockUsabilityService extends Mock implements UsabilityService {}

void main() {
  const skipIntegration = bool.fromEnvironment(
    'SKIP_INTEGRATION',
    defaultValue: true,
  );

  group(
    'UsabilityService (Real Implementation)',
    skip: skipIntegration
        ? 'Skipped in CI (use --dart-define=SKIP_INTEGRATION=false to run)'
        : false,
    () {
      late UsabilityService service;

      setUp(() {
        service = const UsabilityServiceImpl();
      });

      group('Notifications', () {
        test('statusNotification returns NotificationMode', () {
          expect(service.statusNotification, isA<NotificationMode>());
        });

        test('enableNotification completes without error', () async {
          await expectLater(service.enableNotification(), completes);
        });

        test('disableNotification completes without error', () async {
          await expectLater(service.disableNotification(), completes);
        });

        test('disableNotificationAggressive completes without error', () async {
          await expectLater(service.disableNotificationAggressive(), completes);
        });
      });

      group('Legacy Balloon', () {
        test('statusLegacyBalloon returns a boolean', () {
          expect(service.statusLegacyBalloon, isA<bool>());
        });

        test('enableLegacyBalloon completes without error', () async {
          await expectLater(service.enableLegacyBalloon(), completes);
        });

        test('disableLegacyBalloon completes without error', () async {
          await expectLater(service.disableLegacyBalloon(), completes);
        });
      });

      group('Input Personalization', () {
        test('statusInputPersonalization returns a boolean', () {
          expect(service.statusInputPersonalization, isA<bool>());
        });

        test('enableInputPersonalization completes without error', () async {
          await expectLater(service.enableInputPersonalization(), completes);
        });

        test('disableInputPersonalization completes without error', () async {
          await expectLater(service.disableInputPersonalization(), completes);
        });
      });

      group('Caps Lock', () {
        test('statusCapsLock returns a boolean', () {
          expect(service.statusCapsLock, isA<bool>());
        });

        test('enableCapsLock completes without error', () async {
          await expectLater(service.enableCapsLock(), completes);
        });

        test('disableCapsLock completes without error', () async {
          await expectLater(service.disableCapsLock(), completes);
        });
      });

      group('Screen Edge Swipe', () {
        test('statusScreenEdgeSwipe returns a boolean', () {
          expect(service.statusScreenEdgeSwipe, isA<bool>());
        });

        test('enableScreenEdgeSwipe completes without error', () async {
          await expectLater(service.enableScreenEdgeSwipe(), completes);
        });

        test('disableScreenEdgeSwipe completes without error', () async {
          await expectLater(service.disableScreenEdgeSwipe(), completes);
        });
      });

      group('New Context Menu', () {
        test('statusNewContextMenu returns a boolean', () {
          expect(service.statusNewContextMenu, isA<bool>());
        });

        test('enableNewContextMenu completes without error', () async {
          await expectLater(service.enableNewContextMenu(), completes);
        });

        test('disableNewContextMenu completes without error', () async {
          await expectLater(service.disableNewContextMenu(), completes);
        });
      });

      group('Service Instance', () {
        test('UsabilityService can be instantiated', () {
          expect(() => const UsabilityServiceImpl(), returnsNormally);
        });

        test('UsabilityService is const constructible', () {
          const service1 = UsabilityServiceImpl();
          const service2 = UsabilityServiceImpl();
          expect(identical(service1, service2), isTrue);
        });

        test('Multiple instances behave identically', () {
          const service1 = UsabilityServiceImpl();
          const service2 = UsabilityServiceImpl();

          expect(
            service1.statusNotification,
            equals(service2.statusNotification),
          );
          expect(
            service1.statusLegacyBalloon,
            equals(service2.statusLegacyBalloon),
          );
          expect(service1.statusCapsLock, equals(service2.statusCapsLock));
        });
      });

      group('Method Return Types', () {
        test('All status getters return correct types', () {
          expect(service.statusNotification, isA<NotificationMode>());
          expect(service.statusLegacyBalloon, isA<bool>());
          expect(service.statusInputPersonalization, isA<bool>());
          expect(service.statusCapsLock, isA<bool>());
          expect(service.statusScreenEdgeSwipe, isA<bool>());
          expect(service.statusNewContextMenu, isA<bool>());
        });

        test('All methods return Future', () {
          expect(service.enableNotification(), isA<Future<void>>());
          expect(service.disableNotification(), isA<Future<void>>());
          expect(service.disableNotificationAggressive(), isA<Future<void>>());
          expect(service.enableLegacyBalloon(), isA<Future<void>>());
          expect(service.disableLegacyBalloon(), isA<Future<void>>());
          expect(service.enableNewContextMenu(), isA<Future<void>>());
          expect(service.disableNewContextMenu(), isA<Future<void>>());
          expect(service.enableInputPersonalization(), isA<Future<void>>());
          expect(service.disableInputPersonalization(), isA<Future<void>>());
          expect(service.enableCapsLock(), isA<Future<void>>());
          expect(service.disableCapsLock(), isA<Future<void>>());
          expect(service.enableScreenEdgeSwipe(), isA<Future<void>>());
          expect(service.disableScreenEdgeSwipe(), isA<Future<void>>());
        });
      });

      group('NotificationMode Enum', () {
        test('NotificationMode has all expected values', () {
          expect(NotificationMode.values.length, equals(3));
          expect(NotificationMode.values, contains(NotificationMode.on));
          expect(
            NotificationMode.values,
            contains(NotificationMode.offMinimal),
          );
          expect(NotificationMode.values, contains(NotificationMode.offFull));
        });
      });
    },
  );

  group('UsabilityService - Mocked (CI Safe)', () {
    late MockUsabilityService mockService;

    setUp(() {
      mockService = MockUsabilityService();
    });

    group('Notifications', () {
      test('statusNotification can be mocked', () {
        when(
          () => mockService.statusNotification,
        ).thenReturn(NotificationMode.on);
        expect(mockService.statusNotification, NotificationMode.on);
        verify(() => mockService.statusNotification).called(1);
      });

      test('enableNotification can be called without system changes', () async {
        when(
          () => mockService.enableNotification(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableNotification();
        verify(() => mockService.enableNotification()).called(1);
      });

      test(
        'disableNotification can be called without system changes',
        () async {
          when(
            () => mockService.disableNotification(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableNotification();
          verify(() => mockService.disableNotification()).called(1);
        },
      );

      test(
        'disableNotificationAggressive can be called without system changes',
        () async {
          when(
            () => mockService.disableNotificationAggressive(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableNotificationAggressive();
          verify(() => mockService.disableNotificationAggressive()).called(1);
        },
      );
    });

    group('Legacy Balloon', () {
      test('statusLegacyBalloon can be mocked', () {
        when(() => mockService.statusLegacyBalloon).thenReturn(true);
        expect(mockService.statusLegacyBalloon, isTrue);
      });

      test(
        'enableLegacyBalloon can be called without system changes',
        () async {
          when(
            () => mockService.enableLegacyBalloon(),
          ).thenAnswer((_) async => Future.value());

          await mockService.enableLegacyBalloon();
          verify(() => mockService.enableLegacyBalloon()).called(1);
        },
      );

      test(
        'disableLegacyBalloon can be called without system changes',
        () async {
          when(
            () => mockService.disableLegacyBalloon(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableLegacyBalloon();
          verify(() => mockService.disableLegacyBalloon()).called(1);
        },
      );
    });

    group('Input Personalization', () {
      test('statusInputPersonalization can be mocked', () {
        when(() => mockService.statusInputPersonalization).thenReturn(false);
        expect(mockService.statusInputPersonalization, isFalse);
      });

      test(
        'enableInputPersonalization can be called without system changes',
        () async {
          when(
            () => mockService.enableInputPersonalization(),
          ).thenAnswer((_) async => Future.value());

          await mockService.enableInputPersonalization();
          verify(() => mockService.enableInputPersonalization()).called(1);
        },
      );

      test(
        'disableInputPersonalization can be called without system changes',
        () async {
          when(
            () => mockService.disableInputPersonalization(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableInputPersonalization();
          verify(() => mockService.disableInputPersonalization()).called(1);
        },
      );
    });

    group('Caps Lock', () {
      test('statusCapsLock can be mocked', () {
        when(() => mockService.statusCapsLock).thenReturn(true);
        expect(mockService.statusCapsLock, isTrue);
      });

      test('enableCapsLock can be called without system changes', () async {
        when(
          () => mockService.enableCapsLock(),
        ).thenAnswer((_) async => Future.value());

        await mockService.enableCapsLock();
        verify(() => mockService.enableCapsLock()).called(1);
      });

      test('disableCapsLock can be called without system changes', () async {
        when(
          () => mockService.disableCapsLock(),
        ).thenAnswer((_) async => Future.value());

        await mockService.disableCapsLock();
        verify(() => mockService.disableCapsLock()).called(1);
      });
    });

    group('Screen Edge Swipe', () {
      test('statusScreenEdgeSwipe can be mocked', () {
        when(() => mockService.statusScreenEdgeSwipe).thenReturn(false);
        expect(mockService.statusScreenEdgeSwipe, isFalse);
      });

      test(
        'enableScreenEdgeSwipe can be called without system changes',
        () async {
          when(
            () => mockService.enableScreenEdgeSwipe(),
          ).thenAnswer((_) async => Future.value());

          await mockService.enableScreenEdgeSwipe();
          verify(() => mockService.enableScreenEdgeSwipe()).called(1);
        },
      );

      test(
        'disableScreenEdgeSwipe can be called without system changes',
        () async {
          when(
            () => mockService.disableScreenEdgeSwipe(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableScreenEdgeSwipe();
          verify(() => mockService.disableScreenEdgeSwipe()).called(1);
        },
      );
    });

    group('New Context Menu', () {
      test('statusNewContextMenu can be mocked', () {
        when(() => mockService.statusNewContextMenu).thenReturn(true);
        expect(mockService.statusNewContextMenu, isTrue);
      });

      test(
        'enableNewContextMenu can be called without system changes',
        () async {
          when(
            () => mockService.enableNewContextMenu(),
          ).thenAnswer((_) async => Future.value());

          await mockService.enableNewContextMenu();
          verify(() => mockService.enableNewContextMenu()).called(1);
        },
      );

      test(
        'disableNewContextMenu can be called without system changes',
        () async {
          when(
            () => mockService.disableNewContextMenu(),
          ).thenAnswer((_) async => Future.value());

          await mockService.disableNewContextMenu();
          verify(() => mockService.disableNewContextMenu()).called(1);
        },
      );
    });

    group('Call Order Verification', () {
      test('can verify method call order', () async {
        when(
          () => mockService.statusNotification,
        ).thenReturn(NotificationMode.offMinimal);
        when(
          () => mockService.enableCapsLock(),
        ).thenAnswer((_) async => Future.value());
        when(() => mockService.statusCapsLock).thenReturn(true);

        final notificationStatus = mockService.statusNotification;
        await mockService.enableCapsLock();
        final capsLockStatus = mockService.statusCapsLock;

        expect(notificationStatus, NotificationMode.offMinimal);
        expect(capsLockStatus, isTrue);

        verifyInOrder([
          () => mockService.statusNotification,
          () => mockService.enableCapsLock(),
          () => mockService.statusCapsLock,
        ]);
      });

      test('can verify a method was never called', () {
        when(
          () => mockService.enableNotification(),
        ).thenAnswer((_) async => Future.value());

        verifyNever(() => mockService.disableNotification());
      });
    });
  });
}
