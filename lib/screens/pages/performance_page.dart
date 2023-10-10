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
  late final _owgBool =
      ValueNotifier<bool>(_performanceService.statusWindowedOptimization);
  late final _baBool =
      ValueNotifier<bool>(_performanceService.statusBackgroundApps);

  /// Experimental

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
  void dispose() {
    _sfBool.dispose();
    _mcBool.dispose();
    _iTSXBool.dispose();
    _foBool.dispose();
    _owgBool.dispose();
    _baBool.dispose();
    _cStatesBool.dispose();
    _ntfsLTABool.dispose();
    _ntfsEdTBool.dispose();
    _ntfsMUBool.dispose();
    super.dispose();
  }

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
            _sfBool.value = value;
            value
                ? await _performanceService.enableSuperfetch()
                : await _performanceService.disableSuperfetch();
          },
        ),
        ValueListenableBuilder(
          valueListenable: _sfBool,
          builder: (context, value, child) {
            if (_sfBool.value) {
              return CardHighlightSwitch(
                icon: msicons.FluentIcons.ram_20_regular,
                label: ReviLocalizations.of(context).perfMCLabel,
                description: ReviLocalizations.of(context).perfMCDescription,
                switchBool: _mcBool,
                function: (value) async {
                  _mcBool.value = value;
                  value
                      ? await _performanceService.enableMemoryCompression()
                      : await _performanceService.disableMemoryCompression();
                },
              );
            }
            return const SizedBox();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.transmission_20_regular,
          label: ReviLocalizations.of(context).perfITSXLabel,
          description: ReviLocalizations.of(context).perfITSXDescription,
          switchBool: _iTSXBool,
          function: (value) {
            _iTSXBool.value = value;
            value
                ? _performanceService.enableIntelTSX()
                : _performanceService.disableIntelTSX();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.desktop_20_regular,
          label: ReviLocalizations.of(context).perfFOLabel,
          description: ReviLocalizations.of(context).perfFODescription,
          switchBool: _foBool,
          function: (value) {
            _foBool.value = value;
            value
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
              value
                  ? _performanceService.enableWindowedOptimization()
                  : _performanceService.disableWindowedOptimization();
            },
          ),
        ],
        CardHighlightSwitch(
          icon: msicons.FluentIcons.bezier_curve_square_20_regular,
          label: ReviLocalizations.of(context).perfBALabel,
          description: ReviLocalizations.of(context).perfBADescription,
          switchBool: _baBool,
          function: (value) {
            _baBool.value = value;
            value
                ? _performanceService.enableBackgroundApps()
                : _performanceService.disableBackgroundApps();
          },
        ),
        if (expBool.value) ...[
         CardHighlightSwitch(
            icon: msicons.FluentIcons.sleep_20_regular,
            label: ReviLocalizations.of(context).perfCStatesLabel,
            description: ReviLocalizations.of(context).perfCStatesDescription,
            switchBool: _cStatesBool,
            function: (value) {
              _cStatesBool.value = value;
              value
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
              value
                  ? await _performanceService.disableLastTimeAccessNTFS()
                  : await _performanceService.enableLastTimeAccessNTFS();
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
                  ? await _performanceService.disable8dot3NamingNTFS()
                  : await _performanceService.enable8dot3NamingNTFS();
            },
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.memory_16_regular,
            label: ReviLocalizations.of(context).perfMULabel,
            switchBool: _ntfsMUBool,
            function: (value) async {
              _ntfsMUBool.value = value;
              _ntfsMUBool.value
                  ? await _performanceService.enableMemoryUsageNTFS()
                  : await _performanceService.disableMemoryUsageNTFS();
            },
            codeSnippet: ReviLocalizations.of(context).perfMUDescription,
          ),
        ]
      ],
    );
  }
}
