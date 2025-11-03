import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/core/usability/usability_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:revitool/shared/widgets/subtitle.dart';

class UsabilityPage extends ConsumerWidget {
  const UsabilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageUsability)),
      children: [
        const _NotificationCard(),
        const _LegacyBalloonCard(),
        const _InputPersonalizationCard(),
        const _CapsLockCard(),
        const _ScreenEdgeSwipeCard(),
        if (WinRegistryService.isW11 || kDebugMode) ...[
          const Subtitle(content: Text("Windows 11")),
          const _NewContextMenuCard(),
        ],
      ],
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.alert_20_regular,
      label: context.l10n.usabilityNotifLabel,
      description: context.l10n.usabilityNotifDescription,
      action: ComboBox<NotificationMode>(
        value: status,
        onChanged: (value) async {
          if (value == null) return;

          switch (value) {
            case NotificationMode.on:
              await ref.read(usabilityServiceProvider).enableNotification();
              if (!context.mounted) return;
              showRestartDialog(context);
              break;
            case NotificationMode.offMinimal:
              await ref.read(usabilityServiceProvider).disableNotification();
              break;
            case NotificationMode.offFull:
              await ref
                  .read(usabilityServiceProvider)
                  .disableNotificationAggressive();
              break;
          }

          ref.invalidate(notificationStatusProvider);
        },
        items: const [
          ComboBoxItem(value: NotificationMode.on, child: Text("On")),
          ComboBoxItem(
            value: NotificationMode.offMinimal,
            child: Text("Off (Minimal)"),
          ),
          ComboBoxItem(
            value: NotificationMode.offFull,
            child: Text("Off (Full)"),
          ),
        ],
      ),
    );
  }
}

class _LegacyBalloonCard extends ConsumerWidget {
  const _LegacyBalloonCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationStatus = ref.watch(notificationStatusProvider);
    final status = ref.watch(legacyBalloonStatusProvider);

    if (notificationStatus != NotificationMode.on) {
      return const SizedBox();
    }

    return CardHighlight(
      icon: msicons.FluentIcons.balloon_20_regular,
      label: context.l10n.usabilityLBNLabel,
      description: context.l10n.usabilityLBNDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(usabilityServiceProvider).enableLegacyBalloon()
              : await ref.read(usabilityServiceProvider).disableLegacyBalloon();
          ref.invalidate(legacyBalloonStatusProvider);
        },
      ),
    );
  }
}

class _InputPersonalizationCard extends ConsumerWidget {
  const _InputPersonalizationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(inputPersonalizationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.keyboard_20_regular,
      label: context.l10n.usabilityITPLabel,
      description: context.l10n.usabilityITPDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(usabilityServiceProvider)
                    .enableInputPersonalization()
              : await ref
                    .read(usabilityServiceProvider)
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
    final status = ref.watch(capsLockStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.desktop_keyboard_20_regular,
      label: context.l10n.usabilityCPLLabel,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(usabilityServiceProvider).disableCapsLock()
              : await ref.read(usabilityServiceProvider).enableCapsLock();
          ref.invalidate(capsLockStatusProvider);
        },
      ),
    );
  }
}

class _ScreenEdgeSwipeCard extends ConsumerWidget {
  const _ScreenEdgeSwipeCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(screenEdgeSwipeStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.swipe_up_20_regular,
      label: context.l10n.usabilitySESLabel,
      description: context.l10n.usabilitySESDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(usabilityServiceProvider).enableScreenEdgeSwipe()
              : await ref
                    .read(usabilityServiceProvider)
                    .disableScreenEdgeSwipe();
          ref.invalidate(screenEdgeSwipeStatusProvider);
        },
      ),
    );
  }
}

class _NewContextMenuCard extends ConsumerWidget {
  const _NewContextMenuCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(newContextMenuStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.document_one_page_20_regular,
      label: context.l10n.usability11MRCLabel,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(usabilityServiceProvider).enableNewContextMenu()
              : await ref
                    .read(usabilityServiceProvider)
                    .disableNewContextMenu();
          ref.invalidate(newContextMenuStatusProvider);
        },
      ),
    );
  }
}
