import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/services/win_registry_command.dart';
import 'package:revitool/core/services/win_registry_service.dart';

void main() {
  group('FeatureCommand structure under registry', () {
    test('registers enable, disable, and reset subcommands', () {
      final regCmd = WinRegistryServiceCliCommand(const WinRegistryCliService());
      expect(regCmd.subcommands.keys, contains('feature'));

      final Command<void> featureCmd = regCmd.subcommands['feature']!;
      expect(featureCmd.name, equals('feature'));
      expect(featureCmd.aliases, contains('features'));
      expect(featureCmd.subcommands.keys, containsAll(['enable', 'disable', 'reset']));
      expect(featureCmd.subcommands.keys, isNot(contains('delete')));
    });
  });

  group('Feature ID parsing', () {
    CommandRunner<void> createRunner() =>
        CommandRunner<void>('revitool', 'test')
          ..addCommand(WinRegistryServiceCliCommand(const WinRegistryCliService()));

    Command<void> getSubcommand(CommandRunner<void> runner, String action) =>
        runner.commands['registry']!.subcommands['feature']!.subcommands[action]!;

    test('parses comma-separated IDs via --id', () {
      final CommandRunner<void> runner = createRunner();
      final Command<void> cmd = getSubcommand(runner, 'disable');
      final ArgResults argResults = cmd.argParser.parse(['--id', '58375066,40012896']);
      final Set<int> ids = WinRegistryServiceCliCommand.parseFeatureIds(argResults, cmd.usage);

      expect(ids, equals({58375066, 40012896}));
    });

    test('parses comma-separated IDs via -i abbr', () {
      final CommandRunner<void> runner = createRunner();
      final Command<void> cmd = getSubcommand(runner, 'enable');
      final ArgResults argResults = cmd.argParser.parse(['-i', '58375066,40012896']);
      final Set<int> ids = WinRegistryServiceCliCommand.parseFeatureIds(argResults, cmd.usage);

      expect(ids, equals({58375066, 40012896}));
    });

    test('parses repeated --id options', () {
      final CommandRunner<void> runner = createRunner();
      final Command<void> cmd = getSubcommand(runner, 'reset');
      final ArgResults argResults = cmd.argParser.parse(['--id', '58375066', '--id', '40012896']);
      final Set<int> ids = WinRegistryServiceCliCommand.parseFeatureIds(argResults, cmd.usage);

      expect(ids, equals({58375066, 40012896}));
    });

    test('parses positional IDs separated by comma or space', () {
      final CommandRunner<void> runner = createRunner();
      final Command<void> cmd = getSubcommand(runner, 'disable');

      final ArgResults argResultsComma = cmd.argParser.parse(['58375066,40012896']);
      expect(
        WinRegistryServiceCliCommand.parseFeatureIds(argResultsComma, cmd.usage),
        equals({58375066, 40012896}),
      );

      final ArgResults argResultsSpace = cmd.argParser.parse(['58375066', '40012896']);
      expect(
        WinRegistryServiceCliCommand.parseFeatureIds(argResultsSpace, cmd.usage),
        equals({58375066, 40012896}),
      );
    });

    test('throws UsageException on invalid ID', () {
      final CommandRunner<void> runner = createRunner();
      final Command<void> cmd = getSubcommand(runner, 'disable');
      final ArgResults argResults = cmd.argParser.parse(['--id', 'not_a_number']);

      expect(
        () => WinRegistryServiceCliCommand.parseFeatureIds(argResults, cmd.usage),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('Invalid Windows feature ID'),
          ),
        ),
      );
    });

    test('throws UsageException when no IDs are provided', () {
      final CommandRunner<void> runner = createRunner();
      final Command<void> cmd = getSubcommand(runner, 'disable');
      final ArgResults argResults = cmd.argParser.parse([]);

      expect(
        () => WinRegistryServiceCliCommand.parseFeatureIds(argResults, cmd.usage),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('Provide at least one'),
          ),
        ),
      );
    });
  });
}
