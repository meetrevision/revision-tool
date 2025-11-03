import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/security/security_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:revitool/core/ms_store/widgets/msstore_dialogs.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/shared/win_registry_service.dart';

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
        const _DefenderCard(),
        const _UACCard(),
        const _MeltdownSpectreCard(),
        if (WinRegistryService.isIntelCpu || kDebugMode) const _DownfallCard(),
        const _CertificatesCard(),
      ],
    );
  }
}

class _DefenderCard extends ConsumerWidget {
  const _DefenderCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defenderStatus = ref.watch(defenderStatusProvider);
    final protectionsStatus = ref.watch(defenderProtectionsStatusProvider);

    if (!protectionsStatus) {
      return CardHighlight(
        icon: msicons.FluentIcons.shield_20_regular,
        label: context.l10n.securityWDLabel,
        description: context.l10n.securityWDDescription,
        action: CardToggleSwitch(
          value: defenderStatus,
          onChanged: (value) async {
            showLoadingDialog(context, '');
            try {
              if (value) {
                await ref.read(securityServiceProvider).enableDefender();
              } else {
                await ref.read(securityServiceProvider).disableDefender();
              }
              if (!context.mounted) return;
              context.pop();

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
        ),
      );
    } else {
      return CardHighlight(
        icon: msicons.FluentIcons.shield_20_regular,
        label: context.l10n.securityWDLabel,
        description: context.l10n.securityWDDescription,
        action: SizedBox(
          width: 150,
          child: Button(
            onPressed: () async {
              Future.delayed(const Duration(seconds: 1), () async {
                await ref
                    .read(securityServiceProvider)
                    .openDefenderThreatSettings();
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
                          ref.invalidate(defenderProtectionsStatusProvider);
                          final updatedStatus = ref.read(
                            defenderProtectionsStatusProvider,
                          );

                          if (updatedStatus) {
                            await ref
                                .read(securityServiceProvider)
                                .openDefenderThreatSettings();
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
  const _UACCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(uacStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.person_lock_20_regular,
      label: context.l10n.securityUACLabel,
      description: context.l10n.securityUACDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(securityServiceProvider).enableUAC()
              : await ref.read(securityServiceProvider).disableUAC();
          ref.invalidate(uacStatusProvider);
        },
      ),
    );
  }
}

class _MeltdownSpectreCard extends ConsumerWidget {
  const _MeltdownSpectreCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(meltdownSpectreStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.shield_badge_20_regular,
      label: context.l10n.securitySMLabel,
      description: context.l10n.securitySMDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(securityServiceProvider)
                    .enableMitigation(Mitigation.meltdownSpectre)
              : await ref
                    .read(securityServiceProvider)
                    .disableMitigation(Mitigation.meltdownSpectre);
          ref.invalidate(meltdownSpectreStatusProvider);
        },
      ),
    );
  }
}

class _DownfallCard extends ConsumerWidget {
  const _DownfallCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(downfallStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.shield_badge_20_regular,
      label: context.l10n.securityDownfallMitLabel,
      description: context.l10n.securityDownfallMitDescription,
      codeSnippet: context.l10n.securityDownfallMitCodeSnippet,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref
                    .read(securityServiceProvider)
                    .enableMitigation(Mitigation.downfall)
              : await ref
                    .read(securityServiceProvider)
                    .disableMitigation(Mitigation.downfall);
          ref.invalidate(downfallStatusProvider);
        },
      ),
    );
  }
}

class _CertificatesCard extends ConsumerWidget {
  const _CertificatesCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardHighlight(
      icon: msicons.FluentIcons.certificate_20_regular,
      label: context.l10n.miscCertsLabel,
      description: context.l10n.miscCertsDescription,
      action: SizedBox(
        width: 150,
        child: Button(
          onPressed: () async {
            showLoadingDialog(context, "Updating Certificates");
            await ref.read(securityServiceProvider).updateCertificates();

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
