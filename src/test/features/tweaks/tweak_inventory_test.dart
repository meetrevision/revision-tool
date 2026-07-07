import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/inventory/tweak_inventory.dart';

void main() {
  test('declares the controller states required by the profile plan', () {
    expect(
      TweakControllerState.values.map((state) => state.name),
      containsAll(<String>[
        'enabled',
        'disabled',
        'blocked',
        'failed',
        'pendingReboot',
        'unknown',
        'managedByProfile',
        'userOverride',
        'dangerousPendingConfirmation',
      ]),
    );
  });

  test('represents every existing tweak CLI surface in the inventory', () {
    const expectedIds = <String>{
      'performance.powerplan',
      'performance.powerplan-states-c6',
      'performance.superfetch',
      'performance.memory-compression',
      'performance.intel-tsx',
      'performance.swapchain-fso',
      'performance.swapchain-wo',
      'performance.swapchain-mpo',
      'performance.background-apps',
      'performance.ctfmon-input',
      'performance.ntfs-last-access',
      'performance.ntfs-8dot3-naming',
      'performance.ntfs-memory-usage',
      'performance.service-grouping',
      'performance.background-window-message-rate-limit',
      'personalization.notification',
      'personalization.legacy-balloon',
      'personalization.screen-edge-swipe',
      'personalization.new-context-menu',
      'personalization.input-personalization',
      'personalization.caps-lock',
      'personalization.explorer-home',
      'personalization.explorer-gallery',
      'security.defender',
      'security.uac',
      'security.mitigation.meltdown-spectre',
      'security.mitigation.downfall',
      'security.vbs',
      'security.memory-integrity',
      'updates.certificates',
      'updates.kgl',
      'updates.wu-pause-updates',
      'updates.wu-visibility',
      'updates.wu-drivers',
      'utilities.hibernation',
      'utilities.fast-startup',
      'utilities.modern-standby',
      'utilities.tm-monitoring',
      'utilities.usage-reporting',
      'playbook.patches',
    };

    final Set<String> actualIds = tweakInventory
        .map((TweakDefinition tweak) => tweak.id)
        .toSet();

    expect(actualIds, expectedIds);
    expect(tweakControllerInventoryIds, expectedIds);
  });

  test('contains complete declarative metadata for every tweak', () {
    final ids = <String>{};

    for (final TweakDefinition tweak in tweakInventory) {
      expect(ids.add(tweak.id), isTrue, reason: 'duplicate ${tweak.id}');
      expect(tweak.id, isNotEmpty);
      expect(tweak.category.displayName, isNotEmpty, reason: tweak.id);
      expect(tweak.name, isNotEmpty, reason: tweak.id);
      expect(tweak.technicalDescription, isNotEmpty, reason: tweak.id);
      expect(tweak.expectedImpact, isNotEmpty, reason: tweak.id);
      expect(tweak.profiles, isNotEmpty, reason: tweak.id);
      expect(tweak.dependencies, isNotEmpty, reason: tweak.id);
      expect(tweak.detection, isNotEmpty, reason: tweak.id);
      expect(tweak.apply, isNotEmpty, reason: tweak.id);
      expect(tweak.verify, isNotEmpty, reason: tweak.id);
      expect(tweak.rollback, isNotEmpty, reason: tweak.id);
      expect(tweak.logs, isNotEmpty, reason: tweak.id);
      expect(tweak.reason, isNotEmpty, reason: tweak.id);
      expect(tweak.warnings, isNotEmpty, reason: tweak.id);
      expect(tweak.evidence, isNotEmpty, reason: tweak.id);
    }
  });

  test('profile matrix is strictly progressive', () {
    final Map<OptimizationProfile, List<TweakDefinition>> matrix =
        buildTweakProfileMatrix(tweakInventory);
    final List<int> counts = OptimizationProfile.values
        .map((OptimizationProfile profile) => matrix[profile]!.length)
        .toList(growable: false);

    expect(counts[0], greaterThan(0));
    expect(counts[1], greaterThan(counts[0]));
    expect(counts[2], greaterThan(counts[1]));
    expect(counts[3], greaterThan(counts[2]));
  });

  test('YAML mirror contains every inventory entry', () {
    final String yaml = File(tweakInventoryYamlPath).readAsStringSync();

    for (final TweakDefinition tweak in tweakInventory) {
      expect(yaml, contains('id: ${tweak.id}'), reason: tweak.id);
    }
  });
}
