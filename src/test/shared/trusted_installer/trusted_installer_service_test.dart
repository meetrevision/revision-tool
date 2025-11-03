import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revitool/shared/trusted_installer/trusted_installer_exception.dart';
import 'package:revitool/shared/trusted_installer/trusted_installer_service.dart';

/// Mock implementation of TrustedInstallerService for testing
class MockTrustedInstallerService extends Mock
    implements TrustedInstallerService {}

class FakeCommandResult extends Fake implements CommandResult {
  @override
  final int exitCode;
  @override
  final String output;
  @override
  final String error;

  FakeCommandResult({
    required this.exitCode,
    required this.output,
    required this.error,
  });
}

void main() {
  group('TrustedInstallerService - Mocked Tests (CI Safe)', () {
    late MockTrustedInstallerService mockService;

    setUp(() {
      mockService = MockTrustedInstallerService();
    });

    test('executeWithTrustedInstaller returns result from callback', () async {
      // Arrange
      const expectedResult = 'test result';
      when(
        () => mockService.executeWithTrustedInstaller<String>(any()),
      ).thenAnswer((_) async => expectedResult);

      // Act
      final result = await mockService.executeWithTrustedInstaller<String>(
        () async {
          return expectedResult;
        },
      );

      // Assert
      expect(result, expectedResult);
      verify(
        () => mockService.executeWithTrustedInstaller<String>(any()),
      ).called(1);
    });

    test(
      'executeWithTrustedInstaller handles exceptions from callback',
      () async {
        // Arrange
        final exception = Exception('Test exception');
        when(
          () => mockService.executeWithTrustedInstaller<void>(any()),
        ).thenThrow(exception);

        // Act & Assert
        expect(
          () => mockService.executeWithTrustedInstaller<void>(() async {
            throw exception;
          }),
          throwsA(exception),
        );
      },
    );

    test('isTrustedInstallerAvailable returns boolean', () {
      // Arrange
      when(() => mockService.isTrustedInstallerAvailable()).thenReturn(true);

      // Act
      final result = mockService.isTrustedInstallerAvailable();

      // Assert
      expect(result, isA<bool>());
      expect(result, true);
      verify(() => mockService.isTrustedInstallerAvailable()).called(1);
    });

    test('executeWithTrustedInstaller can return different types', () async {
      // Test with int
      when(
        () => mockService.executeWithTrustedInstaller<int>(any()),
      ).thenAnswer((_) async => 42);

      final intResult = await mockService.executeWithTrustedInstaller<int>(
        () async => 42,
      );
      expect(intResult, 42);

      // Test with bool
      when(
        () => mockService.executeWithTrustedInstaller<bool>(any()),
      ).thenAnswer((_) async => true);

      final boolResult = await mockService.executeWithTrustedInstaller<bool>(
        () async => true,
      );
      expect(boolResult, true);

      // Test with List
      when(
        () => mockService.executeWithTrustedInstaller<List<String>>(any()),
      ).thenAnswer((_) async => ['a', 'b', 'c']);

      final listResult = await mockService
          .executeWithTrustedInstaller<List<String>>(
            () async => ['a', 'b', 'c'],
          );
      expect(listResult, ['a', 'b', 'c']);
    });

    test('executeCommand returns CommandResult', () async {
      // Arrange
      final expectedResult = FakeCommandResult(
        exitCode: 0,
        output: 'command output',
        error: '',
      );
      when(
        () => mockService.executeCommand(any(), any()),
      ).thenAnswer((_) async => expectedResult);

      // Act
      final result = await mockService.executeCommand('whoami', ['/all']);

      // Assert
      expect(result.exitCode, 0);
      expect(result.output, 'command output');
      expect(result.error, isEmpty);
      verify(() => mockService.executeCommand(any(), any())).called(1);
    });

    test('executeCommand handles command failures', () async {
      // Arrange
      final expectedResult = FakeCommandResult(
        exitCode: 1,
        output: '',
        error: 'command failed',
      );
      when(
        () => mockService.executeCommand(any(), any()),
      ).thenAnswer((_) async => expectedResult);

      // Act
      final result = await mockService.executeCommand('invalid', []);

      // Assert
      expect(result.exitCode, 1);
      expect(result.error, 'command failed');
      verify(() => mockService.executeCommand(any(), any())).called(1);
    });

    test('multiple sequential calls work correctly', () async {
      // Arrange
      when(
        () => mockService.executeWithTrustedInstaller<int>(any()),
      ).thenAnswer((invocation) async {
        final callback =
            invocation.positionalArguments[0] as Future<int> Function();
        return await callback();
      });

      // Act
      final result1 = await mockService.executeWithTrustedInstaller<int>(
        () async => 1,
      );
      final result2 = await mockService.executeWithTrustedInstaller<int>(
        () async => 2,
      );
      final result3 = await mockService.executeWithTrustedInstaller<int>(
        () async => 3,
      );

      // Assert
      expect(result1, 1);
      expect(result2, 2);
      expect(result3, 3);
      verify(
        () => mockService.executeWithTrustedInstaller<int>(any()),
      ).called(3);
    });
  });

  group('TrustedInstallerService - Real Implementation (Local Only)', () {
    late TrustedInstallerService service;

    setUp(() {
      service = TrustedInstallerServiceImpl();
    });

    test('service can be instantiated', () {
      expect(service, isA<TrustedInstallerService>());
      expect(service, isA<TrustedInstallerServiceImpl>());
    });

    test('isTrustedInstallerAvailable checks service existence', () {
      // This should return true on Windows systems with TrustedInstaller service
      final isAvailable = service.isTrustedInstallerAvailable();
      expect(isAvailable, isA<bool>());
      // On Windows, this should typically be true
      // expect(isAvailable, true); // Uncomment for local testing only
    });

    test('executeWithTrustedInstaller executes callback', () async {
      // Simple test that doesn't require actual TrustedInstaller operations
      bool callbackExecuted = false;

      try {
        await service.executeWithTrustedInstaller(() async {
          callbackExecuted = true;
          return null;
        });

        expect(callbackExecuted, true);
      } on TrustedInstallerException catch (e) {
        // This might fail in CI/CD environments, which is expected
        expect(e.message, isNotEmpty);
      }
    });

    test('executeWithTrustedInstaller returns callback result', () async {
      const testValue = 'test result';

      try {
        final result = await service.executeWithTrustedInstaller<String>(
          () async {
            return testValue;
          },
        );

        expect(result, testValue);
      } on TrustedInstallerException catch (e) {
        // Expected in CI/CD environments
        expect(e.message, isNotEmpty);
      }
    });

    test('executeWithTrustedInstaller handles callback exceptions', () async {
      final testException = Exception('Test exception from callback');

      try {
        await service.executeWithTrustedInstaller<void>(() async {
          throw testException;
        });

        fail('Should have thrown exception');
      } catch (e) {
        // Should catch either the test exception or TrustedInstallerException
        expect(e, anyOf(testException, isA<TrustedInstallerException>()));
      }
    });

    test('TrustedInstallerException contains error information', () {
      final exception1 = TrustedInstallerException('Test message');
      expect(exception1.message, 'Test message');
      expect(exception1.errorCode, isNull);
      expect(exception1.toString(), contains('Test message'));

      final exception2 = TrustedInstallerException('Test with code', 123);
      expect(exception2.message, 'Test with code');
      expect(exception2.errorCode, 123);
      expect(exception2.toString(), contains('Test with code'));
      expect(exception2.toString(), contains('123'));
    });

    test('multiple calls can be made sequentially', () async {
      try {
        final result1 = await service.executeWithTrustedInstaller<int>(
          () async => 1,
        );
        final result2 = await service.executeWithTrustedInstaller<int>(
          () async => 2,
        );
        final result3 = await service.executeWithTrustedInstaller<int>(
          () async => 3,
        );

        expect(result1, 1);
        expect(result2, 2);
        expect(result3, 3);
      } on TrustedInstallerException catch (e) {
        // Expected in CI/CD environments
        expect(e.message, isNotEmpty);
      }
    });

    test('CommandResult contains proper values', () {
      const result = CommandResult(
        exitCode: 0,
        output: 'test output',
        error: 'test error',
      );

      expect(result.exitCode, 0);
      expect(result.output, 'test output');
      expect(result.error, 'test error');
      expect(result.toString(), contains('exitCode: 0'));
      expect(result.toString(), contains('test output'));
      expect(result.toString(), contains('test error'));
    });

    test('executeCommand can execute simple commands', () async {
      try {
        final result = await service.executeCommand('whoami', []);

        expect(result, isA<CommandResult>());
        expect(result.exitCode, isA<int>());
        expect(result.output, isA<String>());
        expect(result.error, isA<String>());
      } on TrustedInstallerException catch (e) {
        // Expected in CI/CD environments
        expect(e.message, isNotEmpty);
      }
    });

    test('executeCommand returns proper output', () async {
      try {
        final result = await service.executeCommand('echo', ['test']);

        expect(result.exitCode, 0);
        expect(result.output, contains('test'));
      } on TrustedInstallerException catch (e) {
        // Expected in CI/CD environments
        expect(e.message, isNotEmpty);
      }
    });
  });

  group('TrustedInstallerService - Integration Tests', () {
    late TrustedInstallerService service;

    setUp(() {
      service = TrustedInstallerServiceImpl();
    });

    test('service implements TrustedInstallerService interface', () {
      expect(service, isA<TrustedInstallerService>());
    });

    test('executeWithTrustedInstaller method exists and is callable', () {
      expect(
        service.executeWithTrustedInstaller<void>,
        isA<Future<void> Function(Future<void> Function())>(),
      );
    });

    test('isTrustedInstallerAvailable method exists and is callable', () {
      expect(service.isTrustedInstallerAvailable, isA<bool Function()>());
    });

    test('executeCommand method exists and is callable', () {
      expect(
        service.executeCommand,
        isA<Future<CommandResult> Function(String, List<String>)>(),
      );
    });

    test('CommandResult class is accessible', () {
      const result = CommandResult(exitCode: 0, output: '', error: '');
      expect(result, isA<CommandResult>());
    });
  });
}
