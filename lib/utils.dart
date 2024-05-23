import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:path/path.dart' as p;

import 'services/registry_utils_service.dart';

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals")
    .path;

final expBool = ValueNotifier<bool>(RegistryUtilsService.readInt(
        RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool',
        'Experimental') ==
    1);

String systemLanguage = RegistryUtilsService.readString(
      RegistryHive.currentUser,
      r'Control Panel\International',
      'LocaleName',
    ) ??
    'en_US';

String appLanguage = RegistryUtilsService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Language',
    ) ??
    'en_US';

final ameTemp =
    p.join(Directory.systemTemp.path, 'AME', 'Playbooks', 'Revision-ReviOS');
