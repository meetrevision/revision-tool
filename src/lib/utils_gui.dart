import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:process_run/shell_run.dart';
import 'package:win32_registry/win32_registry.dart';

import 'core/services/win_registry_service.dart';

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
  if (url.isEmpty) throw ArgumentError('URL cannot be empty');
  if (Uri.tryParse(url) == null) throw FormatException('Invalid URL: $url');
  await run('rundll32 url.dll,FileProtocolHandler $url');
}
