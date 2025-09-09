import 'package:fluent_ui/fluent_ui.dart';
import 'package:revitool/shared/win_registry_service.dart';
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
  left: 25,
  right: 25,
  bottom: 25,
  top: 7,
);
