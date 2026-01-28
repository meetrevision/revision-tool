import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../personalization_service.dart';

class DesktopSection extends StatelessWidget {
  const DesktopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CardHighlight(
      icon: msicons.FluentIcons.desktop_20_regular,
      label: t.pageTweaksDesktop,
      description: t.pageTweaksDesktopDescription,
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
    final NotificationMode status = ref.watch(notificationStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.alert_20_regular,
      title: t.tweaksPersonalizationNotifications,
      description: t.tweaksPersonalizationNotificationsDescription,
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
            case NotificationMode.offMinimal:
              await ref
                  .read(personalizationServiceProvider)
                  .disableNotification();
            case NotificationMode.offFull:
              await ref
                  .read(personalizationServiceProvider)
                  .disableNotificationAggressive();
          }

          ref.invalidate(notificationStatusProvider);
        },
        items: const [
          ComboBoxItem(value: NotificationMode.on, child: Text('On')),
          ComboBoxItem(
            value: NotificationMode.offMinimal,
            child: Text('Off (Minimal)'),
          ),
          ComboBoxItem(
            value: NotificationMode.offFull,
            child: Text('Off (Full)'),
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
    final bool status = ref.watch(legacyBalloonStatusProvider);

    return CardListTile(
      // icon: msicons.FluentIcons.balloon_20_regular,
      title: t.tweaksPersonalizationLegacyNotificationBalloons,
      description: t.tweaksPersonalizationLegacyNotificationBalloonsDescription,
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
    final bool status = ref.watch(screenEdgeSwipeStatusProvider);

    return CardListTile(
      title: t.tweaksPersonalizationScreenEdgeSwipe,
      description: t.tweaksPersonalizationScreenEdgeSwipeDescription,
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
    final bool status = ref.watch(newContextMenuStatusProvider);

    return CardListTile(
      title: t.tweaksPersonalizationNewContextMenu,
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
