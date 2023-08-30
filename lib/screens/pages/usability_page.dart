import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageUsability),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.alert_20_regular,
          label: ReviLocalizations.of(context).usabilityNotifLabel,
          description: ReviLocalizations.of(context).usabilityNotifDescription,
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
            label: ReviLocalizations.of(context).usabilityLBNLabel,
            description: ReviLocalizations.of(context).usabilityLBNDescription,
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
          label: ReviLocalizations.of(context).usabilityITPLabel,
          description: ReviLocalizations.of(context).usabilityITPDescription,
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
          label: ReviLocalizations.of(context).usabilityCPLLabel,
          switchBool: _dCplBool,
          function: (value) async {
            _dCplBool.value = value;
            _dCplBool.value
                ? _usabilityService.disableCapsLock()
                : _usabilityService.enableCapsLock();
          },
        ),
      ],
    );
  }
}
