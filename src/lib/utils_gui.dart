import 'dart:developer' as developer;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/core/services/win_registry_service.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:win32_registry/win32_registry.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsExperimentalStatus = Provider<bool>((ref) {
  return WinRegistryService.readInt(
        RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool',
        'Experimental',
      ) ==
      1;
});

const kScaffoldPagePadding = EdgeInsets.only(
  left: 24.5,
  right: 24.5,
  bottom: 40.5,
  top: 3.7,
);

Future<void> launchURL(String url) async {
  if (await UrlLauncherPlatform.instance.canLaunch(url)) {
    await UrlLauncherPlatform.instance.launch(
      url,
      useSafariVC: false,
      useWebView: false,
      enableJavaScript: false,
      enableDomStorage: false,
      universalLinksOnly: false,
      headers: <String, String>{},
    );
  } else {
    developer.log('Could not launch $url');
  }
}
