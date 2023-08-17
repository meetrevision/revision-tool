import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/services/miscellaneous_service.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class MiscellaneousPage extends StatefulWidget {
  const MiscellaneousPage({super.key});

  @override
  State<MiscellaneousPage> createState() => _MiscellaneousPageState();
}

class _MiscellaneousPageState extends State<MiscellaneousPage> {
  final MiscellaneousService _miscellaneousService = MiscellaneousService();
  late bool _hibBool = _miscellaneousService.statusHibernation;
  late int? _hibMode = _miscellaneousService.statusHibernationMode;
  late bool _fsbBool = _miscellaneousService.statusFastStartup;
  late bool _tmmBool = _miscellaneousService.statusTMMonitoring;
  late bool _mpoBool = _miscellaneousService.statusMPO;
  late bool _bhrBool = _miscellaneousService.statusBatteryHealthReporting;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageMiscellaneous),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.sleep_20_regular,
          label: ReviLocalizations.of(context).miscHibernateLabel,
          description: ReviLocalizations.of(context).miscHibernateDescription,
          switchBool: _hibBool,
          function: (value) async {
            setState(() => _hibBool = value);
            _hibBool
                ? _miscellaneousService.enableHibernation()
                : _miscellaneousService.disableHibernation();
          },
        ),
        if (_hibBool) ...[
          CardHighlight(
            icon: msicons.FluentIcons.document_save_20_regular,
            label: ReviLocalizations.of(context).miscHibernateModeLabel,
            description:
                ReviLocalizations.of(context).miscHibernateModeDescription,
            child: ComboBox(
              value: _hibMode,
              onChanged: (value) {
                switch (value) {
                  case 1:
                    _miscellaneousService.setHibernateModeFull();
                    break;
                  case 2:
                    _miscellaneousService.setHibernateModeReduced();
                    break;
                  default:
                }
                setState(() => _hibMode = value);
              },
              items: const [
                ComboBoxItem(
                  value: 1,
                  child: Text("Full"),
                ),
                ComboBoxItem(
                  value: 2,
                  child: Text("Reduced"),
                ),
              ],
            ),
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.weather_hail_night_20_regular,
            label: ReviLocalizations.of(context).miscFastStartupLabel,
            description:
                ReviLocalizations.of(context).miscFastStartupDescription,
            switchBool: _fsbBool,
            function: (value) async {
              setState(() => _fsbBool = value);
              _fsbBool
                  ? _miscellaneousService.enableFastStartup()
                  : _miscellaneousService.disableFastStartup();
            },
          ),
        ],
        CardHighlightSwitch(
          icon: FluentIcons.task_manager,
          label: ReviLocalizations.of(context).miscTMMonitoringLabel,
          description:
              ReviLocalizations.of(context).miscTMMonitoringDescription,
          switchBool: _tmmBool,
          requiresRestart: true,
          function: (value) async {
            setState(() => _tmmBool = value);
            _tmmBool
                ? _miscellaneousService.enableTMMonitoring()
                : _miscellaneousService.disableTMMonitoring();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.window_settings_20_regular,
          label: ReviLocalizations.of(context).miscMpoLabel,
          codeSnippet: ReviLocalizations.of(context).miscMpoCodeSnippet,
          switchBool: _mpoBool,
          function: (value) async {
            setState(() => _mpoBool = value);
            _mpoBool
                ? _miscellaneousService.enableMPO()
                : _miscellaneousService.disableMPO();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.battery_checkmark_20_regular,
          label: ReviLocalizations.of(context).miscBHRLabel,
          description: ReviLocalizations.of(context).miscBHRDescription,
          switchBool: _bhrBool,
          function: (value) async {
            setState(() => _bhrBool = value);
            _bhrBool
                ? _miscellaneousService.enableBatteryHealthReporting()
                : _miscellaneousService.disableBatteryHealthReporting();
          },
        ),
      ],
    );
  }
}
