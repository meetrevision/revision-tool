import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:process_run/shell_run.dart';

class MiscellaneousPage extends StatefulWidget {
  const MiscellaneousPage({super.key});

  @override
  State<MiscellaneousPage> createState() => _MiscellaneousPageState();
}

class _MiscellaneousPageState extends State<MiscellaneousPage> {
  bool fsbBool = readRegistryInt(RegistryHive.localMachine, r'System\ControlSet001\Control\Session Manager\Power', 'HiberbootEnabled') == 1;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageMiscellaneous),
      ),
      children: [
        CardHighlightSwitch(
          icon: FluentIcons.hail_night,
          label: ReviLocalizations.of(context).miscFastStartupLabel,
          codeSnippet: ReviLocalizations.of(context).miscFastStartupDescription,
          switchBool: fsbBool,
          function: (value) async {
            setState(() {
              fsbBool = value;
            });
            if (fsbBool) {
              writeRegistryDword(Registry.localMachine, r'System\ControlSet001\Control\Session Manager\Power', 'HiberbootEnabled', 1);
              writeRegistryDword(Registry.localMachine, r'Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings', 'ShowHibernateOption', 1);
              await Shell().run(r'''
                     wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:true >NUL
                     wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:true >NUL
                     wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:true >NUL
                    ''');
            } else {
              writeRegistryDword(Registry.localMachine, r'System\ControlSet001\Control\Session Manager\Power', 'HiberbootEnabled', 0);
              writeRegistryDword(Registry.localMachine, r'Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings', 'ShowHibernateOption', 0);
              await Shell().run(r'''
                     wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:false >NUL
                     wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:false >NUL
                     wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:false >NUL
                    ''');
            }
          },
        )
      ],
    );
  }
}
