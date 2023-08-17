import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/services/updates_service.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  final UpdatesService _updatesService = UpdatesService();
  late bool _pausedBool = _updatesService.statusPauseUpdatesWU;
  late bool _wuPageBool = _updatesService.statusVisibilityWU;
  late bool _wuDriversBool = _updatesService.statusDriversWU;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageUpdates),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.pause_20_regular,
          label: ReviLocalizations.of(context).wuPauseLabel,
          description: ReviLocalizations.of(context).wuPauseDescription,
          switchBool: _pausedBool,
          function: (value) async {
            setState(() => _pausedBool = value);
            _pausedBool
                ? _updatesService.enablePauseUpdatesWU()
                : _updatesService.disablePauseUpdatesWU();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.arrow_sync_20_regular,
          label: ReviLocalizations.of(context).wuPageLabel,
          description: ReviLocalizations.of(context).wuPageDescription,
          switchBool: _wuPageBool,
          function: (value) async {
            setState(() => _wuPageBool = value);
            _wuPageBool
                ? _updatesService.enableVisibilityWU()
                : _updatesService.disableVisibilityWU();
          },
        ),
        CardHighlightSwitch(
          icon: FluentIcons.devices4,
          label: ReviLocalizations.of(context).wuDriversLabel,
          description: ReviLocalizations.of(context).wuDriversDescription,
          switchBool: _wuDriversBool,
          function: (value) async {
            setState(() => _wuDriversBool = value);
            _wuDriversBool
                ? _updatesService.enableDriversWU()
                : _updatesService.disableDriversWU();
          },
        ),
      ],
    );
  }
}
