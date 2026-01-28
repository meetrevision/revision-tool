import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import '../ms_store/ms_store_command.dart';
import '../tweaks/security/security_service.dart';
import 'win_package_service.dart';

class WindowsPackageCommand extends Command<String> {

  WindowsPackageCommand() {
    argParser.addOption(
      'download',
      help: 'Downloads a package',
      allowed: allowedList,
    );
    argParser.addOption(
      'download-path',
      help: 'Custom download path for packages',
      defaultsTo: WinPackageService.cabPath,
    );
    argParser.addOption(
      'install',
      help: 'Install a package',
      allowed: allowedList,
    );
    argParser.addOption(
      'uninstall',
      help: 'Uninstall a package',
      allowed: allowedList,
    );
  }
  static final _msStoreCommand = MSStoreCommand();

  static const tag = 'Windows Package';

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'winpackage';

  static const Map<String, WinPackageType> packageList = {
    'system-components-removal': WinPackageType.systemComponentsRemoval,
    'defender-removal': WinPackageType.defenderRemoval,
    'ai-removal': WinPackageType.aiRemoval,
    'onedrive-removal': WinPackageType.oneDriveRemoval,
  };

  static List<String> get allowedList =>
      packageList.keys.toList(growable: false);

  @override
  FutureOr<String>? run() async {
    final String? installOption = argResults?.option('install');
    final String? uninstallOption = argResults?.option('uninstall');

    final String? downloadOption = argResults?.option('download');
    final String? downloadPath = argResults?.option('download-path');

    if (downloadOption != null) {
      await _downloadPackage(downloadOption, downloadPath);
    } else if (installOption != null) {
      await _installPackage(installOption);
    } else if (uninstallOption != null) {
      await _uninstallPackage(getPackageType(uninstallOption));
    } else {
      logger.e(
        '$name: No valid options provided. Use --help for usage information.',
      );
    }
    exit(0);
  }

  WinPackageType getPackageType(final String package) {
    final WinPackageType? type = packageList[package];
    if (type == null) {
      logger.e('$name(getPackageType): Invalid package type: package=$package');
      exit(1);
    }
    return type;
  }

  Future<void> _downloadPackage(
    final String parameter,
    final String? path,
  ) async {
    final WinPackageType mode = getPackageType(parameter);
    logger.i(
      '$name(downloadPackage): Downloading package=${mode.packageName}, path=$path',
    );
    try {
      final String packagePath = await WinPackageService.downloadPackage(
        mode,
        path: path,
      );
      stdout.writeln(packagePath);
    } catch (e) {
      logger.e(
        '$name(downloadPackage): Error downloading package: package=${mode.packageName}, path=$path',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  Future<void> _installPackage(final String parameter) async {
    final WinPackageType mode = getPackageType(parameter);

    try {
      if (mode == WinPackageType.defenderRemoval) {
        await const SecurityServiceImpl().disableDefender();
        return;
      }

      if (mode == WinPackageType.aiRemoval) {
        await WinRegistryService.hidePageVisibilitySettings('aicomponents');
        await WinRegistryService.hidePageVisibilitySettings(
          'privacy-systemaimodels',
        );
        await runPSCommand(
          'Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart',
        );
        await runPSCommand(
          'Get-AppxPackage -AllUsers Microsoft.Copilot* | Remove-AppxPackage',
        );
      }

      logger.i(
        '$name(installPackage): Downloading package=${mode.packageName}',
      );
      final String packagePath = await WinPackageService.downloadPackage(mode);

      logger.i(
        '$name(installPackage): Installing package=${mode.packageName}, path=$packagePath',
      );
      await WinPackageService.installPackage(packagePath);
    } catch (e) {
      logger.e(
        '$name(installPackage): Error installing package',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  Future<void> _uninstallPackage(final WinPackageType packageType) async {
    logger.i(
      '$name(uninstallPackage): Uninstalling package=${packageType.packageName}',
    );

    try {
      if (packageType == WinPackageType.defenderRemoval) {
        await const SecurityServiceImpl().enableDefender();
      }

      if (packageType == WinPackageType.aiRemoval) {
        await WinRegistryService.unhidePageVisibilitySettings('aicomponents');
        await WinRegistryService.unhidePageVisibilitySettings(
          'privacy-systemaimodels',
        );
        await runPSCommand(
          'Enable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart',
        );
        await _msStoreCommand.installPackage(
          id: '9nht9rb2f4hd',
          ring: 'Retail',
          arch: 'auto',
          downloadOnly: false,
        );
      }
      await WinPackageService.uninstallPackage(packageType);
    } catch (e) {
      logger.e(
        '$name(uninstallPackage): Error uninstalling package=${packageType.packageName}',
        error: e,
        stackTrace: StackTrace.current,
      );
      exit(1);
    }
  }
}
