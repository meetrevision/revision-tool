import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/win_registry_service.dart';
import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../security_service.dart';

class HardwareMitigationsSection extends StatelessWidget {
  const HardwareMitigationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.shield_badge_20_regular,
      label: t.tweaksSecurityHWMitigation,
      description: t.tweaksSecurityHWMitigationDescription,
      initiallyExpanded: true,
      children: const [_MeltdownSpectreCard(), _DownfallCard()],
    );
  }
}

class _MeltdownSpectreCard extends ConsumerWidget {
  const _MeltdownSpectreCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(meltdownSpectreStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.shield_badge_20_regular,
      title: t.tweaksSecuritySMitigation,
      description: t.tweaksSecuritySMitigationDescription,

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
    final bool status = ref.watch(downfallStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.shield_badge_20_regular,
      title: t.tweaksSecurityDownfallMitigation,
      description: t.tweaksSecurityDownfallMitigationDescription,
      trailing: CardToggleSwitch(
        enabled: WinRegistryService.isIntelCpu || kDebugMode,
        value: !WinRegistryService.isAmdCpu && status,
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
