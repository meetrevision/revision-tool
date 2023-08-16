import 'dart:io';
import 'package:collection/collection.dart';
import 'package:win32_registry/win32_registry.dart';
import 'services/registry_utils_service.dart';

final RegistryUtilsService registryUtilsService = RegistryUtilsService();
const ListEquality eq = ListEquality();

final int buildNumber = int.parse(registryUtilsService.readString(
    RegistryHive.localMachine,
    r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\',
    'CurrentBuildNumber') as String);

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals")
    .path;

final bool w11 = buildNumber > 19045;
bool expBool = registryUtilsService.readInt(RegistryHive.localMachine,
        r'SOFTWARE\Revision\Revision Tool', 'Experimental') ==
    1;
String? themeModeReg = registryUtilsService.readString(
    RegistryHive.localMachine, r'SOFTWARE\Revision\Revision Tool', 'ThemeMode');

String appLanguage = registryUtilsService.readString(
      RegistryHive.localMachine,
      r'SOFTWARE\Revision\Revision Tool',
      'Language',
    ) ??
    'en_US';
