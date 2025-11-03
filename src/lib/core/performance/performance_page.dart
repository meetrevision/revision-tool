import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/core/performance/performance_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:revitool/shared/widgets/subtitle.dart';

class PerformancePage extends ConsumerWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pagePerformance)),
      children: [
        const _SuperfetchCard(),
        const _MemoryCompressionCard(),
        if (WinRegistryService.isIntelCpu || kDebugMode) const _IntelTSXCard(),
        const _FullscreenOptimizationCard(),
        if (WinRegistryService.isW11 || kDebugMode) ...[
          const _WindowedOptimizationCard(),
        ],
        const _BackgroundAppsCard(),
        const _ServicesGroupingCard(),
        if (WinRegistryService.isW11 || kDebugMode) ...[
          const _BackgroundWindowMessageRateCard(),
        ],
        if (ref.watch(settingsExperimentalStatus)) ...[
          const _CStatesCard(),
          Subtitle(content: Text(context.l10n.perfSectionFS)),
          const _LastTimeAccessCard(),
          const _Dot3NamingCard(),
          const _MemoryUsageCard(),
        ],
      ],
    );
  }
}

class _SuperfetchCard extends ConsumerWidget {
  const _SuperfetchCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(superfetchStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.top_speed_20_regular,
      label: context.l10n.perfSuperfetchLabel,
      description: context.l10n.perfSuperfetchDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableSuperfetch()
              : await ref.read(performanceServiceProvider).disableSuperfetch();

          ref.invalidate(superfetchStatusProvider);
        },
      ),
    );
  }
}

class _MemoryCompressionCard extends ConsumerWidget {
  const _MemoryCompressionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final superfetchStatus = ref.watch(superfetchStatusProvider);
    final memoryCompressionStatus = ref.watch(memoryCompressionStatusProvider);

    if (!superfetchStatus) {
      return const SizedBox();
    }

    return CardHighlight(
      icon: msicons.FluentIcons.ram_20_regular,
      label: context.l10n.perfMCLabel,
      description: context.l10n.perfMCDescription,
      action: CardToggleSwitch(
        value: memoryCompressionStatus,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .enableMemoryCompression()
              : await ref
                    .read(performanceServiceProvider)
                    .disableMemoryCompression();
          ref.invalidate(memoryCompressionStatusProvider);
        },
      ),
    );
  }
}

class _IntelTSXCard extends ConsumerWidget {
  const _IntelTSXCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(intelTSXStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.transmission_20_regular,
      label: context.l10n.perfITSXLabel,
      description: context.l10n.perfITSXDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableIntelTSX()
              : await ref.read(performanceServiceProvider).disableIntelTSX();
          ref.invalidate(intelTSXStatusProvider);
        },
      ),
    );
  }
}

class _FullscreenOptimizationCard extends ConsumerWidget {
  const _FullscreenOptimizationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(fullscreenOptimizationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.desktop_20_regular,
      label: context.l10n.perfFOLabel,
      description: context.l10n.perfFODescription,
      action: CardToggleSwitch(
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

    return CardHighlight(
      icon: msicons.FluentIcons.desktop_mac_20_regular,
      label: context.l10n.perfOWGLabel,
      description: context.l10n.perfOWGDescription,
      action: CardToggleSwitch(
        value: status,
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

class _BackgroundAppsCard extends ConsumerWidget {
  const _BackgroundAppsCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backgroundAppsStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.bezier_curve_square_20_regular,
      label: context.l10n.perfBALabel,
      description: context.l10n.perfBADescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .enableBackgroundApps()
              : await ref
                    .read(performanceServiceProvider)
                    .disableBackgroundApps();
          ref.invalidate(backgroundAppsStatusProvider);
        },
      ),
    );
  }
}

class _ServicesGroupingCard extends ConsumerWidget {
  const _ServicesGroupingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(servicesGroupingStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.group_20_regular,
      label: context.l10n.perfSGMLabel,
      description: context.l10n.perfSGMDescription,
      action: ComboBox<ServiceGrouping>(
        value: status,
        onChanged: (value) async {
          if (value == null) return;

          switch (value) {
            case ServiceGrouping.forced:
              _showServicesGroupingWarning(context);
              ref.read(performanceServiceProvider).forcedServicesGrouping();
              break;
            case ServiceGrouping.recommended:
              ref
                  .read(performanceServiceProvider)
                  .recommendedServicesGrouping();
              break;
            case ServiceGrouping.disabled:
              ref.read(performanceServiceProvider).disableServicesGrouping();
              break;
          }
          ref.invalidate(servicesGroupingStatusProvider);
        },
        items: const [
          ComboBoxItem(value: ServiceGrouping.forced, child: Text("Forced")),
          ComboBoxItem(
            value: ServiceGrouping.recommended,
            child: Text("Recommended"),
          ),
          ComboBoxItem(
            value: ServiceGrouping.disabled,
            child: Text("Disabled"),
          ),
        ],
      ),
    );
  }

