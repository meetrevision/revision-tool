import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/core/performance/performance_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:revitool/shared/widgets/subtitle.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final PerformanceService _performanceService = PerformanceService();
  late final _sfBool = ValueNotifier<bool>(
    _performanceService.statusSuperfetch,
  );
  late final _mcBool =
      _performanceService.statusSuperfetch
          ? ValueNotifier<bool>(_performanceService.statusMemoryCompression)
          : ValueNotifier<bool>(false);
  late final _iTSXBool = ValueNotifier<bool>(
    _performanceService.statusIntelTSX,
  );
  late final _foBool = ValueNotifier<bool>(
    _performanceService.statusFullscreenOptimization,
  );
  late final _owgBool = ValueNotifier<bool>(
    _performanceService.statusWindowedOptimization,
  );
  late final _baBool = ValueNotifier<bool>(
    _performanceService.statusBackgroundApps,
  );
  late final statusServicesGrouping = ValueNotifier<ServiceGrouping>(
    _performanceService.statusServicesGrouping,
  );

  /// Experimental

  late final _cStatesBool = ValueNotifier<bool>(
    _performanceService.statusCStates,
  );

  //NTFS
  late final _ntfsLTABool = ValueNotifier<bool>(
    _performanceService.statusLastTimeAccessNTFS,
  );
  late final _ntfsEdTBool = ValueNotifier<bool>(
    _performanceService.status8dot3NamingNTFS,
  );
  late final _ntfsMUBool = ValueNotifier<bool>(
    _performanceService.statusMemoryUsageNTFS,
  );

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
      padding: kScaffoldPagePadding,

      header: PageHeader(title: Text(context.l10n.pagePerformance)),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.top_speed_20_regular,
          label: context.l10n.perfSuperfetchLabel,
          description: context.l10n.perfSuperfetchDescription,
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
                label: context.l10n.perfMCLabel,
                description: context.l10n.perfMCDescription,
                switchBool: _mcBool,
                requiresRestart: true,
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
          label: context.l10n.perfITSXLabel,
          description: context.l10n.perfITSXDescription,
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
          label: context.l10n.perfFOLabel,
          description: context.l10n.perfFODescription,
          switchBool: _foBool,
          function: (value) {
            _foBool.value = value;
            value
                ? _performanceService.enableFullscreenOptimization()
                : _performanceService.disableFullscreenOptimization();
          },
        ),
        if (WinRegistryService.isW11) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.desktop_mac_20_regular,
            label: context.l10n.perfOWGLabel,
            description: context.l10n.perfOWGDescription,
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
          label: context.l10n.perfBALabel,
          description: context.l10n.perfBADescription,
          switchBool: _baBool,
          function: (value) {
            _baBool.value = value;
            value
                ? _performanceService.enableBackgroundApps()
                : _performanceService.disableBackgroundApps();
          },
        ),
        CardHighlight(
          icon: msicons.FluentIcons.group_20_regular,
          label: context.l10n.perfSGMLabel,
          description: context.l10n.perfSGMDescription,
          child: ValueListenableBuilder<ServiceGrouping>(
            valueListenable: statusServicesGrouping,
            builder:
                (_, value, _) => ComboBox<ServiceGrouping>(
                  value: value,
                  onChanged: (value) {
                    statusServicesGrouping.value = value!;
                    switch (value) {
                      case ServiceGrouping.forced:
                        showDialog(
                          context: context,
                          builder:
                              (context) => ContentDialog(
                                constraints: const BoxConstraints(
                                  maxWidth: 500,
                                  maxHeight: 300,
                                ),
                                title: Text(context.l10n.warning),
                                content: Text(context.l10n.perfSGMDialog),
                                actions: [
                                  FilledButton(
                                    child: Text(context.l10n.close),
                                    onPressed: () => context.pop(),
                                  ),
                                ],
                              ),
                        );
                        _performanceService.forcedServicesGrouping();
                        break;
                      case ServiceGrouping.recommended:
                        _performanceService.recommendedServicesGrouping();
                        break;
                      case ServiceGrouping.disabled:
                        _performanceService.disableServicesGrouping();
                        break;
                    }
                  },
                  items: const [
                    ComboBoxItem(
                      value: ServiceGrouping.forced,
                      child: Text("Forced"),
                    ),
                    ComboBoxItem(
                      value: ServiceGrouping.recommended,
                      child: Text("Recommended"),
                    ),
                    ComboBoxItem(
                      value: ServiceGrouping.disabled,
                      child: Text("Disabled"),
                    ),
                  ],
                ),
          ),
        ),
        if (expBool.value) ...[
          CardHighlightSwitch(
            icon: msicons.FluentIcons.sleep_20_regular,
            label: context.l10n.perfCStatesLabel,
            description: context.l10n.perfCStatesDescription,
            switchBool: _cStatesBool,
            function: (value) {
              _cStatesBool.value = value;
              value
                  ? _performanceService.disableCStates()
                  : _performanceService.enableCStates();
            },
          ),
          Subtitle(content: Text(context.l10n.perfSectionFS)),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.document_bullet_list_clock_20_regular,
            label: context.l10n.perfLTALabel,
            description: context.l10n.perfLTADescription,
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
            label: context.l10n.perfEdTLabel,
            description: context.l10n.perfEdTDescription,
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
            label: context.l10n.perfMULabel,
            switchBool: _ntfsMUBool,
            function: (value) async {
              _ntfsMUBool.value = value;
              _ntfsMUBool.value
                  ? await _performanceService.enableMemoryUsageNTFS()
                  : await _performanceService.disableMemoryUsageNTFS();
            },
            codeSnippet: context.l10n.perfMUDescription,
          ),
        ],
      ],
    );
  }
}
