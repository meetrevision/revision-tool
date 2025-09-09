import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/security/security_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:revitool/core/ms_store/widgets/msstore_dialogs.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(context.l10n.pageSecurity),
        ),
      ),
      children: [
        _DefenderCard(),
        _UACCard(),
        _MeltdownSpectreCard(),
        _DownfallCard(),
        _CertificatesCard(),
      ],
    );
  }
}

class _DefenderCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defenderStatus = ref.watch(defenderStatusProvider);
    final protectionsStatus = ref.watch(defenderProtectionsStatusProvider);

    if (!protectionsStatus) {
      return CardHighlightSwitch(
        icon: msicons.FluentIcons.shield_20_regular,
        label: context.l10n.securityWDLabel,
        description: context.l10n.securityWDDescription,
        switchBool: ValueNotifier(defenderStatus),
        function: (value) async {
          showLoadingDialog(context, '');
          try {
            if (value) {
              await SecurityService.enableDefender();
            } else {
              await SecurityService.disableDefender();
            }
            if (!context.mounted) return;
            context.pop();

            // Invalidate both providers since they're related
            ref.invalidate(defenderStatusProvider);
            ref.invalidate(defenderProtectionsStatusProvider);

            await showDialog(
              context: context,
              builder: (context) => ContentDialog(
                content: Text(context.l10n.restartDialog),
                actions: [
                  Button(
                    child: Text(context.l10n.okButton),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            context.pop();
            await showDialog(
              context: context,
              builder: (context) => ContentDialog(
                content: Text(e.toString()),
                actions: [
                  Button(
                    child: Text(context.l10n.okButton),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      return CardHighlight(
        icon: msicons.FluentIcons.shield_20_regular,
        label: context.l10n.securityWDLabel,
        description: context.l10n.securityWDDescription,
        child: SizedBox(
          width: 150,
          child: Button(
            onPressed: () async {
              Future.delayed(const Duration(seconds: 1), () async {
                await SecurityService.openDefenderThreatSettings();
              });

              showDialog(
                dismissWithEsc: false,
                context: context,
                builder: (context) {
                  return ContentDialog(
                    content: Text(context.l10n.securityDialog),
                    actions: [
                      Button(
                        child: Text(context.l10n.okButton),
                        onPressed: () async {
                          // Update status and check if protections are still enabled
                          ref.invalidate(defenderProtectionsStatusProvider);
                          final updatedStatus = ref.read(
                            defenderProtectionsStatusProvider,
                          );

                          if (updatedStatus) {
                            await SecurityService.openDefenderThreatSettings();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(context.l10n.securityWDButton),
          ),
        ),
      );
    }
  }
}

class _UACCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(uacStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.person_lock_20_regular,
      label: context.l10n.securityUACLabel,
      description: context.l10n.securityUACDescription,
      switchBool: ValueNotifier(status),
      requiresRestart: true,
      function: (value) {
        value ? SecurityService.enableUAC() : SecurityService.disableUAC();
        ref.invalidate(uacStatusProvider);
      },
    );
  }
}

class _MeltdownSpectreCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(meltdownSpectreStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.shield_badge_20_regular,
      label: context.l10n.securitySMLabel,
      description: context.l10n.securitySMDescription,
      switchBool: ValueNotifier(status),
      requiresRestart: true,
      function: (value) {
        value
            ? SecurityService.enableMitigation(Mitigation.meltdownSpectre)
            : SecurityService.disableMitigation(Mitigation.meltdownSpectre);
        ref.invalidate(meltdownSpectreStatusProvider);
      },
    );
  }
}

class _DownfallCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(downfallStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.shield_badge_20_regular,
      label: context.l10n.securityDownfallMitLabel,
      description: context.l10n.securityDownfallMitDescription,
      codeSnippet: context.l10n.securityDownfallMitCodeSnippet,
      switchBool: ValueNotifier(status),
      requiresRestart: true,
      function: (value) {
        value
            ? SecurityService.enableMitigation(Mitigation.downfall)
            : SecurityService.disableMitigation(Mitigation.downfall);
        ref.invalidate(downfallStatusProvider);
      },
    );
  }
}

class _CertificatesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.certificate_20_regular,
      label: context.l10n.miscCertsLabel,
      description: context.l10n.miscCertsDescription,
      child: SizedBox(
        width: 150,
        child: Button(
          onPressed: () async {
            showLoadingDialog(context, "Updating Certificates");
            await SecurityService.updateCertificates();

            if (!context.mounted) return;
            context.pop();
            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                content: Text(context.l10n.miscCertsDialog),
                actions: [
                  Button(
                    child: Text(context.l10n.okButton),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          },
          child: Text(context.l10n.updateButton),
        ),
      ),
    );
  }
}
