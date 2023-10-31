import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/l10n/generated/localizations.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:revitool/widgets/dialogs/msstore_dialogs.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

import '../../services/security_service.dart';
import '../../utils.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final SecurityService _securityService = SecurityService();
  late final _wdBool = ValueNotifier<bool>(_securityService.statusDefender);
  bool _wdButtonCalled = false;
  late final _uacBool = ValueNotifier<bool>(_securityService.statusUAC);
  late final _smBool =
      ValueNotifier<bool>(_securityService.statusSpectreMeltdown);

  @override
  void dispose() {
    _wdBool.dispose();
    _uacBool.dispose();
    _smBool.dispose();
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
        Visibility(
          visible: ((registryUtilsService.readInt(RegistryHive.localMachine,
                      r'SYSTEM\ControlSet001\Services\WinDefend', 'Start') !=
                  4) &&
              _securityService.statusTamperProtection &&
              !_wdButtonCalled),
          replacement: CardHighlightSwitch(
            icon: msicons.FluentIcons.shield_20_regular,
            label: ReviLocalizations.of(context).securityWDLabel,
            description: ReviLocalizations.of(context).securityWDDescription,
            switchBool: _wdBool,
            requiresRestart: true,
            function: (value) async {
              _wdBool.value = value;
              value
                  ? await _securityService.enableDefender()
                  : await _securityService.disableDefender();
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
                  setState(() => _wdButtonCalled = true);
                  if (!mounted) return;
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
          requiresRestart: true,
          function: (value) {
            _uacBool.value = value;
            value
                ? _securityService.enableUAC()
                : _securityService.disableUAC();
          },
        ),

        CardHighlightSwitch(
            icon: msicons.FluentIcons.shield_badge_20_regular,
            label: ReviLocalizations.of(context).securitySMLabel,
            description: ReviLocalizations.of(context).securitySMDescription,
            switchBool: _smBool,
            requiresRestart: true,
            function: (value) {
              _smBool.value = value;
              value
                  ? _securityService.enableSpectreMeltdown()
                  : _securityService.disableSpectreMeltdown();
            }),

        CardHighlight(
          icon: msicons.FluentIcons.certificate_20_regular,
          label: ReviLocalizations.of(context).miscCertsLabel,
          description: ReviLocalizations.of(context).miscCertsDescription,
          child: SizedBox(
            width: 150,
            child: Button(
              onPressed: () async {
                showLoadingDialog(context, "Updating Certificates");
                await _securityService.updateCertificates();

                if (!mounted) return;
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => ContentDialog(
                    content:
                        Text(ReviLocalizations.of(context).miscCertsDialog),
                    actions: [
                      Button(
                          child: Text(ReviLocalizations.of(context).okButton),
                          onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                );
              },
              child: Text(ReviLocalizations.of(context).updateButton),
            ),
          ),
        ),
      ],
    );
  }
}
