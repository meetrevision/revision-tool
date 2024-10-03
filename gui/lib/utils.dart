import 'dart:io';
import 'package:common/common.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:win32_registry/win32_registry.dart';

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals")
    .path;

final expBool = ValueNotifier<bool>(WinRegistryService.readInt(
        RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool',
        'Experimental') ==
    1);

String systemLanguage = WinRegistryService.readString(
      RegistryHive.currentUser,
      r'Control Panel\International',
      'LocaleName',
    ) ??
    'en_US';

String appLanguage = WinRegistryService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Language',
    ) ??
    'en_US';
