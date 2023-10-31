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
  late final _pausedBool =
      ValueNotifier<bool>(_updatesService.statusPauseUpdatesWU);
  late final _wuPageBool =
      ValueNotifier<bool>(_updatesService.statusVisibilityWU);
  late final _wuDriversBool =
      ValueNotifier<bool>(_updatesService.statusDriversWU);

  @override
  void dispose() {
    _pausedBool.dispose();
    _wuPageBool.dispose();
    _wuDriversBool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      key: GlobalKey(),
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageUpdates),
      ),
      children: [
        CardHighlightSwitch(
         
          icon: msicons.FluentIcons.pause_20_regular,
          label: ReviLocalizations.of(context).wuPauseLabel,
          description: ReviLocalizations.of(context).wuPauseDescription,
          switchBool: _pausedBool,
          function: (value) {
            _pausedBool.value = value;
            value
                ? _updatesService.enablePauseUpdatesWU()
                : _updatesService.disablePauseUpdatesWU();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.arrow_sync_20_regular,
          label: ReviLocalizations.of(context).wuPageLabel,
          description: ReviLocalizations.of(context).wuPageDescription,
          switchBool: _wuPageBool,
          function: (value) {
            _wuPageBool.value = value;
            value
                ? _updatesService.enableVisibilityWU()
                : _updatesService.disableVisibilityWU();
          },
        ),
        CardHighlightSwitch(
    
          icon: FluentIcons.devices4,
          label: ReviLocalizations.of(context).wuDriversLabel,
          description: ReviLocalizations.of(context).wuDriversDescription,
          switchBool: _wuDriversBool,
          function: (value) {
            _wuDriversBool.value = value;
            value
                ? _updatesService.enableDriversWU()
                : _updatesService.disableDriversWU();
          },
        ),
      ],
    );
  }
}
