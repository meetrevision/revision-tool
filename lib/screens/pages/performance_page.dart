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
  late bool _sfBool = _performanceService.statusSuperfetch;
  late bool _mcBool = _performanceService.statusMemoryCompression;
  late bool _iTSXBool = _performanceService.statusIntelTSX;
  late bool _foBool = _performanceService.statusFullscreenOptimization;

  /// Experimental
  late bool _owgBool = _performanceService.statusWindowedOptimization;
  late bool _cStatesBool = _performanceService.statusCStates;

  //NTFS
  late bool _ntfsLTABool = _performanceService.statusLastTimeAccessNTFS;
  late bool _ntfsEdTBool = _performanceService.status8dot3NamingNTFS;
  late bool _ntfsMUBool = _performanceService.statusMemoryUsageNTFS;

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
            setState(() => _sfBool = value);
            _sfBool
                ? _performanceService.enableSuperfetch()
                : _performanceService.disableSuperfetch();
          },
        ),
        if (_sfBool) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.ram_20_regular,
            label: ReviLocalizations.of(context).perfMCLabel,
            description: ReviLocalizations.of(context).perfMCDescription,
            switchBool: _mcBool,
            function: (value) {
              setState(() => _mcBool = value);
              _mcBool
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
            setState(() => _iTSXBool = value);
            _iTSXBool
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
            setState(() => _foBool = value);
            _foBool
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
              setState(() => _owgBool = value);

              _owgBool
                  ? _performanceService.enableWindowedOptimization()
                  : _performanceService.disableWindowedOptimization();
            },
          ),
        ],
        if (expBool) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.sleep_20_regular,
            label: ReviLocalizations.of(context).perfCStatesLabel,
            description: ReviLocalizations.of(context).perfCStatesDescription,
            switchBool: _cStatesBool,
            function: (value) async {
              setState(() => _cStatesBool = value);
              _cStatesBool
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
              setState(() => _ntfsLTABool = value);
              _ntfsLTABool
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
              setState(() => _ntfsEdTBool = value);

              _ntfsEdTBool
                  ? _performanceService.disable8dot3NamingNTFS()
                  : _performanceService.enable8dot3NamingNTFS();
            },
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.memory_16_regular,
            label: ReviLocalizations.of(context).perfMULabel,
            switchBool: _ntfsMUBool,
            function: (value) async {
              setState(() => _ntfsMUBool = value);
              _ntfsMUBool
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
