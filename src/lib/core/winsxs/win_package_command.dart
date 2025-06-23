import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/core/ms_store/ms_store_command.dart';
import 'package:revitool/core/security/security_service.dart';
import 'package:revitool/core/winsxs/win_package_service.dart';
import 'package:revitool/shared/win_registry_service.dart';

class WindowsPackageCommand extends Command<String> {
  static final _winPackageService = WinPackageService();
  static final _msStoreCommand = MSStoreCommand();
  static final _securityService = SecurityService();
  static final _shell = Shell();

  static const tag = "[Windows Package]";

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'winpackage';

  WindowsPackageCommand() {
    argParser.addOption(
      'install',
      help: 'Install a package',
      allowed: const [
        'system-components-removal',
        'defender-removal',
        'ai-removal',
      ],
    );
    argParser.addOption(
      'uninstall',
      help: 'Uninstall a package',
      allowed: const [
        'system-components-removal',
        'defender-removal',
        'ai-removal',
      ],
    );
  }

  @override
  FutureOr<String>? run() async {
    final installOption = argResults?.option('install');
    final uninstallOption = argResults?.option('uninstall');

    if (installOption != null) {
      await _installPackage(installOption);
    } else if (uninstallOption != null) {
      await _uninstallPackage(getPackageType(uninstallOption));
    } else {
      stderr.writeln('$tag Invalid command');
    }
    exit(0);
  }

  WinPackageType getPackageType(final String package) {
    switch (package) {
      case 'system-components-removal':
        return WinPackageType.systemComponentsRemoval;
      case 'defender-removal':
        return WinPackageType.defenderRemoval;
      case 'ai-removal':
        return WinPackageType.aiRemoval;
      default:
        throw Exception('Invalid package: $package');
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
        await _shell.run(
          'PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP -C "Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart"',
        );
        await _shell.run(
          'PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP -C "Get-AppxPackage -AllUsers Microsoft.Copilot* | Remove-AppxPackage"',
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
      await _shell.run(
        'PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP -C "Enable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart"',
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