  void _showServicesGroupingWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
        title: Text(context.l10n.warning),
        content: Text(context.l10n.perfSGMDialog),
        actions: [
          FilledButton(
            child: Text(context.l10n.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _BackgroundWindowMessageRateCard extends ConsumerWidget {
  const _BackgroundWindowMessageRateCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backgroundWindowMessageRateLimitStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.group_20_regular,
      label: context.l10n.perfBWMRLabel,
      description: context.l10n.perfBWMRDescription,
      action: ComboBox<int>(
        value: 1000 ~/ status,
        onChanged: (value) async {
          if (value == null) return;

          try {
            ref
                .read(performanceServiceProvider)
                .setBackgroundWindowMessageRateLimit(value);
          } catch (e) {
            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                title: Text(context.l10n.perfBWMRLabel),
                content: Text(e.toString()),
                actions: [
                  FilledButton(
                    child: Text(context.l10n.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          }
          ref.invalidate(backgroundWindowMessageRateLimitStatusProvider);
        },
        items: const [
          ComboBoxItem(value: 20, child: Text("50Hz")),
          ComboBoxItem(value: 8, child: Text("125Hz (Default)")),
        ],
      ),
    );
  }
}

class _CStatesCard extends ConsumerWidget {
  const _CStatesCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cStatesStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: context.l10n.perfCStatesLabel,
      description: context.l10n.perfCStatesDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).disableCStates()
              : await ref.read(performanceServiceProvider).enableCStates();
          ref.invalidate(cStatesStatusProvider);
        },
      ),
    );
  }
}

class _LastTimeAccessCard extends ConsumerWidget {
  const _LastTimeAccessCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(lastTimeAccessNTFSStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
      label: context.l10n.perfLTALabel,
      description: context.l10n.perfLTADescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .disableLastTimeAccessNTFS()
              : await ref
                    .read(performanceServiceProvider)
                    .enableLastTimeAccessNTFS();
          ref.invalidate(lastTimeAccessNTFSStatusProvider);
        },
      ),
    );
  }
}

class _Dot3NamingCard extends ConsumerWidget {
  const _Dot3NamingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dot3NamingNTFSStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.hard_drive_20_regular,
      label: context.l10n.perfEdTLabel,
      description: context.l10n.perfEdTDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .disable8dot3NamingNTFS()
              : await ref
                    .read(performanceServiceProvider)
                    .enable8dot3NamingNTFS();
          ref.invalidate(dot3NamingNTFSStatusProvider);
        },
      ),
    );
  }
}

class _MemoryUsageCard extends ConsumerWidget {
  const _MemoryUsageCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(memoryUsageNTFSStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.memory_16_regular,
      label: context.l10n.perfMULabel,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(performanceServiceProvider)
                    .enableMemoryUsageNTFS()
              : await ref
                    .read(performanceServiceProvider)
                    .disableMemoryUsageNTFS();
          ref.invalidate(memoryUsageNTFSStatusProvider);
        },
      ),
    );
  }
}
