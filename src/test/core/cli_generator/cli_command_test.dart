import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_service.dart';

void main() {
  group('CLI generator fixture contract', () {
    final service = TestServiceImpl();

    test('registers expected top-level subcommands', () {
      final command = TestServiceCliCommand(service);
      expect(command.name, 'test');
      expect(command.subcommands.keys, containsAll(['feature', 'mode']));
    });

    test('registers expected enum leaf subcommands', () {
      final command = TestServiceCliCommand(service);
      final Command<void>? mode = command.subcommands['mode'];
      expect(mode, isNotNull);
      expect(
        mode!.subcommands.keys,
        containsAll(['enable', 'disable', 'status']),
      );
    });

    test('runs enum status with valid target', () async {
      final runner = CommandRunner<void>('revitool', 'test')
        ..addCommand(TestServiceCliCommand(service));
      await runner.run(['test', 'mode', 'status', '--mode', 'alpha']);
    });

    test('rejects enum status with invalid target', () async {
      final runner = CommandRunner<void>('revitool', 'test')
        ..addCommand(TestServiceCliCommand(service));
      expect(
        () => runner.run([
          'test',
          'mode',
          'status',
          '--mode',
          'not-a-valid-target',
        ]),
        throwsA(isA<UsageException>()),
      );
    });
  });
}
