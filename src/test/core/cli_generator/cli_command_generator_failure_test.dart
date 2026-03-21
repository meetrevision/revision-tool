import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CliCommandGenerator failures', () {
    test(
      'throws explicit error when @CliEnumSubCommand status is missing',
      () async {
        final String root = Directory.current.path;
        final testDir = Directory('$root/test/core/cli_generator/test');
        await testDir.create(recursive: true);
        final fixturePath = '${testDir.path}/_tmp_invalid_cli_service.dart';
        final fixtureFile = File(fixturePath);

        await fixtureFile.writeAsString('''
import 'package:revitool/core/cli_generator/annotations.dart';

part '_tmp_invalid_cli_service.g.dart';

enum InvalidTarget { a }

@CliCommand(name: 'invalid', description: 'invalid')
abstract class InvalidCliService {
  @CliEnumSubCommand(name: 'bad', values: InvalidTarget.values)
  bool get bad;
}
''');

        try {
          final ProcessResult result = await Process.run(
            'dart',
            [
              'run',
              'build_runner',
              'build',
              '--delete-conflicting-outputs',
              '--build-filter=test/core/cli_generator/test/_tmp_invalid_cli_service.g.dart',
            ],
            workingDirectory: root,
            runInShell: true,
          );

          expect(result.exitCode, isNonZero);
          final output = '${result.stdout}\n${result.stderr}';
          expect(
            output,
            contains(
              '@CliEnumSubCommand requires a non-empty string "status".',
            ),
          );
        } finally {
          if (fixtureFile.existsSync()) {
            await fixtureFile.delete();
          }
          final generatedFile = File(
            '${testDir.path}/_tmp_invalid_cli_service.g.dart',
          );
          if (generatedFile.existsSync()) {
            await generatedFile.delete();
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
