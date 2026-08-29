import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../performance_service.dart';

class const MemoryStorageSection({super.key}) extends StatelessWidget {
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

class const _SuperfetchCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(superfetchStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.top_speed_20_regular,
      title: t.tweaksPerformanceRdyBoost,
      description: t.tweaksPerformanceRdyBoostDescription,
      trailing: CardToggleSwitch(
        value: status,
        semanticLabel: t.tweaksPerformanceRdyBoost,
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

class const _MemoryCompressionCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool superfetchStatus = ref.watch(superfetchStatusProvider);
    final bool memoryCompressionStatus = ref.watch(memoryCompressionStatusProvider);

    if (!superfetchStatus) {
      return const SizedBox();
    }

    return CardListTile(
      // icon: msicons.FluentIcons.ram_20_regular,
      title: t.tweaksPerformanceMemoryCompression,
      description: t.tweaksPerformanceMemoryCompressionDescription,
      trailing: CardToggleSwitch(
        value: memoryCompressionStatus,
        semanticLabel: t.tweaksPerformanceMemoryCompression,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableMemoryCompression()
              : await ref.read(performanceServiceProvider).disableMemoryCompression();
          ref.invalidate(memoryCompressionStatusProvider);
        },
      ),
    );
  }
}

class const _ServicesGroupingCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ServiceGrouping status = ref.watch(servicesGroupingStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.group_20_regular,
      title: t.tweaksPerformanceServiceGrouping,
      description: t.tweaksPerformanceServiceGroupingDescription,
      semanticLabel: t.tweaksPerformanceServiceGrouping,
      trailing: ComboBox<ServiceGrouping>(
        value: status,
        onChanged: (value) async {
          if (value == null) return;

          if (value == .forced) {
            _showServicesGroupingWarning(context);
          }
          await ref.read(performanceServiceProvider).setServiceGroupingMode(value);

          ref.invalidate(servicesGroupingStatusProvider);
        },
        items: const [
          ComboBoxItem(value: .forced, child: Text('Forced')),
          ComboBoxItem(value: .recommended, child: Text('Recommended')),
          ComboBoxItem(value: .disabled, child: Text('Disabled')),
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
        actions: [FilledButton(child: Text(t.close), onPressed: () => context.pop())],
      ),
    );
  }
}

class const _LastTimeAccessCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(lastTimeAccessNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
      title: t.tweaksPerformanceLastTimeAccess,
      description: t.tweaksPerformanceLastTimeAccessDescription,
      trailing: CardToggleSwitch(
        value: status,
        semanticLabel: t.tweaksPerformanceLastTimeAccess,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableLastTimeAccessNTFS()
              : await ref.read(performanceServiceProvider).disableLastTimeAccessNTFS();
          ref.invalidate(lastTimeAccessNTFSStatusProvider);
        },
      ),
    );
  }
}

class const _Dot3NamingCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(dot3NamingNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.hard_drive_20_regular,
      title: t.tweaksPerformance8dot3Naming,
      description: t.tweaksPerformance8dot3NamingDescription,
      trailing: CardToggleSwitch(
        value: status,
        semanticLabel: t.tweaksPerformance8dot3Naming,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enable8dot3NamingNTFS()
              : await ref.read(performanceServiceProvider).disable8dot3NamingNTFS();
          ref.invalidate(dot3NamingNTFSStatusProvider);
        },
      ),
    );
  }
}

class const _MemoryUsageCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(memoryUsageNTFSStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.memory_16_regular,
      title: t.tweaksPerformancePagedPoolLimit,
      description: t.tweaksPerformancePagedPoolLimitDescription,
      trailing: CardToggleSwitch(
        value: status,
        semanticLabel: t.tweaksPerformancePagedPoolLimit,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableMemoryUsageNTFS()
              : await ref.read(performanceServiceProvider).disableMemoryUsageNTFS();
          ref.invalidate(memoryUsageNTFSStatusProvider);
        },
      ),
    );
  }
}
