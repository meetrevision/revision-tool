import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../security_service.dart';

class SystemSafeguardsSection extends StatelessWidget {
  const SystemSafeguardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.shield_keyhole_20_regular,
      label: t.tweaksSecuritySystemSafeguards,
      description: t.tweaksSecuritySystemSafeguardsDescription,
      initiallyExpanded: true,
      children: const [_UACCard(), _VbsCard(), _MemoryIntegrityCard()],
    );
  }
}

class _UACCard extends ConsumerWidget {
  const _UACCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(uacStatusProvider);

    return CardListTile(
      leading: const Icon(msicons.FluentIcons.person_lock_20_regular, size: 24),
      title: t.tweaksSecurityUAC,
      description: t.tweaksSecurityUACDescription,
      trailing: CardToggleSwitch(
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

class _VbsCard extends ConsumerWidget {
  const _VbsCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(vbsStatusProvider);

    return CardListTile(
      leading: const Icon(
        msicons.FluentIcons.window_shield_20_regular,
        size: 24,
      ),
      title: t.tweaksSecurityVBS,
      description: t.tweaksSecurityVBSDescription,
      trailing: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(securityServiceProvider).enableVbs()
              : await ref.read(securityServiceProvider).disableVbs();
          ref.invalidate(vbsStatusProvider);
          ref.invalidate(memoryIntegrityStatusProvider);
        },
      ),
    );
  }
}

class _MemoryIntegrityCard extends ConsumerWidget {
  const _MemoryIntegrityCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(memoryIntegrityStatusProvider);

    return CardListTile(
      leading: const Icon(msicons.FluentIcons.ram_20_regular, size: 24),
      title: t.tweaksSecurityMemoryIntegrity,
      description: t.tweaksSecurityMemoryIntegrityDescription,
      trailing: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(securityServiceProvider).enableMemoryIntegrity()
              : await ref
                    .read(securityServiceProvider)
                    .disableMemoryIntegrity();
          ref.invalidate(memoryIntegrityStatusProvider);
        },
      ),
    );
  }
}
