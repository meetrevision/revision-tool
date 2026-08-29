import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/win_registry_service.dart';
import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../performance_service.dart';

class const BackgroundManagementSection({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.radar_rectangle_multiple_20_regular,
      label: t.tweaksPerformanceBackground,
      description: t.tweaksPerformanceBackgroundDescription,
      children: [
        const _BackgroundAppsCard(),
        const _CtfmonInputCard(),
        if (WinRegistryService.isW11 || kDebugMode) ...[const _BackgroundWindowMessageRateCard()],
      ],
    );
  }
}

class const _BackgroundAppsCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(backgroundAppsStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.bezier_curve_square_20_regular,
      title: t.tweaksPerformanceBA,
      description: t.tweaksPerformanceBADescription,
      trailing: CardToggleSwitch(
        value: status,
        semanticLabel: t.tweaksPerformanceBA,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableBackgroundApps()
              : await ref.read(performanceServiceProvider).disableBackgroundApps();
          ref.invalidate(backgroundAppsStatusProvider);
        },
      ),
    );
  }
}

class const _CtfmonInputCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(ctfmonInputStatusProvider);

    // Credits to https://youtu.be/b6wfwG4jecQ for discovering
    return CardListTile(
      title: t.tweaksPerformanceCtfmonInput,
      description: t.tweaksPerformanceCtfmonInputDescription,
      descriptionLink: 'https://ctfmon.vercel.app/',
      trailing: CardToggleSwitch(
        value: !status,
        semanticLabel: t.tweaksPerformanceCtfmonInput,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).disableCtfmonInput()
              : await ref.read(performanceServiceProvider).enableCtfmonInput();
          ref.invalidate(ctfmonInputStatusProvider);
        },
      ),
    );
  }
}

class const _BackgroundWindowMessageRateCard() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int status = ref.watch(backgroundWindowMessageRateLimitStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.group_20_regular,
      title: t.tweaksPerformanceBWMR,
      description: t.tweaksPerformanceBWMRDescription,
      semanticLabel: t.tweaksPerformanceBWMR,
      trailing: ComboBox<int>(
        value: 1000 ~/ status,

        onChanged: (value) async {
          if (value == null) return;

          try {
            await ref.read(performanceServiceProvider).setBackgroundWindowMessageRateLimit(value);
          } catch (e) {
            if (!context.mounted) return;
            await showDialog(
              context: context,
              builder: (context) => ContentDialog(
                title: Text(t.tweaksPerformanceBWMR),
                content: Text(e.toString()),
                actions: [FilledButton(child: Text(t.close), onPressed: () => context.pop())],
              ),
            );
          }
          ref.invalidate(backgroundWindowMessageRateLimitStatusProvider);
        },
        items: const [
          ComboBoxItem(value: 20, child: Text('50Hz')),
          ComboBoxItem(value: 8, child: Text('125Hz (Default)')),
        ],
      ),
    );
  }
}
