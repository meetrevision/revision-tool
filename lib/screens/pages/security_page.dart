import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/services/security_service.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:revitool/widgets/dialogs/msstore_dialogs.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _securityService = SecurityService();
  late final _wdBool = ValueNotifier<bool>(_securityService.statusDefender);
  late final _uacBool = ValueNotifier<bool>(_securityService.statusUAC);
  late final _smBool =
      ValueNotifier<bool>(_securityService.statusSpectreMeltdown);
  late final _statusProtections =
      ValueNotifier<bool>(_securityService.statusDefenderProtections);

  @override
  void dispose() {
    _wdBool.dispose();
    _uacBool.dispose();
    _smBool.dispose();
    _statusProtections.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(context.l10n.pageSecurity),
        ),
      ),
      children: [
        ValueListenableBuilder(
          valueListenable: _statusProtections,
          builder: (context, value, child) {
            switch (value) {
              case false:
                return CardHighlightSwitch(
                  icon: msicons.FluentIcons.shield_20_regular,
                  label: context.l10n.securityWDLabel,
                  description: context.l10n.securityWDDescription,
                  switchBool: _wdBool,
                  function: (valueWd) async {
                    showLoadingDialog(context, '');
                    try {
                      valueWd
                          ? await _securityService.enableDefender()
                          : {
                              updateStatusProtectionsValue(),
                              if (!_statusProtections.value)
                                await _securityService.disableDefender()
                            };
                      if (!context.mounted) return;
                      context.pop();
                      _wdBool.value = valueWd;
                      await showDialog(
                        context: context,
                        builder: (context) => ContentDialog(
                          content: Text(context.l10n.restartDialog),
                          actions: [
                            Button(
                              child: Text(context.l10n.okButton),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      context.pop();
                      await showDialog(
                        context: context,
                        builder: (context) => ContentDialog(
                          content: Text(e.toString()),
                          actions: [
                            Button(
                              child: Text(context.l10n.okButton),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              case true:
                return CardHighlight(
                  icon: msicons.FluentIcons.shield_20_regular,
                  label: context.l10n.securityWDLabel,
                  description: context.l10n.securityWDDescription,
                  child: SizedBox(
                    width: 150,
                    child: Button(
                      onPressed: () async {
                        Future.delayed(const Duration(seconds: 1), () async {
                          await _securityService.openDefenderThreatSettings();
                        });

                        showDialog(
                          dismissWithEsc: false,
                          context: context,
                          builder: (context) {
                            return ContentDialog(
                              content: Text(context.l10n.securityDialog),
                              actions: [
                                Button(
                                  child: Text(context.l10n.okButton),
                                  onPressed: () async {
                                    updateStatusProtectionsValue();
                                    switch (_statusProtections.value) {
                                      case true:
                                        await _securityService
                                            .openDefenderThreatSettings();
                                        break;
                                      default:
                                        Navigator.pop(context);
                                        break;
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(context.l10n.securityWDButton),
                    ),
                  ),
                );
              default:
                return const SizedBox();
            }
          },
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.person_lock_20_regular,
          label: context.l10n.securityUACLabel,
          description: context.l10n.securityUACDescription,
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
            label: context.l10n.securitySMLabel,
            description: context.l10n.securitySMDescription,
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
          label: context.l10n.miscCertsLabel,
          description: context.l10n.miscCertsDescription,
          child: SizedBox(
            width: 150,
            child: Button(
              onPressed: () async {
                showLoadingDialog(context, "Updating Certificates");
                await _securityService.updateCertificates();

                if (!context.mounted) return;
                context.pop();
                showDialog(
                  context: context,
                  builder: (context) => ContentDialog(
                    content: Text(context.l10n.miscCertsDialog),
                    actions: [
                      Button(
                          child: Text(context.l10n.okButton),
                          onPressed: () => context.pop()),
                    ],
                  ),
                );
              },
              child: Text(context.l10n.updateButton),
            ),
          ),
        ),
      ],
    );
  }

  void updateStatusProtectionsValue() {
    // force updating .value
    _statusProtections.value = _securityService.statusDefenderProtections;
  }
}
