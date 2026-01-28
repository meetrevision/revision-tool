import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/card_highlight.dart';
import '../../../extensions.dart';
import '../../../i18n/generated/strings.g.dart';
import '../../../utils_gui.dart';
import 'personalization_service.dart';
import 'sections/desktop_section.dart';

class PersonalizationPage extends ConsumerWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        const DesktopSection(),
        const _InputPersonalizationCard(),
        const _CapsLockCard(),
      ].withSpacing(5),
    );
  }
}

class _InputPersonalizationCard extends ConsumerWidget {
  const _InputPersonalizationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(inputPersonalizationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.keyboard_20_regular,
      label: t.tweaksPersonalizationInkingAndTypingPersonalization,
      description:
          t.tweaksPersonalizationInkingAndTypingPersonalizationDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(personalizationServiceProvider)
                    .enableInputPersonalization()
              : await ref
                    .read(personalizationServiceProvider)
                    .disableInputPersonalization();
          ref.invalidate(inputPersonalizationStatusProvider);
        },
      ),
    );
  }
}

class _CapsLockCard extends ConsumerWidget {
  const _CapsLockCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(capsLockStatusProvider);

    return CardHighlight(
      icon: WindowsIcons.keyboard_left_dock,
      label: t.tweaksPersonalizationCapsLock,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(personalizationServiceProvider).disableCapsLock()
              : await ref.read(personalizationServiceProvider).enableCapsLock();
          ref.invalidate(capsLockStatusProvider);
        },
      ),
    );
  }
}
