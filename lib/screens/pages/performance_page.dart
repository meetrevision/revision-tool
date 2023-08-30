import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

import '../../l10n/generated/localizations.dart';
import '../../services/performance_service.dart';
import '../../utils.dart';
import '../../widgets/card_highlight.dart';
import '../../widgets/subtitle.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final PerformanceService _performanceService = PerformanceService();
  late final _sfBool =
      ValueNotifier<bool>(_performanceService.statusSuperfetch);
  late final _mcBool =
      ValueNotifier<bool>(_performanceService.statusMemoryCompression);
  late final _iTSXBool =
      ValueNotifier<bool>(_performanceService.statusIntelTSX);
  late final _foBool =
      ValueNotifier<bool>(_performanceService.statusFullscreenOptimization);

  /// Experimental
  late final _owgBool =
      ValueNotifier<bool>(_performanceService.statusWindowedOptimization);
  late final _cStatesBool =
      ValueNotifier<bool>(_performanceService.statusCStates);

  //NTFS
  late final _ntfsLTABool =
      ValueNotifier<bool>(_performanceService.statusLastTimeAccessNTFS);
  late final _ntfsEdTBool =
      ValueNotifier<bool>(_performanceService.status8dot3NamingNTFS);
  late final _ntfsMUBool =
      ValueNotifier<bool>(_performanceService.statusMemoryUsageNTFS);

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pagePerformance),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.top_speed_20_regular,
          label: ReviLocalizations.of(context).perfSuperfetchLabel,
          description: ReviLocalizations.of(context).perfSuperfetchDescription,
          switchBool: _sfBool,
          requiresRestart: true,
          function: (value) async {
            _mcBool.value = value;
            _sfBool.value
                ? _performanceService.enableSuperfetch()
                : _performanceService.disableSuperfetch();
          },
        ),
        if (_sfBool.value) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.ram_20_regular,
            label: ReviLocalizations.of(context).perfMCLabel,
            description: ReviLocalizations.of(context).perfMCDescription,
            switchBool: _mcBool,
            function: (value) {
              _mcBool.value = value;
              _mcBool.value
                  ? _performanceService.enableMemoryCompression()
                  : _performanceService.disableMemoryCompression();
            },
          ),
        ],
        CardHighlightSwitch(
          icon: msicons.FluentIcons.transmission_20_regular,
          label: ReviLocalizations.of(context).perfITSXLabel,
          description: ReviLocalizations.of(context).perfITSXDescription,
          switchBool: _iTSXBool,
          function: (value) async {
            _iTSXBool.value = value;
            _iTSXBool.value
                ? _performanceService.enableIntelTSX()
                : _performanceService.disableIntelTSX();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.desktop_20_regular,
          label: ReviLocalizations.of(context).perfFOLabel,
          description: ReviLocalizations.of(context).perfFODescription,
          switchBool: _foBool,
          function: (value) async {
            _foBool.value = value;
            _foBool.value
                ? _performanceService.enableFullscreenOptimization()
                : _performanceService.disableFullscreenOptimization();
          },
        ),
        if (w11) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.desktop_mac_20_regular,
            label: ReviLocalizations.of(context).perfOWGLabel,
            description: ReviLocalizations.of(context).perfOWGDescription,
            switchBool: _owgBool,
            function: (value) {
              _owgBool.value = value;

              _owgBool.value
                  ? _performanceService.enableWindowedOptimization()
                  : _performanceService.disableWindowedOptimization();
            },
          ),
        ],
        if (expBool.value) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.sleep_20_regular,
            label: ReviLocalizations.of(context).perfCStatesLabel,
            description: ReviLocalizations.of(context).perfCStatesDescription,
            switchBool: _cStatesBool,
            function: (value) async {
              _cStatesBool.value = value;
              _cStatesBool.value
                  ? _performanceService.disableCStates()
                  : _performanceService.enableCStates();
            },
          ),
          Subtitle(content: Text(ReviLocalizations.of(context).perfSectionFS)),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
            label: ReviLocalizations.of(context).perfLTALabel,
            description: ReviLocalizations.of(context).perfLTADescription,
            switchBool: _ntfsLTABool,
            function: (value) async {
              _ntfsLTABool.value = value;
              print(_ntfsLTABool.value);
              _ntfsLTABool.value
                  ? _performanceService.disableLastTimeAccessNTFS()
                  : _performanceService.enableLastTimeAccessNTFS();
            },
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.hard_drive_20_regular,
            label: ReviLocalizations.of(context).perfEdTLabel,
            description: ReviLocalizations.of(context).perfEdTDescription,
            switchBool: _ntfsEdTBool,
            function: (value) async {
              _ntfsEdTBool.value = value;

              _ntfsEdTBool.value
                  ? _performanceService.disable8dot3NamingNTFS()
                  : _performanceService.enable8dot3NamingNTFS();
            },
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.memory_16_regular,
            label: ReviLocalizations.of(context).perfMULabel,
            switchBool: _ntfsMUBool,
            function: (value) async {
              _ntfsMUBool.value = value;
              _ntfsMUBool.value
                  ? _performanceService.enableMemoryUsageNTFS()
                  : _performanceService.disableMemoryUsageNTFS();
            },
            codeSnippet: ReviLocalizations.of(context).perfMUDescription,
          ),
        ]
      ],
    );
  }
}
