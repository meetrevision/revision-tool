import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:revitool/extensions.dart';

import 'package:revitool/features/tweaks/performance/performance_service.dart';

class MemoryStorageSection extends StatelessWidget {
  const MemoryStorageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.memory_16_regular,
      label: context.l10n.tweaksPerformanceMemory,
      description: context.l10n.tweaksPerformanceMemoryDescription,
      children: const [
        _SuperfetchCard(),
        _MemoryCompressionCard(),
        _ServicesGroupingCard(),
        _LastTimeAccessCard(),
        _Dot3NamingCard(),
        _MemoryUsageCard(),
      ],
    );
  }
}

class _SuperfetchCard extends ConsumerWidget {
  const _SuperfetchCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(superfetchStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.top_speed_20_regular,
      title: context.l10n.tweaksPerformanceRdyBoost,
      description: context.l10n.tweaksPerformanceRdyBoostDescription,
      trailing: CardToggleSwitch(
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

    return CardListTile(
      // icon: msicons.FluentIcons.ram_20_regular,
      title: context.l10n.tweaksPerformanceMemoryCompression,
      description: context.l10n.tweaksPerformanceMemoryCompressionDescription,
      trailing: CardToggleSwitch(
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

class _ServicesGroupingCard extends ConsumerWidget {
  const _ServicesGroupingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(servicesGroupingStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.group_20_regular,
      title: context.l10n.tweaksPerformanceServiceGrouping,
      description: context.l10n.tweaksPerformanceServiceGroupingDescription,
      trailing: ComboBox<ServiceGrouping>(
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
        content: Text(context.l10n.tweaksPerformanceServiceGroupingDialog),
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

class _LastTimeAccessCard extends ConsumerWidget {
  const _LastTimeAccessCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(lastTimeAccessNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
      title: context.l10n.tweaksPerformanceLastTimeAccess,
      description: context.l10n.tweaksPerformanceLastTimeAccessDescription,
      trailing: CardToggleSwitch(
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

    return CardListTile(
      // icon: msicons.FluentIcons.hard_drive_20_regular,
      title: context.l10n.tweaksPerformance8dot3Naming,
      description: context.l10n.tweaksPerformance8dot3NamingDescription,
      trailing: CardToggleSwitch(
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

    return CardListTile(
      // icon: msicons.FluentIcons.memory_16_regular,
      title: context.l10n.tweaksPerformancePagedPoolLimit,
      description: context.l10n.tweaksPerformancePagedPoolLimitDescription,
      trailing: CardToggleSwitch(
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
