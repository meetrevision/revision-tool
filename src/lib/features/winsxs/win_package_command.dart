import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import '../ms_store/ms_store_command.dart';
import '../tweaks/security/security_service.dart';
import 'win_package_service.dart';

class WindowsPackageCommand extends Command<void> {
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
    'xbox-removal': WinPackageType.xboxRemoval,
  };

  static List<String> get allowedList =>
      packageList.keys.toList(growable: false);

  @override
  FutureOr<void> run() async {
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

      if (mode == WinPackageType.xboxRemoval) {
        await runPSCommand(
          r"Get-AppxPackage -Name 'Microsoft.XboxGameCallableUI' | Remove-AppxPackage -PreserveRoamableApplicationData",
        ); // Unregister XboxGameCallableUI package first

        await runPSCommand(
          r"'Microsoft.Xbox.TCUI','Microsoft.XboxApp','Microsoft.GamingApp','Microsoft.GamingServices','Microsoft.Edge.GameAssist','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider' | ForEach-Object { Get-AppxPackage -AllUsers -Name $_ | Remove-AppxPackage -AllUsers }",
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
          ring: .retail,
          arch: .auto,
          downloadOnly: false,
        );
      }

      await WinPackageService.uninstallPackage(packageType);

      if (packageType == WinPackageType.xboxRemoval) {
        const xboGameCallableUIPath =
            r'C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy\AppxManifest.xml';
        if (File(xboGameCallableUIPath).existsSync()) {
          logger.i('winsxs: Re-registering XboxGameCallableUI package...');

          await runPSCommand(
            'Add-AppxPackage -Register -DisableDevelopmentMode -Path "$xboGameCallableUIPath"',
          );
        }

        logger.i('winsxs: Reinstalling Xbox packages from Microsoft Store...');

        const xboxPackages = <String, String>{
          'Microsoft.Xbox.TCUI': '9MV0B5HZVK9Z',
          // 'Microsoft.XboxApp': '9WZDNCRFJBD8', // Deprecated package
          'Microsoft.GamingApp': '9MV0B5HZVK9Z',
          'Microsoft.GamingServices': '9MWPM2CQNLHN',
          'Microsoft.Edge.GameAssist': '',
          'Microsoft.XboxGamingOverlay': '9NZKPSTSNW4P',
          'Microsoft.XboxIdentityProvider': '9WZDNCRD1HKW',
        };

        for (final MapEntry<String, String> package in xboxPackages.entries) {
          final String packageName = package.key;
          final String storeId = package.value;

          if (storeId.isEmpty) {
            logger.w(
              'winsxs: No Store ID for $packageName, skipping reinstallation.',
            );
            continue;
          }

          await _msStoreCommand.installPackage(
            id: storeId,
            ring: .retail,
            arch: .auto,
            downloadOnly: false,
          );
        }
      }
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
