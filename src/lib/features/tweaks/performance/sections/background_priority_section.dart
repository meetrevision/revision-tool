import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:revitool/core/services/win_registry_service.dart';

import 'package:revitool/features/tweaks/performance/performance_service.dart';
import 'package:revitool/i18n/generated/strings.g.dart';

class BackgroundManagementSection extends StatelessWidget {
  const BackgroundManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.radar_rectangle_multiple_20_regular,
      label: t.tweaksPerformanceBackground,
      description: t.tweaksPerformanceBackgroundDescription,
      children: [
        const _BackgroundAppsCard(),
        if (WinRegistryService.isW11 || kDebugMode) ...[
          const _BackgroundWindowMessageRateCard(),
        ],
      ],
    );
  }
}

class _BackgroundAppsCard extends ConsumerWidget {
  const _BackgroundAppsCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backgroundAppsStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.bezier_curve_square_20_regular,
      title: t.tweaksPerformanceBA,
      description: t.tweaksPerformanceBADescription,
      trailing: CardToggleSwitch(
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

class _BackgroundWindowMessageRateCard extends ConsumerWidget {
  const _BackgroundWindowMessageRateCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backgroundWindowMessageRateLimitStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.group_20_regular,
      title: t.tweaksPerformanceBWMR,
      description: t.tweaksPerformanceBWMRDescription,
      trailing: ComboBox<int>(
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
                title: Text(t.tweaksPerformanceBWMR),
                content: Text(e.toString()),
                actions: [
                  FilledButton(
                    child: Text(t.close),
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
