import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:win32_registry/win32_registry.dart';
import 'services/registry_utils_service.dart';

final registryUtilsService = RegistryUtilsService();

final int buildNumber = int.parse(registryUtilsService.readString(
    RegistryHive.localMachine,
    r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
    'CurrentBuildNumber')!);

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals")
    .path;

final bool w11 = buildNumber > 19045;
final expBool = ValueNotifier<bool>(registryUtilsService.readInt(
        RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool',
        'Experimental') ==
    1);
String? themeModeReg = registryUtilsService.readString(
    RegistryHive.localMachine, r'SOFTWARE\Revision\Revision Tool', 'ThemeMode');

String systemLanguage = registryUtilsService.readString(
      RegistryHive.currentUser,
      r'Control Panel\International',
      'LocaleName',
    ) ??
    'en_US';

String appLanguage = registryUtilsService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Language',
    ) ??
    'en_US';
