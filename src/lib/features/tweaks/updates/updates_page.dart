import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:revitool/core/widgets/subtitle.dart';
import 'package:revitool/features/ms_store/widgets/msstore_dialogs.dart';
import 'package:revitool/features/tweaks/updates/updates_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/i18n/generated/strings.g.dart';
import 'package:revitool/utils_gui.dart';

class UpdatesPage extends ConsumerWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,

      children: [
        const _CertificatesCard(),
        const _UpdateKGLCard(),
        Subtitle(content: Text(t.subtitleWindowsUpdates)),
        const _PauseUpdatesCard(),
        const _VisibilityCard(),
        const _DriversCard(),
      ].withSpacing(5),
    );
  }
}

class _CertificatesCard extends ConsumerWidget {
  const _CertificatesCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: move to troubleshooting page
    return CardHighlight(
      icon: msicons.FluentIcons.certificate_20_regular,
      label: t.tweaksSecurityCerts,
      description: t.tweaksSecurityCertsDescription,
      action: SizedBox(
        width: 150,
        child: Button(
          onPressed: () async {
            showLoadingDialog(context, "Updating Certificates");
            await ref.read(updatesServiceProvider).updateCertificates();

            if (!context.mounted) return;
            context.pop();
            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                content: Text(t.tweaksSecurityCertsUpdateDialog),
                actions: [
                  Button(
                    child: Text(t.okButton),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          },
          child: Text(t.updateButton),
        ),
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
      label: t.tweaksUtilitiesUpdateKGL,
      description: t.tweaksUtilitiesUpdateKGLDescription,
      action: SizedBox(
        width: 150,
        child: Button(
          onPressed: () async {
            String message = "";
            try {
              showLoadingDialog(context, "${t.settingsUpdatingStatus} KGL");
              await ref.read(updatesServiceProvider).updateKGL();
              if (!context.mounted) return;
              message = t.restartDialog;
            } catch (e) {
              message = e.toString();
            } finally {
              context.pop();
              showRestartDialog(
                context,
                title: t.settingsUpdatingStatusSuccess,
                content: message,
              );
            }
          },
          child: Text(t.updateButton),
        ),
      ),
    );
  }
}

class _PauseUpdatesCard extends ConsumerWidget {
  const _PauseUpdatesCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pauseUpdatesWUStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.pause_20_regular,
      label: t.tweaksUpdatesWUPause,
      description: t.tweaksUpdatesWUPauseDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(updatesServiceProvider).enablePauseUpdatesWU()
              : await ref.read(updatesServiceProvider).disablePauseUpdatesWU();
          ref.invalidate(pauseUpdatesWUStatusProvider);
        },
      ),
    );
  }
}

class _VisibilityCard extends ConsumerWidget {
  const _VisibilityCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(visibilityWUStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.arrow_sync_20_regular,
      label: t.tweaksUpdatesWUPage,
      description: t.tweaksUpdatesWUPageDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(updatesServiceProvider).disableVisibilityWU()
              : await ref.read(updatesServiceProvider).enableVisibilityWU();
          ref.invalidate(visibilityWUStatusProvider);
        },
      ),
    );
  }
}

class _DriversCard extends ConsumerWidget {
  const _DriversCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(driversWUStatusProvider);

    return CardHighlight(
      icon: FluentIcons.devices4,
      label: t.tweaksUpdatesWUDrivers,
      description: t.tweaksUpdatesWUDriversDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(updatesServiceProvider).enableDriversWU()
              : await ref.read(updatesServiceProvider).disableDriversWU();
          ref.invalidate(driversWUStatusProvider);
        },
      ),
    );
  }
}
