import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/extensions.dart';
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
  late final _hibBool =
      ValueNotifier<bool>(_miscellaneousService.statusHibernation);
  // late final _hibMode =
  //     ValueNotifier<int>(_miscellaneousService.statusHibernationMode!);
  late final _fsbBool =
      ValueNotifier<bool>(_miscellaneousService.statusFastStartup);
  late final _tmmBool =
      ValueNotifier<bool>(_miscellaneousService.statusTMMonitoring);
  late final _mpoBool = ValueNotifier<bool>(_miscellaneousService.statusMPO);
  late final _bhrBool =
      ValueNotifier<bool>(_miscellaneousService.statusUsageReporting);

  @override
  void dispose() {
    _hibBool.dispose();
    // _hibMode.dispose();
    _fsbBool.dispose();
    _mpoBool.dispose();
    _bhrBool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(context.l10n.pageMiscellaneous),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.sleep_20_regular,
          label: context.l10n.miscHibernateLabel,
          description: context.l10n.miscHibernateDescription,
          switchBool: _hibBool,
          function: (value) async {
            _hibBool.value = value;
            value
                ? await _miscellaneousService.enableHibernation()
                : await _miscellaneousService.disableHibernation();
          },
        ),
        // ValueListenableBuilder(
        //   valueListenable: _hibBool,
        //   builder: (context, value, child) {
        //     if (value) {
        //       return Column(
        //         children: [
        //           ValueListenableBuilder(
        //               valueListenable: _hibMode,
        //               builder: (context, hibValue, child) {
        //                 return CardHighlight(
        //                   icon: msicons.FluentIcons.document_save_20_regular,
        //                   label: context.l10n
        //                       .miscHibernateModeLabel,
        //                   description: context.l10n
        //                       .miscHibernateModeDescription,
        //                   child: ComboBox(
        //                     value: hibValue,
        //                     onChanged: (value) {
        //                       _hibMode.value = value!;
        //                     },
        //                     items: [
        //                       ComboBoxItem(
        //                         onTap: () async {
        //                           await _miscellaneousService
        //                               .setHibernateModeReduced();
        //                         },
        //                         value: 1,
        //                         child: const Text("Reduced"),
        //                       ),
        //                       ComboBoxItem(
        //                         onTap: () async {
        //                           await _miscellaneousService
        //                               .setHibernateModeFull();
        //                         },
        //                         value: 2,
        //                         child: const Text("Full"),
        //                       ),
        //                     ],
        //                   ),
        //                 );
        //               }),
        //           CardHighlightSwitch(
        //             icon: msicons.FluentIcons.weather_hail_night_20_regular,
        //             label: context.l10n.miscFastStartupLabel,
        //             description: context.l10n
        //                 .miscFastStartupDescription,
        //             switchBool: _fsbBool,
        //             function: (value) {
        //               _fsbBool.value = value;
        //               value
        //                   ? _miscellaneousService.enableFastStartup()
        //                   : _miscellaneousService.disableFastStartup();
        //             },
        //           )
        //         ],
        //       );
        //     }
        //     return const SizedBox();
        //   },
        // ),

        CardHighlightSwitch(
          icon: FluentIcons.task_manager,
          label: context.l10n.miscTMMonitoringLabel,
          description: context.l10n.miscTMMonitoringDescription,
          switchBool: _tmmBool,
          requiresRestart: true,
          function: (value) async {
            _tmmBool.value = value;
            value
                ? await _miscellaneousService.enableTMMonitoring()
                : _miscellaneousService.disableTMMonitoring();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.window_settings_20_regular,
          label: context.l10n.miscMpoLabel,
          codeSnippet: context.l10n.miscMpoCodeSnippet,
          switchBool: _mpoBool,
          function: (value) async {
            _mpoBool.value = value;
            value
                ? _miscellaneousService.enableMPO()
                : _miscellaneousService.disableMPO();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.battery_checkmark_20_regular,
          label: context.l10n.miscURLabel,
          description: context.l10n.miscURDescription,
          switchBool: _bhrBool,
          function: (value) async {
            _bhrBool.value = value;
            value
                ? await _miscellaneousService.enableUsageReporting()
                : await _miscellaneousService.disableUsageReporting();
          },
        ),
      ],
    );
  }
}
