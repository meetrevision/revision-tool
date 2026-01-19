import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:revitool/core/widgets/card_highlight.dart';

import 'package:revitool/extensions.dart';
import 'package:revitool/features/ms_store/widgets/msstore_dialogs.dart';
import 'package:revitool/features/tweaks/security/sections/hw_mitigation_section.dart';
import 'package:revitool/features/tweaks/security/sections/system_safeguard_section.dart';
import 'package:revitool/features/tweaks/security/security_service.dart';
import 'package:revitool/i18n/generated/strings.g.dart';
import 'package:revitool/utils_gui.dart';

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        const _DefenderCard(),
        const HardwareMitigationsSection(),
        const SystemSafeguardsSection(),
      ].withSpacing(5),
    );
  }
}

class _DefenderCard extends ConsumerWidget {
  const _DefenderCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defenderStatus = ref.watch(defenderStatusProvider);
    final protectionsStatus = ref.watch(defenderProtectionsStatusProvider);

    final Widget action = !protectionsStatus
        ? CardToggleSwitch(
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
                    content: Text(t.restartDialog),
                    actions: [
                      Button(
                        child: Text(t.okButton),
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
                        child: Text(t.okButton),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            },
          )
        : SizedBox(
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
                      content: Text(t.securityDialog),
                      actions: [
                        Button(
                          child: Text(t.okButton),
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
              child: Text(t.securityWDButton),
            ),
          );

    return CardHighlight(
      icon: msicons.FluentIcons.shield_20_regular,
      label: t.tweaksSecurityDefender,
      description: t.tweaksSecurityDefenderDescription,
      action: action,
    );
  }
}
