import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/core/usability/usability_service.dart';

class MockUsabilityService extends Mock implements UsabilityService {}

void main() {
  group('UsabilityService - Real Implementation', () {
    late UsabilityService service;

    setUp(() {
      service = const UsabilityServiceImpl();
    });

    group('Notifications', () {
      test('statusNotification returns NotificationMode', () {
        expect(service.statusNotification, isA<NotificationMode>());
      });

      test('enableNotification completes without error', () async {
        expect(() => service.enableNotification(), returnsNormally);
      });

      test('disableNotification completes without error', () async {
        expect(() => service.disableNotification(), returnsNormally);
      });

      test('disableNotificationAggressive completes without error', () async {
        expect(() => service.disableNotificationAggressive(), returnsNormally);
      });
    });

    group('Legacy Balloon', () {
      test('statusLegacyBalloon returns a boolean', () {
        expect(service.statusLegacyBalloon, isA<bool>());
      });

      test('enableLegacyBalloon completes without error', () async {
        expect(() => service.enableLegacyBalloon(), returnsNormally);
      });

      test('disableLegacyBalloon completes without error', () async {
        expect(() => service.disableLegacyBalloon(), returnsNormally);
      });
    });

    group('Input Personalization', () {
      test('statusInputPersonalization returns a boolean', () {
        expect(service.statusInputPersonalization, isA<bool>());
      });

      test('enableInputPersonalization completes without error', () {
        expect(() => service.enableInputPersonalization(), returnsNormally);
      });

      test('disableInputPersonalization completes without error', () {
        expect(() => service.disableInputPersonalization(), returnsNormally);
      });
    });

    group('Caps Lock', () {
      test('statusCapsLock returns a boolean', () {
        expect(service.statusCapsLock, isA<bool>());
      });

      test('enableCapsLock completes without error', () {
        expect(() => service.enableCapsLock(), returnsNormally);
      });

      test('disableCapsLock completes without error', () {
        expect(() => service.disableCapsLock(), returnsNormally);
      });
    });

    group('Screen Edge Swipe', () {
      test('statusScreenEdgeSwipe returns a boolean', () {
        expect(service.statusScreenEdgeSwipe, isA<bool>());
      });

      test('enableScreenEdgeSwipe completes without error', () {
        expect(() => service.enableScreenEdgeSwipe(), returnsNormally);
      });

      test('disableScreenEdgeSwipe completes without error', () {
        expect(() => service.disableScreenEdgeSwipe(), returnsNormally);
      });
    });

    group('New Context Menu', () {
      test('statusNewContextMenu returns a boolean', () {
        expect(service.statusNewContextMenu, isA<bool>());
      });

      test('enableNewContextMenu completes without error', () async {
        expect(() => service.enableNewContextMenu(), returnsNormally);
      });

      test('disableNewContextMenu completes without error', () async {
        expect(() => service.disableNewContextMenu(), returnsNormally);
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

      test('Async methods return Future', () {
        expect(service.enableNotification(), isA<Future<void>>());
        expect(service.disableNotification(), isA<Future<void>>());
        expect(service.disableNotificationAggressive(), isA<Future<void>>());
        expect(service.enableLegacyBalloon(), isA<Future<void>>());
        expect(service.disableLegacyBalloon(), isA<Future<void>>());
        expect(service.enableNewContextMenu(), isA<Future<void>>());
        expect(service.disableNewContextMenu(), isA<Future<void>>());
      });

      test('Sync methods return void', () {
        expect(() => service.enableInputPersonalization(), returnsNormally);
        expect(() => service.disableInputPersonalization(), returnsNormally);
        expect(() => service.enableCapsLock(), returnsNormally);
        expect(() => service.disableCapsLock(), returnsNormally);
        expect(() => service.enableScreenEdgeSwipe(), returnsNormally);
        expect(() => service.disableScreenEdgeSwipe(), returnsNormally);
      });
    });

    group('NotificationMode Enum', () {
      test('NotificationMode has all expected values', () {
        expect(NotificationMode.values.length, equals(3));
        expect(NotificationMode.values, contains(NotificationMode.on));
        expect(NotificationMode.values, contains(NotificationMode.offMinimal));
        expect(NotificationMode.values, contains(NotificationMode.offFull));
      });
    });
  });

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
        () {
          when(() => mockService.enableInputPersonalization()).thenReturn(null);

          mockService.enableInputPersonalization();
          verify(() => mockService.enableInputPersonalization()).called(1);
        },
      );

      test(
        'disableInputPersonalization can be called without system changes',
        () {
          when(
            () => mockService.disableInputPersonalization(),
          ).thenReturn(null);

          mockService.disableInputPersonalization();
          verify(() => mockService.disableInputPersonalization()).called(1);
        },
      );
    });

    group('Caps Lock', () {
      test('statusCapsLock can be mocked', () {
        when(() => mockService.statusCapsLock).thenReturn(true);
        expect(mockService.statusCapsLock, isTrue);
      });

      test('enableCapsLock can be called without system changes', () {
        when(() => mockService.enableCapsLock()).thenReturn(null);

        mockService.enableCapsLock();
        verify(() => mockService.enableCapsLock()).called(1);
      });

      test('disableCapsLock can be called without system changes', () {
        when(() => mockService.disableCapsLock()).thenReturn(null);

        mockService.disableCapsLock();
        verify(() => mockService.disableCapsLock()).called(1);
      });
    });

    group('Screen Edge Swipe', () {
      test('statusScreenEdgeSwipe can be mocked', () {
        when(() => mockService.statusScreenEdgeSwipe).thenReturn(false);
        expect(mockService.statusScreenEdgeSwipe, isFalse);
      });

      test('enableScreenEdgeSwipe can be called without system changes', () {
        when(() => mockService.enableScreenEdgeSwipe()).thenReturn(null);

        mockService.enableScreenEdgeSwipe();
        verify(() => mockService.enableScreenEdgeSwipe()).called(1);
      });

      test('disableScreenEdgeSwipe can be called without system changes', () {
        when(() => mockService.disableScreenEdgeSwipe()).thenReturn(null);

        mockService.disableScreenEdgeSwipe();
        verify(() => mockService.disableScreenEdgeSwipe()).called(1);
      });
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
      test('can verify method call order', () {
        when(
          () => mockService.statusNotification,
        ).thenReturn(NotificationMode.offMinimal);
        when(() => mockService.enableCapsLock()).thenReturn(null);
        when(() => mockService.statusCapsLock).thenReturn(true);

        final notificationStatus = mockService.statusNotification;
        mockService.enableCapsLock();
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
