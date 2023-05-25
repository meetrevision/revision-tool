import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:process_run/shell_run.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class MiscellaneousPage extends StatefulWidget {
  const MiscellaneousPage({super.key});

  @override
  State<MiscellaneousPage> createState() => _MiscellaneousPageState();
}

class _MiscellaneousPageState extends State<MiscellaneousPage> {
  bool _hibBool = readRegistryInt(RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled') ==
      1;

  bool _fsbBool = readRegistryInt(
          RegistryHive.localMachine,
          r'System\ControlSet001\Control\Session Manager\Power',
          'HiberbootEnabled') ==
      1;
  bool _tmmBool = readRegistryInt(RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start') ==
          2 &&
      readRegistryInt(RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\Ndu', 'Start') ==
          2;
  bool _mpoBool = readRegistryInt(RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode') !=
      5;

  bool _bhrBool = readRegistryInt(RegistryHive.localMachine,
          r'SYSTEM\ControlSet001\Services\DPS', 'Start') !=
      4;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(ReviLocalizations.of(context).pageMiscellaneous),
      ),
      children: [
        CardHighlightSwitch(
          icon: msicons.FluentIcons.sleep_20_regular,
          label: ReviLocalizations.of(context).miscHibernateLabel,
          description: ReviLocalizations.of(context).miscHibernateDescription,
          switchBool: _hibBool,
          function: (value) async {
            setState(() {
              _hibBool = value;
            });
            if (_hibBool) {
              writeRegistryDword(
                  Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\System',
                  'ShowHibernateOption',
                  1);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 1);
              await Shell().run(r'''
                     powercfg -h on
                     powercfg /h /type full
                    ''');
            } else {
              writeRegistryDword(
                  Registry.localMachine,
                  r'Software\Policies\Microsoft\Windows\System',
                  'ShowHibernateOption',
                  0);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Control\Power', 'HibernateEnabled', 0);
              await Shell().run(r'''
                     powercfg -h off
                    ''');
            }
          },
        ),
        if (_hibBool) ...[
          CardHighlight(
            icon: msicons.FluentIcons.document_save_20_regular,
            label: ReviLocalizations.of(context).miscHibernateModeLabel,
            description:
                ReviLocalizations.of(context).miscHibernateModeDescription,
            child: ComboBox(
              value: readRegistryInt(RegistryHive.localMachine,
                  r'System\ControlSet001\Control\Power', 'HiberFileType'),
              onChanged: (value) async {
                switch (value) {
                  case 1:
                    await Shell().run(r'''
                     powercfg /h /type reduced
                    ''');
                    setState(() {});
                    break;
                  case 2:
                    await Shell().run(r'''
                     powercfg /h /type full
                    ''');
                    setState(() {});
                    break;
                  default:
                }
              },
              items: const <ComboBoxItem>[
                ComboBoxItem(
                  value: 2,
                  child: Text("Full"),
                ),
                ComboBoxItem(
                  value: 1,
                  child: Text("Reduced"),
                ),
              ],
            ),
          ),
          CardHighlightSwitch(
            icon: msicons.FluentIcons.weather_hail_night_20_regular,
            label: ReviLocalizations.of(context).miscFastStartupLabel,
            description:
                ReviLocalizations.of(context).miscFastStartupDescription,
            switchBool: _fsbBool,
            function: (value) async {
              setState(() {
                _fsbBool = value;
              });
              if (_fsbBool) {
                writeRegistryDword(
                    Registry.localMachine,
                    r'System\ControlSet001\Control\Session Manager\Power',
                    'HiberbootEnabled',
                    1);
                writeRegistryDword(
                    Registry.localMachine,
                    r'Software\Policies\Microsoft\Windows\System',
                    'HiberbootEnabled',
                    1);
              } else {
                writeRegistryDword(
                    Registry.localMachine,
                    r'System\ControlSet001\Control\Session Manager\Power',
                    'HiberbootEnabled',
                    0);
                writeRegistryDword(
                    Registry.localMachine,
                    r'Software\Policies\Microsoft\Windows\System',
                    'HiberbootEnabled',
                    0);
              }
            },
          ),
        ],
        CardHighlightSwitch(
          icon: FluentIcons.task_manager,
          label: ReviLocalizations.of(context).miscTMMonitoringLabel,
          description:
              ReviLocalizations.of(context).miscTMMonitoringDescription,
          switchBool: _tmmBool,
          function: (value) async {
            setState(() {
              _tmmBool = value;
            });
            if (_tmmBool) {
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 2);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 2);
              await Shell().run(r'''
                    sc start GraphicsPerfSvc
                    sc start Ndu
                    ''');
            } else {
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\GraphicsPerfSvc', 'Start', 4);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 4);
            }
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.window_settings_20_regular,
          label: ReviLocalizations.of(context).miscMpoLabel,
          codeSnippet: ReviLocalizations.of(context).miscMpoCodeSnippet,
          switchBool: _mpoBool,
          function: (value) async {
            setState(() {
              _mpoBool = value;
            });
            if (_mpoBool) {
              deleteRegistry(Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode');
            } else {
              writeRegistryDword(Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\Dwm', 'OverlayTestMode', 5);
            }
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.battery_checkmark_20_regular,
          label: ReviLocalizations.of(context).miscBHRLabel,
          description: ReviLocalizations.of(context).miscBHRDescription,
          switchBool: _bhrBool,
          function: (value) async {
            setState(() {
              _bhrBool = value;
            });
            if (_bhrBool) {
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\DPS', 'Start', 2);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 2);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\diagsvc', 'Start', 2);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\WdiServiceHost', 'Start', 2);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\WdiSystemHost', 'Start', 2);
              await Shell().run(r'''
                     wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:true >NUL
                     wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:true >NUL
                     wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:true >NUL
                    ''');
            } else {
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\DPS', 'Start', 4);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\Ndu', 'Start', 4);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\diagsvc', 'Start', 4);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\WdiServiceHost', 'Start', 4);
              writeRegistryDword(Registry.localMachine,
                  r'SYSTEM\ControlSet001\Services\WdiSystemHost', 'Start', 4);
              await Shell().run(r'''
                     wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /e:false >NUL
                     wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /e:false >NUL
                     wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /e:false >NUL
                    ''');
            }
          },
        ),
      ],
    );
  }
}
