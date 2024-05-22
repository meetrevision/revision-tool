import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:revitool/services/security_service.dart';
import 'package:revitool/services/win_package_service.dart';

class WindowsPackageCommand extends Command<String> {
  static final _winPackageService = WinPackageService();
  static final _securityService = SecurityService();

  static const tag = "[Windows Package]";

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'winpackage';

  WindowsPackageCommand() {
    argParser.addOption(
      'install',
      help: 'Install a package',
      allowed: const ['system-components-removal', 'defender-removal'],
    );
    argParser.addOption(
      'uninstall',
      help: 'Uninstall a package',
      allowed: const ['system-components-removal', 'defender-removal'],
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
      await _winPackageService.downloadPackage(mode);

      stdout.writeln('$tag Installing package: ${mode.packageName}');
      await _winPackageService.installPackage(mode);
    } catch (e) {
      stderr.writeln('$tag $e');
    }
  }

  Future<void> _uninstallPackage(final WinPackageType packageType) async {
    stdout.writeln('$tag Uninstalling package: ${packageType.packageName}');
    if (packageType == WinPackageType.defenderRemoval) {
      await _securityService.enableDefender();
    }
    await _winPackageService.uninstallPackage(packageType);
  }
}
