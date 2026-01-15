import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/features/tweaks/performance/performance_service.dart';
import 'package:revitool/i18n/generated/strings.g.dart';

class PresentationSection extends ConsumerWidget {
  const PresentationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.window_shield_24_regular,
      label: t.tweaksPerformancePresentation,
      descriptionLink: "https://wiki.special-k.info/en/SwapChain",
      children: const [
        _FullscreenOptimizationCard(),
        _WindowedOptimizationCard(),
        _MPOCard(),
      ],
    );
  }
}

class _FullscreenOptimizationCard extends ConsumerWidget {
  const _FullscreenOptimizationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(fullscreenOptimizationStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.desktop_20_regular,
      title: t.tweaksPerformanceFSO,
      description: t.tweaksPerformanceFSODescription,
      trailing: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .enableFullscreenOptimization()
              : await ref
                    .read(performanceServiceProvider)
                    .disableFullscreenOptimization();
          ref.invalidate(fullscreenOptimizationStatusProvider);
        },
      ),
    );
  }
}

class _WindowedOptimizationCard extends ConsumerWidget {
  const _WindowedOptimizationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(windowedOptimizationStatusProvider);

    return CardListTile(
      title: t.tweaksPerformanceOWG,
      description: t.tweaksPerformanceOWGDescription,
      trailing: CardToggleSwitch(
        enabled: !WinRegistryService.isW11 || kDebugMode,
        value: !WinRegistryService.isW11 ? false : status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .enableWindowedOptimization()
              : await ref
                    .read(performanceServiceProvider)
                    .disableWindowedOptimization();
          ref.invalidate(windowedOptimizationStatusProvider);
        },
      ),
    );
  }
}

class _MPOCard extends ConsumerWidget {
  const _MPOCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(mpoStatusProvider);

    return CardListTile(
      title: t.tweaksPerformanceMPO,
      // description: t.miscMpoCodeSnippet,
      description: t.tweaksPerformanceMPODescription,
      trailing: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableMPO()
              : await ref.read(performanceServiceProvider).disableMPO();
          ref.invalidate(mpoStatusProvider);
        },
      ),
    );
  }
}
