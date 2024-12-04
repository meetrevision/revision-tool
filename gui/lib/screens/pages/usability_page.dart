import 'package:common/common.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/extensions.dart';

import 'package:revitool/widgets/card_highlight.dart';
import 'package:revitool/widgets/subtitle.dart';

class UsabilityPage extends StatefulWidget {
  const UsabilityPage({super.key});

  @override
  State<UsabilityPage> createState() => _UsabilityPageState();
}

class _UsabilityPageState extends State<UsabilityPage> {
  final UsabilityService _usabilityService = UsabilityService();
  late final _notifValue =
      ValueNotifier<NotificationMode>(_usabilityService.statusNotification);
  late final _lbnBool =
      ValueNotifier<bool>(_usabilityService.statusLegacyBalloon);
  late final _itpBool =
      ValueNotifier<bool>(_usabilityService.statusInputPersonalization);
  late final _dCplBool = ValueNotifier<bool>(_usabilityService.statusCapsLock);
  late final _sesBool =
      ValueNotifier<bool>(_usabilityService.statusScreenEdgeSwipe);
  late final _mrcBool =
      ValueNotifier<bool>(_usabilityService.statusNewContextMenu);

  @override
  void dispose() {
    _notifValue.dispose();
    _lbnBool.dispose();
    _itpBool.dispose();
    _dCplBool.dispose();
    _sesBool.dispose();
    _mrcBool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(context.l10n.pageUsability),
      ),
      children: [
        CardHighlight(
          icon: msicons.FluentIcons.alert_20_regular,
          label: context.l10n.usabilityNotifLabel,
          description: context.l10n.usabilityNotifDescription,
          child: ValueListenableBuilder<NotificationMode>(
            valueListenable: _notifValue,
            builder: (context, value, child) => ComboBox<NotificationMode>(
              value: value,
              onChanged: (value) async {
                _notifValue.value = value!;
                switch (value) {
                  case NotificationMode.on:
                    await _usabilityService.enableNotification();
                    if (!context.mounted) return;
                    showRestartDialog(context);
                    break;
                  case NotificationMode.offMinimal:
                    await _usabilityService.disableNotification();
                    break;
                  case NotificationMode.offFull:
                    await _usabilityService.disableNotificationAggressive();
                    break;
                }
              },
              items: const [
                ComboBoxItem(
                  value: NotificationMode.on,
                  child: Text("On"),
                ),
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
          ),
        ),
        ValueListenableBuilder<NotificationMode>(
          valueListenable: _notifValue,
          builder: (context, value, child) {
            if (value == NotificationMode.on) {
              return CardHighlightSwitch(
                icon: msicons.FluentIcons.balloon_20_regular,
                label: context.l10n.usabilityLBNLabel,
                description: context.l10n.usabilityLBNDescription,
                switchBool: _lbnBool,
                function: (value) async {
                  _lbnBool.value = value;
                  _lbnBool.value
                      ? _usabilityService.enableLegacyBalloon()
                      : _usabilityService.disableLegacyBalloon();
                },
              );
            } else {
              return const SizedBox();
            }
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.keyboard_20_regular,
          label: context.l10n.usabilityITPLabel,
          description: context.l10n.usabilityITPDescription,
          switchBool: _itpBool,
          function: (value) async {
            _itpBool.value = value;
            _itpBool.value
                ? _usabilityService.enableInputPersonalization()
                : _usabilityService.disableInputPersonalization();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.desktop_keyboard_20_regular,
          label: context.l10n.usabilityCPLLabel,
          switchBool: _dCplBool,
          function: (value) async {
            _dCplBool.value = value;
            _dCplBool.value
                ? _usabilityService.disableCapsLock()
                : _usabilityService.enableCapsLock();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.swipe_up_20_regular,
          label: context.l10n.usabilitySESLabel,
          description: context.l10n.usabilitySESDescription,
          switchBool: _sesBool,
          function: (value) async {
            _sesBool.value = value;
            _sesBool.value
                ? _usabilityService.enableScreenEdgeSwipe()
                : _usabilityService.disableScreenEdgeSwipe();
          },
        ),
        if (WinRegistryService.isW11) ...[
          const Subtitle(content: Text("Windows 11")),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.document_one_page_20_regular,
            label: context.l10n.usability11MRCLabel,
            switchBool: _mrcBool,
            function: (value) async {
              _mrcBool.value = value;
              _mrcBool.value
                  ? await _usabilityService.enableNewContextMenu()
                  : await _usabilityService.disableNewContextMenu();
            },
          ),
        ],
      ],
    );
  }
}
