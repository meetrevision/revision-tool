import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/tweaks/controller/tweak_controller.dart';
import 'package:revitool/features/tweaks/controller/tweak_controller_view_model.dart';
import 'package:revitool/features/tweaks/inventory/tweak_inventory.dart';

void main() {
  group('TweakControllerViewModel', () {
    test('counts states from latest results', () {
      final model = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{
          'performance.powerplan': TweakResult(
            id: 'performance.powerplan',
            state: TweakControllerState.enabled,
          ),
          'security.uac': TweakResult(
            id: 'security.uac',
            state: TweakControllerState.blocked,
          ),
          'security.defender': TweakResult(
            id: 'security.defender',
            state: TweakControllerState.dangerousPendingConfirmation,
          ),
          'performance.background-apps': TweakResult(
            id: 'performance.background-apps',
            state: TweakControllerState.failed,
          ),
        },
        filters: const TweakControllerFilters(),
      );

      expect(model.counts.total, tweakInventory.length);
      expect(model.counts.enabled, 1);
      expect(model.counts.blocked, 1);
      expect(model.counts.pending, 1);
      expect(model.counts.failed, 1);
      expect(model.counts.unknown, tweakInventory.length - 4);
    });

    test('filters by profile, risk, category, and state', () {
      final model = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{
          'security.defender': TweakResult(
            id: 'security.defender',
            state: TweakControllerState.dangerousPendingConfirmation,
          ),
        },
        filters: const TweakControllerFilters(
          profile: OptimizationProfile.extreme,
          risk: TweakRisk.dangerous,
          category: TweakCategory.windowsDefender,
          state: TweakControllerState.dangerousPendingConfirmation,
        ),
      );

      expect(model.visibleRows, hasLength(1));
      expect(model.visibleRows.single.tweak.id, 'security.defender');
    });

    test('search matches name, id, category, and description', () {
      final byName = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{},
        filters: const TweakControllerFilters(query: 'fullscreen'),
      );
      final byId = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{},
        filters: const TweakControllerFilters(query: 'swapchain-fso'),
      );
      final byCategory = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{},
        filters: const TweakControllerFilters(query: 'windows defender'),
      );
      final byDescription = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{},
        filters: const TweakControllerFilters(query: 'memory compression'),
      );

      expect(
        byName.visibleRows.map((TweakRowView row) => row.tweak.id),
        contains('performance.swapchain-fso'),
      );
      expect(byId.visibleRows.single.tweak.id, 'performance.swapchain-fso');
      expect(
        byCategory.visibleRows.map((TweakRowView row) => row.tweak.id),
        contains('security.defender'),
      );
      expect(
        byDescription.visibleRows.map((TweakRowView row) => row.tweak.id),
        contains('performance.memory-compression'),
      );
    });

    test('groups visible tweaks by category in inventory category order', () {
      final model = TweakControllerViewModel.build(
        tweaks: tweakInventory,
        results: const <String, TweakResult>{},
        filters: const TweakControllerFilters(
          profile: OptimizationProfile.gaming,
        ),
      );

      expect(model.groups, isNotEmpty);
      expect(
        model.groups.map((TweakCategoryGroup group) => group.category).toList(),
        orderedEquals(
          model.groups
              .map((TweakCategoryGroup group) => group.category)
              .toList()
            ..sort(
              (TweakCategory left, TweakCategory right) =>
                  left.index.compareTo(right.index),
            ),
        ),
      );
      expect(
        model.visibleRows.every(
          (TweakRowView row) =>
              row.tweak.profiles.contains(OptimizationProfile.gaming),
        ),
        isTrue,
      );
    });
  });
}
