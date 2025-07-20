import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:revitool/core/ms_store/ms_store_command.dart';
import 'package:revitool/core/security/security_service.dart';
import 'package:revitool/core/winsxs/win_package_service.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/utils.dart';

class WindowsPackageCommand extends Command<String> {
  static final _winPackageService = WinPackageService();
  static final _msStoreCommand = MSStoreCommand();
  static final _securityService = SecurityService();

  static const tag = "[Windows Package]";

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'winpackage';

  static const packageList = {
    'system-components-removal': WinPackageType.systemComponentsRemoval,
    'defender-removal': WinPackageType.defenderRemoval,
    'ai-removal': WinPackageType.aiRemoval,
    'onedrive-removal': WinPackageType.oneDriveRemoval,
  };

  static List<String> get allowedList =>
      packageList.keys.toList(growable: false);

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

  @override
  FutureOr<String>? run() async {
    final installOption = argResults?.option('install');
    final uninstallOption = argResults?.option('uninstall');

    final downloadOption = argResults?.option('download');
    final downloadPath = argResults?.option('download-path');

    if (downloadOption != null) {
      await _downloadPackage(downloadOption, downloadPath);
    } else if (installOption != null) {
      await _installPackage(installOption);
    } else if (uninstallOption != null) {
      await _uninstallPackage(getPackageType(uninstallOption));
    } else {
      stderr.writeln('$tag Invalid command');
    }
    exit(0);
  }

  WinPackageType getPackageType(final String package) {
    final type = packageList[package];
    if (type == null) {
      stderr.writeln('$tag Invalid package type: $package');
      exit(1);
    }
    return type;
  }

  Future<void> _downloadPackage(
    final String parameter,
    final String? path,
  ) async {
    try {
      final mode = getPackageType(parameter);
      stdout.writeln('$tag Downloading package: ${mode.packageName}');
      final packagePath = await _winPackageService.downloadPackage(
        mode,
        path: path,
      );
      stdout.writeln(packagePath);
    } catch (e) {
      stderr.writeln('$tag $e');
    }
  }

  Future<void> _installPackage(final String parameter) async {
    try {
      final mode = getPackageType(parameter);

      if (mode == WinPackageType.defenderRemoval) {
        await _securityService.disableDefender();
        return;
      }

      stdout.writeln('$tag Downloading package: ${mode.packageName}');
      final packagePath = await _winPackageService.downloadPackage(mode);

      stdout.writeln('$tag Installing package: ${mode.packageName}');
      await _winPackageService.installPackage(packagePath);

      if (mode == WinPackageType.aiRemoval) {
        WinRegistryService.hidePageVisibilitySettings("aicomponents");
        WinRegistryService.hidePageVisibilitySettings("privacy-systemaimodels");
        await runPSCommand(
          'Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart',
        );
        await runPSCommand(
          'Get-AppxPackage -AllUsers Microsoft.Copilot* | Remove-AppxPackage',
        );
      }
    } catch (e) {
      stderr.writeln('$tag $e');
    }
  }

  Future<void> _uninstallPackage(final WinPackageType packageType) async {
    stdout.writeln('$tag Uninstalling package: ${packageType.packageName}');

    if (packageType == WinPackageType.defenderRemoval) {
      await _securityService.enableDefender();
    }

    if (packageType == WinPackageType.aiRemoval) {
      WinRegistryService.unhidePageVisibilitySettings("aicomponents");
      WinRegistryService.unhidePageVisibilitySettings("privacy-systemaimodels");
      await runPSCommand(
        'Enable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart',
      );
      await _msStoreCommand.installPackage(
        id: "9nht9rb2f4hd",
        ring: "Retail",
        arch: "auto",
        downloadOnly: false,
      );
    }
    await _winPackageService.uninstallPackage(packageType);
  }
}
