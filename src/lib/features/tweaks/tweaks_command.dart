import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import 'performance/performance_service.dart';
import 'security/security_service.dart';
import 'updates/updates_service.dart';
import 'utilities/utilities_service.dart';

class TweaksCommand extends Command<void> {
  TweaksCommand() {
    addSubcommand(TweaksPatchesCommand());
    // Code-generated:
    addSubcommand(SecurityServiceCliCommand(const SecurityServiceImpl()));
    addSubcommand(PerformanceServiceCliCommand(const PerformanceServiceImpl()));
    addSubcommand(UtilitiesServiceCliCommand(const UtilitiesServiceImpl()));
    addSubcommand(UpdatesServiceCliCommand(const UpdatesServiceImpl()));
  }

  @override
  final String name = 'tweaks';

  @override
  final String description = 'Manage system tweaks by category';
}

class TweaksPatchesCommand extends Command<void> {
  @override
  String get name => 'patches';

  @override
  String get description => 'Apply main ReviOS playbook patches';

  @override
  FutureOr<void> run() async {
    logger.i('$name: Applying main playbook patch...');

    // Disable WebView2 spawning from SearchHost.
    // https://www.reddit.com/r/WindowsHelp/comments/1lfu325/comment/n2nk50h
    await WinRegistryService.writeRegistryValue(
      Registry.localMachine,
      r'SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides',
      '1694661260',
      0,
    );
    exit(0);
  }
}
