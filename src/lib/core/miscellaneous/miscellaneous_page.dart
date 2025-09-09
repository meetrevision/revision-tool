import 'package:fluent_ui/fluent_ui.dart';
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
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageMiscellaneous)),
      children: [
        _HibernationCard(),
        _FastStartupCard(),
        _TMMonitoringCard(),
        _MPOCard(),
        _UsageReportingCard(),
        _UpdateKGLCard(),
      ],
    );
  }
}

class _HibernationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hibernationStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: context.l10n.miscHibernateLabel,
      description: context.l10n.miscHibernateDescription,
      switchBool: ValueNotifier(status),
      function: (value) async {
        value
            ? await MiscellaneousService.enableHibernation()
            : await MiscellaneousService.disableHibernation();
        ref.invalidate(hibernationStatusProvider);
      },
    );
  }
}

class _FastStartupCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(fastStartupStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.flash_20_regular,
      label: context.l10n.miscFastStartupLabel,
      description: context.l10n.miscFastStartupDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? MiscellaneousService.enableFastStartup()
            : MiscellaneousService.disableFastStartup();
        ref.invalidate(fastStartupStatusProvider);
      },
    );
  }
}

class _TMMonitoringCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(tmMonitoringStatusProvider);

    return CardHighlightSwitch(
      icon: FluentIcons.task_manager,
      label: context.l10n.miscTMMonitoringLabel,
      description: context.l10n.miscTMMonitoringDescription,
      switchBool: ValueNotifier(status),
      requiresRestart: true,
      function: (value) async {
        value
            ? await MiscellaneousService.enableTMMonitoring()
            : MiscellaneousService.disableTMMonitoring();
        ref.invalidate(tmMonitoringStatusProvider);
      },
    );
  }
}

class _MPOCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(mpoStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.window_settings_20_regular,
      label: context.l10n.miscMpoLabel,
      codeSnippet: context.l10n.miscMpoCodeSnippet,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? MiscellaneousService.enableMPO()
            : MiscellaneousService.disableMPO();
        ref.invalidate(mpoStatusProvider);
      },
    );
  }
}

class _UsageReportingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(usageReportingStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.battery_checkmark_20_regular,
      label: context.l10n.miscURLabel,
      description: context.l10n.miscURDescription,
      switchBool: ValueNotifier(status),
      function: (value) async {
        value
            ? await MiscellaneousService.enableUsageReporting()
            : await MiscellaneousService.disableUsageReporting();
        ref.invalidate(usageReportingStatusProvider);
      },
    );
  }
}

class _UpdateKGLCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.xbox_controller_20_regular,
      label: context.l10n.miscUpdateKGL,
      description: context.l10n.miscUpdateKGLDescription,
      child: SizedBox(
        width: 150,
        child: FilledButton(
          onPressed: () async {
            String message = "";
            try {
              showLoadingDialog(
                context,
                "${context.l10n.settingsUpdatingStatus} KGL",
              );
              await MiscellaneousService.updateKGL();
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
