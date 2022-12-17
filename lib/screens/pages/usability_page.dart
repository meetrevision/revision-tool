import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';

class UsabilityPage extends StatefulWidget {
  const UsabilityPage({super.key});

  @override
  State<UsabilityPage> createState() => _UsabilityPageState();
}

class _UsabilityPageState extends State<UsabilityPage> {
  bool notifBool = readRegistryInt(RegistryHive.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'IsNotificationsEnabled') == 1;
  bool elbnBool = readRegistryInt(RegistryHive.currentUser, r'Software\Policies\Microsoft\Windows\Explorer', 'EnableLegacyBalloonNotifications') != 0;
  bool itpBool = readRegistryInt(RegistryHive.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'AllowInputPersonalization') == 1;

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
      header: const PageHeader(
        title: Text('Usability'),
      ),
      children: [
        CardHighlightSwitch(
          icon: FluentIcons.action_center,
          label: "Windows Notifications",
          description: "Completely toggle Windows notifications",
          switchBool: notifBool,
          function: (value) async {
            setState(() {
              notifBool = value;
            });
            if (notifBool) {
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'IsNotificationsEnabled', 1);
              deleteRegistry(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings', 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK');
              deleteRegistry(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings', 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK');
              deleteRegistry(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings', 'NOC_GLOBAL_SETTING_TOASTS_ENABLED');
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'DisableNotificationCenter', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'DisableNotificationCenter', 0);
              deleteRegistry(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications', 'ToastEnabled');
              deleteRegistry(Registry.localMachine, r'SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications', 'ToastEnabled');
              deleteRegistry(Registry.currentUser, r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications', 'NoToastApplicationNotification');
              deleteRegistry(Registry.currentUser, r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications', 'NoTileApplicationNotification');
              await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
              await Process.run('explorer.exe', [], runInShell: true);
            } else {
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings', 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK', 0);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings', 'NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK', 0);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings', 'NOC_GLOBAL_SETTING_TOASTS_ENABLED', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'DisableNotificationCenter', 1);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'DisableNotificationCenter', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'ToastEnabled', 0);
              writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications', 'NoToastApplicationNotification', 1);
              writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications', 'NoTileApplicationNotification', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\Windows\Explorer', 'IsNotificationsEnabled', 0);
              await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
              await Process.run('explorer.exe', [], runInShell: true);
            }
          },
        ),
        if (notifBool) ...[
          const SizedBox(height: 5.0),
          CardHighlightSwitch(
            icon: FluentIcons.balloons,
            label: "Legacy Notification Balloons",
            description: "Completely toggle Windows notifications",
            switchBool: elbnBool,
            function: (value) async {
              setState(() {
                elbnBool = value;
              });
              if (elbnBool) {
                writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\Windows\Explorer', 'EnableLegacyBalloonNotifications', 1);
                await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
                await Process.run('explorer.exe', [], runInShell: true);
              } else {
                writeRegistryDword(Registry.currentUser, r'Software\Policies\Microsoft\Windows\Explorer', 'EnableLegacyBalloonNotifications', 0);
                await Process.run('taskkill.exe', ['/im', 'explorer.exe', '/f']);
                await Process.run('explorer.exe', [], runInShell: true);
              }
            },
          ),
        ],
        const SizedBox(height: 5.0),
        CardHighlightSwitch(
          icon: FluentIcons.keyboard_classic,
          label: "Inking And Typing Personalization",
          description: "Windows will learn what you type to improve suggestions when writing",
          switchBool: itpBool,
          function: (value) async {
            setState(() {
              itpBool = value;
            });
            if (itpBool) {
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization', 'RestrictImplicitInkCollection', 0);
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization', 'RestrictImplicitTextCollection', 0);
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization\TrainedDataStore', 'HarvestContacts', 1);
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization\Settings', 'AcceptedPrivacyPolicy', 1);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitInkCollection', 0);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitTextCollection', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitInkCollection', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitTextCollection', 0);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'AllowInputPersonalization', 1);
            } else {
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization', 'RestrictImplicitInkCollection', 1);
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization', 'RestrictImplicitTextCollection', 1);
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization\TrainedDataStore', 'HarvestContacts', 0);
              writeRegistryDword(Registry.currentUser, r'Software\Microsoft\InputPersonalization\Settings', 'AcceptedPrivacyPolicy', 0);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitInkCollection', 1);
              writeRegistryDword(Registry.currentUser, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitTextCollection', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitInkCollection', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'RestrictImplicitTextCollection', 1);
              writeRegistryDword(Registry.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'AllowInputPersonalization', 0);
            }
          },
        ),
      ],
    );
  }
}
