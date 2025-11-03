import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/miscellaneous/miscellaneous_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/core/ms_store/widgets/msstore_dialogs.dart';

class MiscellaneousPage extends ConsumerWidget {
  const MiscellaneousPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hibernationStatus = ref.watch(hibernationStatusProvider);

    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageMiscellaneous)),
      children: [
        const _HibernationCard(),
        if (hibernationStatus || kDebugMode) const _FastStartupCard(),
        const _TMMonitoringCard(),
        const _MPOCard(),
        const _UsageReportingCard(),
        const _UpdateKGLCard(),
      ],
    );
  }
}

class _HibernationCard extends ConsumerWidget {
  const _HibernationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hibernationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: context.l10n.miscHibernateLabel,
      description: context.l10n.miscHibernateDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(miscellaneousServiceProvider).enableHibernation()
              : await ref
                    .read(miscellaneousServiceProvider)
                    .disableHibernation();
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
    final status = ref.watch(fastStartupStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.flash_20_regular,
      label: context.l10n.miscFastStartupLabel,
      description: context.l10n.miscFastStartupDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? ref.read(miscellaneousServiceProvider).enableFastStartup()
              : await ref
                    .read(miscellaneousServiceProvider)
                    .disableFastStartup();
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
    final status = ref.watch(tmMonitoringStatusProvider);

    return CardHighlight(
      icon: FluentIcons.task_manager,
      label: context.l10n.miscTMMonitoringLabel,
      description: context.l10n.miscTMMonitoringDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(miscellaneousServiceProvider)
                    .enableTMMonitoring()
              : await ref
                    .read(miscellaneousServiceProvider)
                    .disableTMMonitoring();
          ref.invalidate(tmMonitoringStatusProvider);
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

    return CardHighlight(
      icon: msicons.FluentIcons.window_settings_20_regular,
      label: context.l10n.miscMpoLabel,
      codeSnippet: context.l10n.miscMpoCodeSnippet,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? ref.read(miscellaneousServiceProvider).enableMPO()
              : await ref.read(miscellaneousServiceProvider).disableMPO();
          ref.invalidate(mpoStatusProvider);
        },
      ),
    );
  }
}

class _UsageReportingCard extends ConsumerWidget {
  const _UsageReportingCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(usageReportingStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.battery_checkmark_20_regular,
      label: context.l10n.miscURLabel,
      description: context.l10n.miscURDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(miscellaneousServiceProvider)
                    .enableUsageReporting()
              : await ref
                    .read(miscellaneousServiceProvider)
                    .disableUsageReporting();
          ref.invalidate(usageReportingStatusProvider);
        },
      ),
    );
  }
}

class _UpdateKGLCard extends ConsumerWidget {
  const _UpdateKGLCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.xbox_controller_20_regular,
      label: context.l10n.miscUpdateKGL,
      description: context.l10n.miscUpdateKGLDescription,
      action: SizedBox(
        width: 150,
        child: FilledButton(
          onPressed: () async {
            String message = "";
            try {
              showLoadingDialog(
                context,
                "${context.l10n.settingsUpdatingStatus} KGL",
              );
              await ref.read(miscellaneousServiceProvider).updateKGL();
              if (!context.mounted) return;
              message = context.l10n.restartDialog;
            } catch (e) {
              message = e.toString();
            } finally {
              context.pop();
              showRestartDialog(
                context,
                title: context.l10n.settingsUpdatingStatusSuccess,
                content: message,
              );
            }
          },
          child: Text(context.l10n.updateButton),
        ),
      ),
    );
  }
}
