import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/controller/tweak_commands.dart';
import 'package:revitool/features/tweaks/controller/tweak_controller.dart';
import 'package:revitool/features/tweaks/inventory/tweak_inventory.dart';

void main() {
  late TweakController controller;
  late ProfileController profiles;
  late RollbackManager rollback;
  late CommandRunner<void> runner;

  setUp(() {
    rollback = RollbackManager.inMemory();
    controller = TweakController(
      registry: TweakOperationRegistry(<String, TweakOperation>{
        for (final TweakDefinition tweak in tweakInventory)
          tweak.id: TweakOperation.noop(tweak.id),
      }),
      compatibilityChecker: const CompatibilityChecker(
        context: SystemContext.testSafe(),
      ),
      rollbackManager: rollback,
    );
    profiles = ProfileController(controller);
    runner = CommandRunner<void>('revitool', 'test')
      ..addCommand(ProfileCommand(profiles))
      ..addCommand(TweakCommand(controller))
      ..addCommand(ReportCommand(rollback));
  });

  test('profile list command is registered', () {
    final Command<void>? profile = runner.commands['profile'];

    expect(profile, isNotNull);
    expect(profile!.subcommands.keys, containsAll(<String>['list', 'apply']));
  });

  test('profile apply supports dry-run and profile names', () async {
    await runner.run(<String>[
      'profile',
      'apply',
      'gaming',
      '--dry-run',
    ]);

    expect(rollback.latestReport()?.profile, OptimizationProfile.gaming);
  });

  test('tweak enable blocks dangerous tweak without confirmation', () async {
    await runner.run(<String>['tweak', 'enable', 'security.defender']);

    final TweakResult result = rollback.latestReport()!.results.single;
    expect(result.state, TweakControllerState.dangerousPendingConfirmation);
  });

  test('report last returns without throwing after an operation', () async {
    await runner.run(<String>[
      'profile',
      'apply',
      'compatibility',
      '--dry-run',
    ]);

    await runner.run(<String>['report', '--last', '--json']);
  });

  test('profile rollback can target a specific application id', () async {
    await runner.run(<String>[
      'profile',
      'apply',
      'compatibility',
      '--dry-run',
    ]);
    final String applicationId = rollback.latestReport()!.applicationId;

    await runner.run(<String>[
      'profile',
      'rollback',
      '--application',
      applicationId,
      '--json',
    ]);

    expect(rollback.latestReport()!.applicationId, startsWith('rollback-'));
  });
}
