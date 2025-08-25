import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:revitool/core/security/security_service.dart';
import 'package:revitool/utils.dart';

class SecurityCommand extends Command<String> {
  static final _securityService = SecurityService();
  String get tag => "Security - Defender";

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'defender';

  SecurityCommand() {
    argParser.addCommand('status');
    argParser.addCommand('enable').addCommand("--force");
    argParser.addCommand('disable').addCommand("--force");
  }

  @override
  FutureOr<String>? run() async {
    final bool isForce = argResults?.command?.command?.name == '--force';
    switch (argResults?.command?.name) {
      case 'enable':
        if (!isForce && _securityService.statusDefender) {
          logger.i('$name: Windows Defender is already enabled');
          exit(0);
        }
        await _securityService.enableDefender();
        break;
      case 'disable':
        await _disableDefender(isForce);
        break;
      default:
        logger.i(
          '$name: defender-status: ${_securityService.statusDefender.toString()}\nVirus and Threat Protections Status: ${_securityService.statusDefenderProtections.toString()}',
        );
    }
    exit(0);
  }

  Future<void> _disableDefender(bool isForce) async {
    if (!isForce && !_securityService.statusDefender) {
      logger.i('$name: Windows Defender is already disabled');
      exit(0);
    }

    if (!isForce && !isProcessRunning('explorer.exe')) {
      logger.i('$name: Explorer.exe is not running. Starting Explorer...');
      await Process.run('explorer.exe', const []);
      await Future.delayed(const Duration(seconds: 5));
    }

    logger.i('$name: Checking if Virus and Threat Protections are enabled...');
    int count = 0;
    while (_securityService.statusDefenderProtections) {
      if (count > 10) {
        logger.e('$name: Unable to disable Defender. Exiting...');
        exit(1);
      }

      if (!_securityService.statusDefenderProtectionTamper) {
        await runPSCommand(
          'Set-MpPreference -DisableRealtimeMonitoring \$true',
        );
        break;
      }

      logger.i('$name: Please disable Realtime and Tamper Protections');
      await _securityService.openDefenderThreatSettings();

      await Future.delayed(const Duration(seconds: 7));
      count++;
    }
    await Process.run('taskkill', ['/f', '/im', 'SecHealthUI.exe']);

    try {
      await _securityService.disableDefender();
    } on Exception catch (e) {
      logger.e(
        '$name: Error disabling Windows Defender: ${e.toString()}',
        error: e,
        stackTrace: StackTrace.current,
      );
      exit(1);
    }
  }
}
