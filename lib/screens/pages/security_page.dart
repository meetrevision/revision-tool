import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool wdBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Services\WinDefend', 'Start') != 4;
  bool uacBool = readRegistryInt(RegistryHive.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableLUA') != 0;
  bool smBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettingsOverride') != 3;
  bool iTSXBool = readRegistryInt(RegistryHive.localMachine, r'SYSTEM\ControlSet001\Control\Session Manager\Kernel', 'DisableTsx') == 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(ReviLocalizations.of(context).pageSecurity),
        ),
      ),
      children: [
        CardHighlightSwitch(
          icon: FluentIcons.defender_app,
          label: ReviLocalizations.of(context).securityWDLabel,
          description: ReviLocalizations.of(context).securityWDDescription,
          switchBool: wdBool,
          function: (value) async {
            setState(() {
              wdBool = value;
            });
            if (wdBool) {
              await run('"$directoryExe\\NSudoLG.exe" -U:T -P:E cmd /min /c "$directoryExe\\EnableWD.bat"');
              // // Services and Drivers
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\MsSecFlt', 'Start', 0);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\SecurityHealthService', 'Start', 3);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\Sense', 'Start', 3);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdBoot', 'Start', 0);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdFilter', 'Start', 0);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdNisDrv', 'Start', 3);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdNisSvc', 'Start', 3);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WinDefend', 'Start', 3);
              // // SystemGuard
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\SgrmAgent', 'Start', 0);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\SgrmBroker', 'Start', 2);
              // // WindowsSystemTray
              // writeRegistryString(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'SecurityHealth', r'%systemroot%\system32\SecurityHealthSystray.exe');
              // // WebThreatDefSvc
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\webthreatdefsvc', 'Start', 0);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\webthreatdefusersvc', 'Start', 2);
              // final key = Registry.openPath(RegistryHive.localMachine, path: r'SYSTEM\ControlSet001\Services');
              // String wtdsvcKey = '';
              // for (final value in key.subkeyNames) {
              //   if (value.toString().contains("webthreatdefusersvc_")) {
              //     wtdsvcKey = value.toString();
              //   }
              // }
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\' + wtdsvcKey, 'Start', 2);
              // deleteRegistryKey(Registry.localMachine, r'Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\smartscreen.exe');
              // deleteRegistryKey(Registry.currentUser, r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations');
              // deleteRegistryKey(Registry.localMachine, r'Software\Policies\Microsoft\Windows Defender\SmartScreen');
              // deleteRegistryKey(Registry.localMachine, r'Software\Policies\Microsoft\Windows Defender\Signature Updates');
            } else {
              await run('"$directoryExe\\NSudoLG.exe" -U:T -P:E cmd /min /c "$directoryExe\\DisableWD.bat"');
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\MsSecFlt', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\SecurityHealthService', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\Sense', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdBoot', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdFilter', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdNisDrv', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WdNisSvc', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\WinDefend', 'Start', 4);
              // // SystemGuard
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\SgrmAgent', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\SgrmBroker', 'Start', 4);
              // // WindowsSystemTray
              // deleteRegistry(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'SecurityHealth');
              // // WebThreatDefSvc
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\webthreatdefsvc', 'Start', 4);
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\webthreatdefusersvc', 'Start', 4);
              // final key = Registry.openPath(RegistryHive.localMachine, path: r'SYSTEM\ControlSet001\Services');
              // String wtdsvcKey = '';
              // for (final value in key.subkeyNames) {
              //   if (value.toString().contains("webthreatdefusersvc_")) {
              //     wtdsvcKey = value.toString();
              //   }
              // }
              // writeRegistryDword(Registry.localMachine, r'SYSTEM\ControlSet001\Services\' + wtdsvcKey, 'Start', 4);
              // writeRegistryString(
              //     Registry.localMachine, r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\smartscreen.exe', 'Debugger', r'%%windir%%\System32\taskkill.exe');
              // writeRegistryDword(Registry.currentUser, r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations', 'DefaultFileTypeRisk', 1808);
              // writeRegistryDword(Registry.currentUser, r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations', 'SaveZoneInformation', 1);
              // writeRegistryString(Registry.localMachine, r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations', 'LowRiskFileTypes',
              //     r'.avi;.bat;.com;.cmd;.exe;.htm;.html;.lnk;.mpg;.mpeg;.mov;.mp3;.msi;.m3u;.rar;.reg;.txt;.vbs;.wav;.zip;');
              // writeRegistryString(Registry.localMachine, r'Software\Microsoft\Windows\CurrentVersion\Policies\Associations', 'ModRiskFileTypes', r'.bat;.exe;.reg;.vbs;.chm;.msi;.js;.cmd');
              // writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows Defender\SmartScreen', 'ConfigureAppInstallControlEnabled', 0);
              // writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows Defender\SmartScreen', 'ConfigureAppInstallControl', 0);
              // writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\Windows Defender\SmartScreen', 'EnableSmartScreen', 0);
              // writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter', 'EnabledV9', 0);
              // writeRegistryDword(Registry.localMachine, r'Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter', 'EnabledV9', 0);
            }

            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                content: Text(ReviLocalizations.of(context).restartDialog),
                actions: [
                  Button(
                    child: Text(ReviLocalizations.of(context).okButton),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        //
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.local_admin,
          label: ReviLocalizations.of(context).securityUACLabel,
          description: ReviLocalizations.of(context).securityUACDescription,
          switchBool: uacBool,
          function: (value) async {
            setState(() {
              uacBool = value;
            });
            if (uacBool) {
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableVirtualization', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableInstallerDetection', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'PromptOnSecureDesktop', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableLUA', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableSecureUIAPaths', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'ConsentPromptBehaviorAdmin', 5);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'ValidateAdminCodeSignatures', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableUIADesktopToggle', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'ConsentPromptBehaviorUser', 3);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'FilterAdministratorToken', 0);
            } else {
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableVirtualization', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableInstallerDetection', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'PromptOnSecureDesktop', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableLUA', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableSecureUIAPaths', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'ConsentPromptBehaviorAdmin', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'ValidateAdminCodeSignatures', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'EnableUIADesktopToggle', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'ConsentPromptBehaviorUser', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'FilterAdministratorToken', 0);
            }
          },
        ),
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.a_t_p_logo,
          label: ReviLocalizations.of(context).securitySMLabel,
          description: ReviLocalizations.of(context).securitySMDescription,
          switchBool: smBool,
          function: (value) async {
            setState(() {
              smBool = value;
            });
            if (smBool) {
              deleteRegistry(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettings');
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettingsOverride', 0);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettingsOverrideMask', 3);
            } else {
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettings', 1);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettingsOverride', 3);
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'FeatureSettingsOverrideMask', 3);
            }
          },
        ),
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.market,
          label: ReviLocalizations.of(context).securityITSXLabel,
          description: ReviLocalizations.of(context).securityITSXDescription,
          switchBool: iTSXBool,
          function: (value) async {
            setState(() {
              iTSXBool = value;
            });
            if (smBool) {
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel', 'DisableTsx', 0);
            } else {
              writeRegistryDword(Registry.localMachine, r'SYSTEM\CurrentControlSet\Control\Session Manager\kernel', 'DisableTsx', 1);
            }
          },
        ),
      ],
    );
  }
}
