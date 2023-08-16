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
  late bool _mrcBool = _usabilityService.statusNewContextMenu;
  late bool _tabsUWPbool = _usabilityService.statusTabsUWP;

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
            setState(() => _mrcBool = value);
            _mrcBool
                ? _usabilityService.enableNewContextMenu()
                : _usabilityService.disableNewContextMenu();
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.folder_multiple_16_regular,
          label: ReviLocalizations.of(context).usability11FETLabel,
          switchBool: _tabsUWPbool,
          function: (value) async {
            setState(() => _tabsUWPbool = value);
            _tabsUWPbool
                ? _usabilityService.enableTabsUWP()
                : _usabilityService.disableTabsUWP();
          },
        ),
      ],
    );
  }
}
