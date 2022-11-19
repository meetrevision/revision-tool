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
  bool itpBool = readRegistryInt(RegistryHive.localMachine, r'SOFTWARE\Policies\Microsoft\InputPersonalization', 'AllowInputPersonalization') == 1;
  bool foBool = false;
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(
        title: Text('Usability'),
      ),
      children: [
        //  subtitle(content: const Text('A simple ToggleSwitch')),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.action_center,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Notifications'),
                      Text(
                        "Get notified if there's something new",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(notifBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: notifBool,
                onChanged: (bool value) async {
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
            ],
          ),
        ),
        //
        const SizedBox(height: 5.0),
        CardHighlight(
          child: Row(
            children: [
              const SizedBox(width: 5.0),
              const Icon(
                FluentIcons.keyboard_classic,
                size: 24,
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoLabel(label: 'Inking And Typing Personalization'),
                      Text(
                        "Windows will learn what you type to improve suggestions when writing",
                        style: FluentTheme.of(context).brightness.isDark
                            ? const TextStyle(fontSize: 11, color: Color.fromARGB(255, 200, 200, 200), overflow: TextOverflow.fade)
                            : const TextStyle(fontSize: 11, color: Color.fromARGB(255, 117, 117, 117), overflow: TextOverflow.fade),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Text(itpBool ? "On" : "Off"),
              const SizedBox(width: 10.0),
              ToggleSwitch(
                checked: itpBool,
                onChanged: (bool value) {
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
          ),
        ),
      ],
    );
  }
}
