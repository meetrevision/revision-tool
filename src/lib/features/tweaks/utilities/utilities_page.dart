import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/card_highlight.dart';
import '../../../extensions.dart';
import '../../../i18n/generated/strings.g.dart';
import '../../../utils_gui.dart';
import 'utilities_service.dart';

class UtilitiesPage extends ConsumerWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hibernationStatus = ref.watch(hibernationStatusProvider);

    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,

      children: [
        const _HibernationCard(),
        if (hibernationStatus || kDebugMode) const _FastStartupCard(),
        const _TMMonitoringCard(),
        // const _MPOCard(),
        const _UsageReportingCard(),
      ].withSpacing(5),
    );
  }
}

class _HibernationCard extends ConsumerWidget {
  const _HibernationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(hibernationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: t.tweaksUtilitiesHibernate,
      description: t.tweaksUtilitiesHibernateDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(utilitiesServiceProvider).enableHibernation()
              : await ref.read(utilitiesServiceProvider).disableHibernation();
          ref.invalidate(hibernationStatusProvider);
        },
      ),
    );
  }
}

class _FastStartupCard extends ConsumerWidget {
  const _FastStartupCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(fastStartupStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.flash_20_regular,
      label: t.tweaksUtilitiesFastStartup,
      description: t.tweaksUtilitiesFastStartupDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? ref.read(utilitiesServiceProvider).enableFastStartup()
              : await ref.read(utilitiesServiceProvider).disableFastStartup();
          ref.invalidate(fastStartupStatusProvider);
        },
      ),
    );
  }
}

class _TMMonitoringCard extends ConsumerWidget {
  const _TMMonitoringCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(tmMonitoringStatusProvider);

    return CardHighlight(
      icon: FluentIcons.task_manager,
      label: t.tweaksUtilitiesTMMonitoring,
      description: t.tweaksUtilitiesTMMonitoringDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(utilitiesServiceProvider).enableTMMonitoring()
              : await ref.read(utilitiesServiceProvider).disableTMMonitoring();
          ref.invalidate(tmMonitoringStatusProvider);
        },
      ),
    );
  }
}

class _UsageReportingCard extends ConsumerWidget {
  const _UsageReportingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(usageReportingStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.battery_checkmark_20_regular,
      label: t.tweaksUtilitiesUsageReporting,
      description: t.tweaksUtilitiesUsageReportingDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(utilitiesServiceProvider).enableUsageReporting()
              : await ref
                    .read(utilitiesServiceProvider)
                    .disableUsageReporting();
          ref.invalidate(usageReportingStatusProvider);
        },
      ),
    );
  }
}
