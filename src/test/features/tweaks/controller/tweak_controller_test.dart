import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/controller/tweak_controller.dart';
import 'package:revitool/features/tweaks/inventory/tweak_inventory.dart';

void main() {
  group('TweakController', () {
    test('dry-run marks profile-managed tweak without calling apply', () async {
      var applied = false;
      final TweakController controller = _controllerFor(
        _operation(
          id: 'performance.swapchain-fso',
          detect: false,
          apply: () async {
            applied = true;
          },
        ),
      );

      final TweakResult result = await controller.enable(
        'performance.swapchain-fso',
        const TweakExecutionOptions(
          dryRun: true,
          sourceProfile: OptimizationProfile.compatibility,
        ),
      );

      expect(applied, isFalse);
      expect(result.state, TweakControllerState.managedByProfile);
      expect(result.profile, OptimizationProfile.compatibility);
    });

    test('dangerous tweaks require confirmation flags', () async {
      final TweakController controller = _controllerFor(
        _operation(id: 'security.defender', detect: true),
      );

      final TweakResult result = await controller.enable('security.defender');

      expect(result.state, TweakControllerState.dangerousPendingConfirmation);
      expect(result.reason, contains('confirmation'));
    });

    test('confirmed dangerous tweak creates a backup and verifies', () async {
      var applied = false;
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'revi-controller-test-',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });
      final rollback = RollbackManager(rootDirectory: tempDir);
      final TweakController controller = _controllerFor(
        _operation(
          id: 'security.defender',
          detect: false,
          apply: () async {
            applied = true;
          },
        ),
        rollback: rollback,
      );

      final TweakResult result = await controller.enable(
        'security.defender',
        const TweakExecutionOptions(includeDangerous: true, assumeYes: true),
      );

      expect(applied, isTrue);
      expect(result.state, TweakControllerState.enabled);
      expect(result.backupId, isNotNull);
      expect(rollback.latestReport(), isNotNull);
    });

    test('guard blocks system-critical tweaks even in extreme', () async {
      final TweakController controller = _controllerFor(
        _operation(id: 'security.uac', detect: true),
      );

      final TweakResult result = await controller.enable(
        'security.uac',
        const TweakExecutionOptions(
          includeDangerous: true,
          assumeYes: true,
          sourceProfile: OptimizationProfile.extreme,
        ),
      );

      expect(result.state, TweakControllerState.blocked);
      expect(result.reason, contains('login'));
    });

    test('manual override is respected during profile apply', () async {
      final TweakController controller = _controllerFor(
        _operation(id: 'performance.swapchain-fso', detect: false),
      );
      final profiles = ProfileController(controller);
      await controller.setOverride('performance.swapchain-fso', enabled: false);

      final ProfileReport report = await profiles.apply(
        OptimizationProfile.compatibility,
      );
      final TweakResult result = report.results.singleWhere(
        (TweakResult item) => item.id == 'performance.swapchain-fso',
      );

      expect(result.state, TweakControllerState.userOverride);
    });

    test('profile application count is progressive', () async {
      final TweakController controller = _controllerForMany(tweakInventory);
      final profiles = ProfileController(controller);

      final ProfileReport compatibility = await profiles.apply(
        OptimizationProfile.compatibility,
        const ProfileApplyOptions(dryRun: true),
      );
      final ProfileReport gaming = await profiles.apply(
        OptimizationProfile.gaming,
        const ProfileApplyOptions(dryRun: true),
      );
      final ProfileReport performance = await profiles.apply(
        OptimizationProfile.performance,
        const ProfileApplyOptions(dryRun: true),
      );
      final ProfileReport extreme = await profiles.apply(
        OptimizationProfile.extreme,
        const ProfileApplyOptions(dryRun: true),
      );

      expect(gaming.results.length, greaterThan(compatibility.results.length));
      expect(performance.results.length, greaterThan(gaming.results.length));
      expect(extreme.results.length, greaterThan(performance.results.length));
    });

    test('rolls back a stored profile report by application id', () async {
      var rolledBack = false;
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'revi-controller-report-test-',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });
      final rollback = RollbackManager(rootDirectory: tempDir);
      final TweakController controller = _controllerFor(
        _operation(
          id: 'performance.swapchain-fso',
          detect: false,
          rollback: () async {
            rolledBack = true;
          },
        ),
        rollback: rollback,
      );
      final profiles = ProfileController(controller);

      final ProfileReport applied = await profiles.apply(
        OptimizationProfile.compatibility,
        const ProfileApplyOptions(dryRun: true),
      );
      final ProfileReport? report = await profiles.rollbackApplication(
        applied.applicationId,
      );

      expect(report, isNotNull);
      expect(rolledBack, isTrue);
      expect(report!.applicationId, startsWith('rollback-'));
    });
  });
}

TweakController _controllerFor(
  TweakOperation operation, {
  RollbackManager? rollback,
}) {
  return TweakController(
    registry: TweakOperationRegistry(<String, TweakOperation>{
      operation.id: operation,
    }),
    compatibilityChecker: const CompatibilityChecker(
      context: SystemContext.testSafe(),
    ),
    rollbackManager: rollback ?? RollbackManager.inMemory(),
  );
}

TweakController _controllerForMany(List<TweakDefinition> definitions) {
  return TweakController(
    registry: TweakOperationRegistry(<String, TweakOperation>{
      for (final TweakDefinition tweak in definitions)
        tweak.id: _operation(id: tweak.id, detect: false),
    }),
    compatibilityChecker: const CompatibilityChecker(
      context: SystemContext.testSafe(),
    ),
    rollbackManager: RollbackManager.inMemory(),
  );
}

TweakOperation _operation({
  required String id,
  required bool detect,
  bool verify = true,
  Future<void> Function()? apply,
  Future<void> Function()? rollback,
}) {
  return TweakOperation(
    id: id,
    detect: () async => detect,
    applyOptimized: apply ?? () async {},
    verifyOptimized: () async => verify,
    rollback: rollback ?? () async {},
  );
}
