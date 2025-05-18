import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/core/miscellaneous/miscellaneous_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:revitool/core/ms_store/widgets/msstore_dialogs.dart';

class MiscellaneousPage extends StatefulWidget {
  const MiscellaneousPage({super.key});

  @override
  State<MiscellaneousPage> createState() => _MiscellaneousPageState();
}

class _MiscellaneousPageState extends State<MiscellaneousPage> {
  final MiscellaneousService _miscellaneousService = MiscellaneousService();
  late final _hibBool = ValueNotifier<bool>(
    _miscellaneousService.statusHibernation,
  );
  // late final _hibMode =
  //     ValueNotifier<int>(_miscellaneousService.statusHibernationMode!);
  late final _fsbBool = ValueNotifier<bool>(
    _miscellaneousService.statusFastStartup,
  );
  late final _tmmBool = ValueNotifier<bool>(
    _miscellaneousService.statusTMMonitoring,
  );
  late final _mpoBool = ValueNotifier<bool>(_miscellaneousService.statusMPO);
  late final _bhrBool = ValueNotifier<bool>(
    _miscellaneousService.statusUsageReporting,
  );

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
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageMiscellaneous)),
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
        CardHighlight(
          icon: msicons.FluentIcons.xbox_controller_20_regular,
          label: context.l10n.miscUpdateKGL,
          description: context.l10n.miscUpdateKGLDescription,
          child: SizedBox(
            width: 150,
            child: FilledButton(
              onPressed: () async {
                String message = "";
                try {
                  showLoadingDialog(
                    context,
                    "${context.l10n.settingsUpdatingStatus} KGL",
                  );
                  await _miscellaneousService.updateKGL();
                  if (!context.mounted) return;
                  message = context.l10n.restartDialog;
                } catch (e) {
                  message = e.toString();
                } finally {
                  context.pop();
                  showRestartDialog(
                    context,
                    title: context.l10n.settingsUpdatingStatusSuccess,
                    content: message,
                  );
                }
              },
              child: Text(context.l10n.updateButton),
            ),
          ),
        ),
      ],
    );
  }
}
