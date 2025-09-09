import 'package:fluent_ui/fluent_ui.dart';
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
        _NotificationCard(),
        _LegacyBalloonCard(),
        _InputPersonalizationCard(),
        _CapsLockCard(),
        _ScreenEdgeSwipeCard(),
        if (WinRegistryService.isW11) ...[
          const Subtitle(content: Text("Windows 11")),
          _NewContextMenuCard(),
        ],
      ],
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.alert_20_regular,
      label: context.l10n.usabilityNotifLabel,
      description: context.l10n.usabilityNotifDescription,
      child: ComboBox<NotificationMode>(
        value: status,
        onChanged: (value) async {
          if (value == null) return;
          
          switch (value) {
            case NotificationMode.on:
              await UsabilityService.enableNotification();
              if (!context.mounted) return;
              showRestartDialog(context);
              break;
            case NotificationMode.offMinimal:
              await UsabilityService.disableNotification();
              break;
            case NotificationMode.offFull:
              await UsabilityService.disableNotificationAggressive();
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationStatus = ref.watch(notificationStatusProvider);
    final status = ref.watch(legacyBalloonStatusProvider);

    if (notificationStatus != NotificationMode.on) {
      return const SizedBox();
    }

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.balloon_20_regular,
      label: context.l10n.usabilityLBNLabel,
      description: context.l10n.usabilityLBNDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? UsabilityService.enableLegacyBalloon()
            : UsabilityService.disableLegacyBalloon();
        ref.invalidate(legacyBalloonStatusProvider);
      },
    );
  }
}

class _InputPersonalizationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(inputPersonalizationStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.keyboard_20_regular,
      label: context.l10n.usabilityITPLabel,
      description: context.l10n.usabilityITPDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? UsabilityService.enableInputPersonalization()
            : UsabilityService.disableInputPersonalization();
        ref.invalidate(inputPersonalizationStatusProvider);
      },
    );
  }
}

class _CapsLockCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(capsLockStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.desktop_keyboard_20_regular,
      label: context.l10n.usabilityCPLLabel,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? UsabilityService.disableCapsLock()
            : UsabilityService.enableCapsLock();
        ref.invalidate(capsLockStatusProvider);
      },
    );
  }
}

class _ScreenEdgeSwipeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(screenEdgeSwipeStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.swipe_up_20_regular,
      label: context.l10n.usabilitySESLabel,
      description: context.l10n.usabilitySESDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? UsabilityService.enableScreenEdgeSwipe()
            : UsabilityService.disableScreenEdgeSwipe();
        ref.invalidate(screenEdgeSwipeStatusProvider);
      },
    );
  }
}

class _NewContextMenuCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(newContextMenuStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.document_one_page_20_regular,
      label: context.l10n.usability11MRCLabel,
      switchBool: ValueNotifier(status),
      function: (value) async {
        value
            ? await UsabilityService.enableNewContextMenu()
            : await UsabilityService.disableNewContextMenu();
        ref.invalidate(newContextMenuStatusProvider);
      },
    );
  }
}
