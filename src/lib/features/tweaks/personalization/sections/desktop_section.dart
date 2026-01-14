import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/extensions.dart';
import 'package:revitool/features/tweaks/personalization/personalization_service.dart';

import 'package:revitool/core/widgets/card_highlight.dart';

class DesktopSection extends StatelessWidget {
  const DesktopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.desktop_20_regular,
      label: context.l10n.pageTweaksDesktop,
      description: context.l10n.pageTweaksDesktopDescription,
      children: const [
        _NotificationCard(),
        _LegacyBalloonCard(),
        _ScreenEdgeSwipeCard(),
        _NewContextMenuCard(),
      ],
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.alert_20_regular,
      title: context.l10n.tweaksPersonalizationNotifications,
      description: context.l10n.tweaksPersonalizationNotificationsDescription,
      trailing: ComboBox<NotificationMode>(
        value: status,
        onChanged: (value) async {
          if (value == null) return;

          switch (value) {
            case NotificationMode.on:
              await ref
                  .read(personalizationServiceProvider)
                  .enableNotification();
              if (!context.mounted) return;
              showRestartDialog(context);
              break;
            case NotificationMode.offMinimal:
              await ref
                  .read(personalizationServiceProvider)
                  .disableNotification();
              break;
            case NotificationMode.offFull:
              await ref
                  .read(personalizationServiceProvider)
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
    final status = ref.watch(legacyBalloonStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.balloon_20_regular,
      title: context.l10n.tweaksPersonalizationLegacyNotificationBalloons,
      description: context
          .l10n
          .tweaksPersonalizationLegacyNotificationBalloonsDescription,
      trailing: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(personalizationServiceProvider)
                    .enableLegacyBalloon()
              : await ref
                    .read(personalizationServiceProvider)
                    .disableLegacyBalloon();
          ref.invalidate(legacyBalloonStatusProvider);
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

    return CardListTile(
      title: context.l10n.tweaksPersonalizationScreenEdgeSwipe,
      description: context.l10n.tweaksPersonalizationScreenEdgeSwipeDescription,
      trailing: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(personalizationServiceProvider)
                    .enableScreenEdgeSwipe()
              : await ref
                    .read(personalizationServiceProvider)
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

    return CardListTile(
      title: context.l10n.tweaksPersonalizationNewContextMenu,
      trailing: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref
                    .read(personalizationServiceProvider)
                    .enableNewContextMenu()
              : await ref
                    .read(personalizationServiceProvider)
                    .disableNewContextMenu();
          ref.invalidate(newContextMenuStatusProvider);
        },
      ),
    );
  }
}
