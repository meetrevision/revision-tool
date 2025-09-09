import 'package:fluent_ui/fluent_ui.dart';
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
      resizeToAvoidBottomInset: false,
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pagePerformance)),
      children: [
        _SuperfetchCard(),
        _MemoryCompressionCard(),
        _IntelTSXCard(),
        _FullscreenOptimizationCard(),
        if (WinRegistryService.isW11) _WindowedOptimizationCard(),
        _BackgroundAppsCard(),
        _ServicesGroupingCard(),
        if (ref.watch(settingsExperimentalStatus)) ...[
          _CStatesCard(),
          Subtitle(content: Text(context.l10n.perfSectionFS)),
          _LastTimeAccessCard(),
          _Dot3NamingCard(),
          _MemoryUsageCard(),
        ],
      ],
    );
  }
}

class _SuperfetchCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(superfetchStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.top_speed_20_regular,
      label: context.l10n.perfSuperfetchLabel,
      description: context.l10n.perfSuperfetchDescription,
      switchBool: ValueNotifier(status),
      requiresRestart: true,
      function: (value) async {
        value
            ? await PerformanceService.enableSuperfetch()
            : await PerformanceService.disableSuperfetch();

        ref.invalidate(superfetchStatusProvider);
      },
    );
  }
}

class _MemoryCompressionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final superfetchStatus = ref.watch(superfetchStatusProvider);
    final memoryCompressionStatus = ref.watch(memoryCompressionStatusProvider);

    if (!superfetchStatus) {
      return const SizedBox();
    }

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.ram_20_regular,
      label: context.l10n.perfMCLabel,
      description: context.l10n.perfMCDescription,
      switchBool: ValueNotifier(memoryCompressionStatus),
      requiresRestart: true,
      function: (value) async {
        value
            ? await PerformanceService.enableMemoryCompression()
            : await PerformanceService.disableMemoryCompression();
        ref.invalidate(memoryCompressionStatusProvider);
      },
    );
  }
}

class _IntelTSXCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(intelTSXStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.transmission_20_regular,
      label: context.l10n.perfITSXLabel,
      description: context.l10n.perfITSXDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? PerformanceService.enableIntelTSX()
            : PerformanceService.disableIntelTSX();
        ref.invalidate(intelTSXStatusProvider);
      },
    );
  }
}

class _FullscreenOptimizationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(fullscreenOptimizationStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.desktop_20_regular,
      label: context.l10n.perfFOLabel,
      description: context.l10n.perfFODescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? PerformanceService.enableFullscreenOptimization()
            : PerformanceService.disableFullscreenOptimization();
        ref.invalidate(fullscreenOptimizationStatusProvider);
      },
    );
  }
}

class _WindowedOptimizationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(windowedOptimizationStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.desktop_mac_20_regular,
      label: context.l10n.perfOWGLabel,
      description: context.l10n.perfOWGDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? PerformanceService.enableWindowedOptimization()
            : PerformanceService.disableWindowedOptimization();
        ref.invalidate(windowedOptimizationStatusProvider);
      },
    );
  }
}

class _BackgroundAppsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backgroundAppsStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.bezier_curve_square_20_regular,
      label: context.l10n.perfBALabel,
      description: context.l10n.perfBADescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? PerformanceService.enableBackgroundApps()
            : PerformanceService.disableBackgroundApps();
        ref.invalidate(backgroundAppsStatusProvider);
      },
    );
  }
}

class _ServicesGroupingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(servicesGroupingStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.group_20_regular,
      label: context.l10n.perfSGMLabel,
      description: context.l10n.perfSGMDescription,
      child: ComboBox<ServiceGrouping>(
        value: status,
        onChanged: (value) {
          if (value == null) return;

          switch (value) {
            case ServiceGrouping.forced:
              _showServicesGroupingWarning(context);
              PerformanceService.forcedServicesGrouping();
              break;
            case ServiceGrouping.recommended:
              PerformanceService.recommendedServicesGrouping();
              break;
            case ServiceGrouping.disabled:
              PerformanceService.disableServicesGrouping();
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

class _CStatesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cStatesStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: context.l10n.perfCStatesLabel,
      description: context.l10n.perfCStatesDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? PerformanceService.disableCStates()
            : PerformanceService.enableCStates();
        ref.invalidate(cStatesStatusProvider);
      },
    );
  }
}

class _LastTimeAccessCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(lastTimeAccessNTFSStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
      label: context.l10n.perfLTALabel,
      description: context.l10n.perfLTADescription,
      switchBool: ValueNotifier(status),
      function: (value) async {
        value
            ? await PerformanceService.disableLastTimeAccessNTFS()
            : await PerformanceService.enableLastTimeAccessNTFS();
        ref.invalidate(lastTimeAccessNTFSStatusProvider);
      },
    );
  }
}

class _Dot3NamingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dot3NamingNTFSStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.hard_drive_20_regular,
      label: context.l10n.perfEdTLabel,
      description: context.l10n.perfEdTDescription,
      switchBool: ValueNotifier(status),
      function: (value) async {
        value
            ? await PerformanceService.disable8dot3NamingNTFS()
            : await PerformanceService.enable8dot3NamingNTFS();
        ref.invalidate(dot3NamingNTFSStatusProvider);
      },
    );
  }
}

class _MemoryUsageCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(memoryUsageNTFSStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.memory_16_regular,
      label: context.l10n.perfMULabel,
      switchBool: ValueNotifier(status),
      function: (value) async {
        value
            ? await PerformanceService.enableMemoryUsageNTFS()
            : await PerformanceService.disableMemoryUsageNTFS();
        ref.invalidate(memoryUsageNTFSStatusProvider);
      },
      codeSnippet: context.l10n.perfMUDescription,
    );
  }
}
