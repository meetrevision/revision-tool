import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/services/usability_service.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class UsabilityPage extends StatefulWidget {
  const UsabilityPage({super.key});

  @override
  State<UsabilityPage> createState() => _UsabilityPageState();
}

class _UsabilityPageState extends State<UsabilityPage> {
  final UsabilityService _usabilityService = UsabilityService();
  late final _notifBool =
      ValueNotifier<bool>(_usabilityService.statusNotification);
  late final _lbnBool =
      ValueNotifier<bool>(_usabilityService.statusLegacyBalloon);
  late final _itpBool =
      ValueNotifier<bool>(_usabilityService.statusInputPersonalization);
  late final _dCplBool = ValueNotifier<bool>(_usabilityService.statusCapsLock);
  late final _sesBool =
      ValueNotifier<bool>(_usabilityService.statusScreenEdgeSwipe);

  @override
  void dispose() {
    _notifBool.dispose();
    _lbnBool.dispose();
    _itpBool.dispose();
    _dCplBool.dispose();
    _sesBool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(context.l10n.pageUsability),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.alert_20_regular,
          label: context.l10n.usabilityNotifLabel,
          description: context.l10n.usabilityNotifDescription,
          switchBool: _notifBool,
          function: (value) async {
            _notifBool.value = value;
            _notifBool.value
                ? _usabilityService.enableNotification()
                : _usabilityService.disableNotification();
          },
        ),
        if (_notifBool.value) ...[
          CardHighlightSwitch(
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
          ),
        ],
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
      ],
    );
  }
}
