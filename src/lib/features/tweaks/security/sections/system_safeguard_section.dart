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
      children: const [_UACCard()],
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
