import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../performance_service.dart';

class MemoryStorageSection extends StatelessWidget {
  const MemoryStorageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.memory_16_regular,
      label: t.tweaksPerformanceMemory,
      description: t.tweaksPerformanceMemoryDescription,
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
    final bool status = ref.watch(superfetchStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.top_speed_20_regular,
      title: t.tweaksPerformanceRdyBoost,
      description: t.tweaksPerformanceRdyBoostDescription,
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
    final bool superfetchStatus = ref.watch(superfetchStatusProvider);
    final bool memoryCompressionStatus = ref.watch(
      memoryCompressionStatusProvider,
    );

    if (!superfetchStatus) {
      return const SizedBox();
    }

    return CardListTile(
      // icon: msicons.FluentIcons.ram_20_regular,
      title: t.tweaksPerformanceMemoryCompression,
      description: t.tweaksPerformanceMemoryCompressionDescription,
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
    final ServiceGrouping status = ref.watch(servicesGroupingStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.group_20_regular,
      title: t.tweaksPerformanceServiceGrouping,
      description: t.tweaksPerformanceServiceGroupingDescription,
      trailing: ComboBox<ServiceGrouping>(
        value: status,
        onChanged: (value) async {
          if (value == null) return;

          switch (value) {
            case ServiceGrouping.forced:
              _showServicesGroupingWarning(context);
              await ref
                  .read(performanceServiceProvider)
                  .forcedServicesGrouping();
            case ServiceGrouping.recommended:
              await ref
                  .read(performanceServiceProvider)
                  .recommendedServicesGrouping();
            case ServiceGrouping.disabled:
              await ref
                  .read(performanceServiceProvider)
                  .disableServicesGrouping();
          }
          ref.invalidate(servicesGroupingStatusProvider);
        },
        items: const [
          ComboBoxItem(value: ServiceGrouping.forced, child: Text('Forced')),
          ComboBoxItem(
            value: ServiceGrouping.recommended,
            child: Text('Recommended'),
          ),
          ComboBoxItem(
            value: ServiceGrouping.disabled,
            child: Text('Disabled'),
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
        title: Text(t.warning),
        content: Text(t.tweaksPerformanceServiceGroupingDialog),
        actions: [
          FilledButton(child: Text(t.close), onPressed: () => context.pop()),
        ],
      ),
    );
  }
}

class _LastTimeAccessCard extends ConsumerWidget {
  const _LastTimeAccessCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(lastTimeAccessNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
      title: t.tweaksPerformanceLastTimeAccess,
      description: t.tweaksPerformanceLastTimeAccessDescription,
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
    final bool status = ref.watch(dot3NamingNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.hard_drive_20_regular,
      title: t.tweaksPerformance8dot3Naming,
      description: t.tweaksPerformance8dot3NamingDescription,
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
    final bool status = ref.watch(memoryUsageNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.memory_16_regular,
      title: t.tweaksPerformancePagedPoolLimit,
      description: t.tweaksPerformancePagedPoolLimitDescription,
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
