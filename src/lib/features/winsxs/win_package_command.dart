import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:riverpod/riverpod.dart';

import '../../utils.dart';
import 'win_package_service.dart';

class WindowsPackageCommand extends Command<void> {
  WindowsPackageCommand({required this._container}) {
    final Set<String> allowedList = WinPackageType.values
        .map((e) => e.cliKey)
        .toSet();

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

  final ProviderContainer _container;

  static const tag = 'Windows Package';

  @override
  String get description => '[$tag] Manage ReviOS WinSxS removal packages';

  @override
  String get name => 'winpackage';

  @override
  FutureOr<void> run() async {
    final String? downloadOption = argResults?.option('download');
    final String? installOption = argResults?.option('install');
    final String? uninstallOption = argResults?.option('uninstall');
    final String? downloadPath = argResults?.option('download-path');

    final String? cliKey = downloadOption ?? installOption ?? uninstallOption;
    if (cliKey == null) {
      logger.e(
        '$name: No valid options provided. Use --help for usage information.',
      );
      exit(0);
    }

    final WinPackageType type = WinPackageType.byCliKey(cliKey);
    final WinPackageService service = _container.read(
      winPackageServiceProvider(type),
    );

    try {
      if (downloadOption != null) {
        stdout.writeln(await service.download(path: downloadPath));
      } else if (installOption != null) {
        await service.install();
      } else {
        await service.uninstall();
      }
    } catch (e) {
      logger.e(
        '$name: Operation failed for package=$cliKey',
        error: e,
        stackTrace: StackTrace.current,
      );
      exit(1);
    }
    exit(0);
  }
}
