import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/features/tweaks/security/security_service.dart';

class HardwareMitigationsSection extends StatelessWidget {
  const HardwareMitigationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.shield_badge_20_regular,
      label: context.l10n.tweaksSecurityHWMitigation,
      description: context.l10n.tweaksSecurityHWMitigationDescription,
      initiallyExpanded: true,
      children: const [_MeltdownSpectreCard(), _DownfallCard()],
    );
  }
}

class _MeltdownSpectreCard extends ConsumerWidget {
  const _MeltdownSpectreCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(meltdownSpectreStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.shield_badge_20_regular,
      title: context.l10n.tweaksSecuritySMitigation,
      description: context.l10n.tweaksSecuritySMitigationDescription,

      trailing: CardToggleSwitch(
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

    return CardListTile(
      // icon: msicons.FluentIcons.shield_badge_20_regular,
      title: context.l10n.tweaksSecurityDownfallMitigation,
      description: context.l10n.tweaksSecurityDownfallMitigationDescription,
      trailing: CardToggleSwitch(
        enabled: WinRegistryService.isIntelCpu || kDebugMode,
        value: WinRegistryService.isAmdCpu ? false : status,
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
