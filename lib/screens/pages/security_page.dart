import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _wdBool = (readRegistryInt(RegistryHive.localMachine,
              r'SYSTEM\ControlSet001\Services\WinDefend', 'Start') ??
          4) <=
      3;
  bool _wdButtonCalled = false;

  bool _uacBool = readRegistryInt(
          RegistryHive.localMachine,
          r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
          'EnableLUA') ==
      1;
  bool _smBool = readRegistryInt(
          RegistryHive.localMachine,
          r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
          'FeatureSettingsOverride') ==
      0;

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
        Visibility(
          visible: (readRegistryInt(
                      RegistryHive.localMachine,
                      r'SOFTWARE\Microsoft\Windows Defender\Features',
                      'TamperProtection') ==
                  5 &&
              !_wdButtonCalled),
          replacement: CardHighlightSwitch(
            icon: msicons.FluentIcons.shield_20_regular,
            label: ReviLocalizations.of(context).securityWDLabel,
            description: ReviLocalizations.of(context).securityWDDescription,
            switchBool: _wdBool,
            function: (value) async {
              setState(() {
                _wdBool = value;
              });
              if (_wdBool) {
                await run(
                    '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableWD.bat"');
              } else {
                await run(
                    '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableWD.bat"');
                // ignore: use_build_context_synchronously
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
                      )
                    ],
                  ),
                );
              }
            },
          ),
          child: CardHighlight(
            icon: msicons.FluentIcons.shield_20_regular,
            label: ReviLocalizations.of(context).securityWDLabel,
            description: ReviLocalizations.of(context).securityWDDescription,
            child: SizedBox(
              width: 150,
              child: Button(
                onPressed: () async {
                  final process = await Process.start(
                    'explorer.exe',
                    ['windowsdefender://threatsettings'],
                  );
                  await process.exitCode;
                  setState(() {
                    _wdButtonCalled = true;
                  });
                  showDialog(
                    context: context,
                    builder: (context) => ContentDialog(
                      content:
                          Text(ReviLocalizations.of(context).securityDialog),
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
                child: Text(ReviLocalizations.of(context).securityWDButton),
              ),
            ),
          ),
        ),

        // if (_wdBool && tamperProtection) ...[
        //   CardHighlight(
        //     child: Row(
        //       children: [
        //         const SizedBox(width: 5.0),
        //         const Icon(
        //           msicons.FluentIcons.shield_20_regular,
        //           size: 24,
        //         ),
        //         const SizedBox(width: 15.0),
        //         Expanded(
        //           child: SizedBox(
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 InfoLabel(
        //                     label:
        //                         ReviLocalizations.of(context).securityWDLabel),
        //                 Text(
        //                   ReviLocalizations.of(context).securityWDDescription,
        //                   style: FluentTheme.of(context).brightness.isDark
        //                       ? const TextStyle(
        //                           fontSize: 11,
        //                           color: Color.fromARGB(255, 200, 200, 200),
        //                           overflow: TextOverflow.fade)
        //                       : const TextStyle(
        //                           fontSize: 11,
        //                           color: Color.fromARGB(255, 117, 117, 117),
        //                           overflow: TextOverflow.fade),
        //                 )
        //               ],
        //             ),
        //           ),
        //         ),
        //         SizedBox(
        //           width: 150,
        //           child: Button(
        //             onPressed: () async {
        //               final process = await Process.start(
        //                 'explorer.exe',
        //                 ['windowsdefender://threatsettings'],
        //               );
        //               await process.exitCode;

        //               _wdButtonCalled = true;
        //               setState(() {});
        //             },
        //             child: Text(ReviLocalizations.of(context).securityWDButton),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ] else ...[
        //   CardHighlightSwitch(
        //     icon: msicons.FluentIcons.shield_20_regular,
        //     label: ReviLocalizations.of(context).securityWDLabel,
        //     description: ReviLocalizations.of(context).securityWDDescription,
        //     switchBool: _wdBool,
        //     function: (value) async {
        //       setState(() {
        //         _wdBool = value;
        //       });
        //       if (_wdBool) {
        //         await run(
        //             '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\EnableWD.bat"');
        //       } else {
        //         showDialog(
        //           context: context,
        //           builder: (context) => ContentDialog(
        //             content: Text(ReviLocalizations.of(context).securityDialog),
        //             actions: [
        //               Button(
        //                 child: Text(ReviLocalizations.of(context).okButton),
        //                 onPressed: () async {
        //                   await run(
        //                       '"$directoryExe\\MinSudo.exe" --NoLogo --TrustedInstaller cmd /min /c "$directoryExe\\DisableWD.bat"');
        //                   // ignore: use_build_context_synchronously
        //                   showDialog(
        //                     context: context,
        //                     builder: (context) => ContentDialog(
        //                       content: Text(
        //                           ReviLocalizations.of(context).restartDialog),
        //                       actions: [
        //                         Button(
        //                           child: Text(
        //                               ReviLocalizations.of(context).okButton),
        //                           onPressed: () {
        //                             Navigator.pop(context);
        //                           },
        //                         ),
        //                       ],
        //                     ),
        //                   );
        //                 },
        //               ),
        //             ],
        //           ),
        //         );
        //       }
        //     },
        //   ),
        // ],
        CardHighlightSwitch(
          icon: msicons.FluentIcons.person_lock_20_regular,
          label: ReviLocalizations.of(context).securityUACLabel,
          description: ReviLocalizations.of(context).securityUACDescription,
          switchBool: _uacBool,
          function: (value) async {
            setState(() {
              _uacBool = value;
            });
            if (_uacBool) {
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableVirtualization',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableInstallerDetection',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'PromptOnSecureDesktop',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableLUA',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableSecureUIAPaths',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'ConsentPromptBehaviorAdmin',
                  5);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'ValidateAdminCodeSignatures',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableUIADesktopToggle',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'ConsentPromptBehaviorUser',
                  3);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'FilterAdministratorToken',
                  0);
            } else {
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableVirtualization',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableInstallerDetection',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'PromptOnSecureDesktop',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableLUA',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableSecureUIAPaths',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'ConsentPromptBehaviorAdmin',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'ValidateAdminCodeSignatures',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'EnableUIADesktopToggle',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'ConsentPromptBehaviorUser',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
                  'FilterAdministratorToken',
                  0);
            }
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.shield_badge_20_regular,
          label: ReviLocalizations.of(context).securitySMLabel,
          description: ReviLocalizations.of(context).securitySMDescription,
          switchBool: _smBool,
          function: (value) async {
            setState(() {
              _smBool = value;
            });
            if (_smBool) {
              deleteRegistry(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
                  'FeatureSettings');
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
                  'FeatureSettingsOverride',
                  0);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
                  'FeatureSettingsOverrideMask',
                  3);
            } else {
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
                  'FeatureSettings',
                  1);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
                  'FeatureSettingsOverride',
                  3);
              writeRegistryDword(
                  Registry.localMachine,
                  r'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management',
                  'FeatureSettingsOverrideMask',
                  3);
            }
          },
        ),
      ],
    );
  }
}
