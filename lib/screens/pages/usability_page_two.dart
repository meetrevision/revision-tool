import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/services/usability_service.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class UsabilityPageTwo extends StatefulWidget {
  const UsabilityPageTwo({super.key});

  @override
  State<UsabilityPageTwo> createState() => _UsabilityPageTwoState();
}

class _UsabilityPageTwoState extends State<UsabilityPageTwo> {
  final UsabilityService _usabilityService = UsabilityService();
  late final _mrcBool =
      ValueNotifier<bool>(_usabilityService.statusNewContextMenu);
  late final _tabsUWPbool =
      ValueNotifier<bool>(_usabilityService.statusTabsUWP);

  @override
  void dispose() {
    _mrcBool.dispose();
    _tabsUWPbool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title:
            Text('${ReviLocalizations.of(context).pageUsability} > Windows 11'),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.document_one_page_20_regular,
          label: ReviLocalizations.of(context).usability11MRCLabel,
          switchBool: _mrcBool,
          function: (value) async {
            _mrcBool.value = value;
            _mrcBool.value
                ? await _usabilityService.enableNewContextMenu()
                : await _usabilityService.disableNewContextMenu();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.folder_multiple_16_regular,
          label: ReviLocalizations.of(context).usability11FETLabel,
          switchBool: _tabsUWPbool,
          function: (value) {
            _tabsUWPbool.value = value;
            _tabsUWPbool.value
                ? _usabilityService.enableTabsUWP()
                : _usabilityService.disableTabsUWP();
          },
        ),
      ],
    );
  }
}
