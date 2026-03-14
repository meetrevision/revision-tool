import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../performance_service.dart';

class PowerplanSection extends ConsumerWidget {
  const PowerplanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(reviPowerPlanStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.rocket_20_regular,
      label: t.tweaksPerformancePowerPlan,
      description: t.tweaksPerformancePowerPlanDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableReviPowerPlan()
              : await ref
                    .read(performanceServiceProvider)
                    .disableReviPowerPlan();
          ref.invalidate(reviPowerPlanStatusProvider);
          ref.invalidate(reviPowerPlanC6StatesStatusProvider);
        },
      ),
      initiallyExpanded: status,
      children: [
        CardListTile(
          title: t.tweaksPerformanceCStates,
          description: t.tweaksPerformanceCStatesDescription,
          trailing: CardToggleSwitch(
            enabled: status,
            value: ref.watch(reviPowerPlanC6StatesStatusProvider),
            onChanged: (value) async {
              value
                  ? await ref
                        .read(performanceServiceProvider)
                        .disableReviPowerPlanC6States()
                  : await ref
                        .read(performanceServiceProvider)
                        .enableReviPowerPlanC6States();
              ref.invalidate(reviPowerPlanC6StatesStatusProvider);
            },
          ),
        ),
      ],
    );
  }
}
