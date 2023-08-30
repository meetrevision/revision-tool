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
  late final ValueNotifier<bool> _hibBool =
      ValueNotifier<bool>(_miscellaneousService.statusHibernation);
  late final ValueNotifier<int> _hibMode =
      ValueNotifier<int>(_miscellaneousService.statusHibernationMode!);
  late final ValueNotifier<bool> _fsbBool =
      ValueNotifier<bool>(_miscellaneousService.statusFastStartup);
  late final ValueNotifier<bool> _tmmBool =
      ValueNotifier<bool>(_miscellaneousService.statusTMMonitoring);
  late final ValueNotifier<bool> _mpoBool =
      ValueNotifier<bool>(_miscellaneousService.statusMPO);
  late final ValueNotifier<bool> _bhrBool =
      ValueNotifier<bool>(_miscellaneousService.statusBatteryHealthReporting);

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
            _hibBool.value = value;
            _hibBool.value
                ? _miscellaneousService.enableHibernation()
                : _miscellaneousService.disableHibernation();
          },
        ),
        if (_hibBool.value) ...[
          CardHighlight(
            icon: msicons.FluentIcons.document_save_20_regular,
            label: ReviLocalizations.of(context).miscHibernateModeLabel,
            description:
                ReviLocalizations.of(context).miscHibernateModeDescription,
            child: ComboBox(
              value: _hibMode.value,
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
                _hibMode.value = value!;
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
              _fsbBool.value = value;
              _fsbBool.value
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
            _tmmBool.value = value;
            _tmmBool.value
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
            _mpoBool.value = value;
            _mpoBool.value
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
            _bhrBool.value = value;
            _bhrBool.value
                ? _miscellaneousService.enableBatteryHealthReporting()
                : _miscellaneousService.disableBatteryHealthReporting();
          },
        ),
      ],
    );
  }
}
