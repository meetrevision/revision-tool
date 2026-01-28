import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../utils.dart';
import 'security_service.dart';

class SecurityCommand extends Command<String> {
  SecurityCommand() {
    argParser.addCommand('status');
    argParser.addCommand('enable').addCommand('--force');
    argParser.addCommand('disable').addCommand('--force');
  }
  String get tag => 'Security - Defender';

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'defender';

  @override
  FutureOr<String>? run() async {
    final isForce = argResults?.command?.command?.name == '--force';
    switch (argResults?.command?.name) {
      case 'enable':
        if (!isForce && const SecurityServiceImpl().statusDefender) {
          logger.i('$name: Windows Defender is already enabled');
          exit(0);
        }
        await const SecurityServiceImpl().enableDefender();
      case 'disable':
        await _disableDefender(isForce);
      default:
        logger.i(
          '$name: defender-status: ${const SecurityServiceImpl().statusDefender}\nVirus and Threat Protections Status: ${const SecurityServiceImpl().statusDefenderProtections}',
        );
    }
    exit(0);
  }

  Future<void> _disableDefender(bool isForce) async {
    if (!isForce && !const SecurityServiceImpl().statusDefender) {
      logger.i('$name: Windows Defender is already disabled');
      exit(0);
    }

    if (!isForce && !isProcessRunning('explorer.exe')) {
      logger.i('$name: Explorer.exe is not running. Starting Explorer...');
      await Process.run('explorer.exe', const []);
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    logger.i('$name: Checking if Virus and Threat Protections are enabled...');
    var count = 0;
    while (const SecurityServiceImpl().statusDefenderProtections) {
      if (count > 10) {
        logger.e('$name: Unable to disable Defender. Exiting...');
        exit(1);
      }

      if (!const SecurityServiceImpl().statusDefenderProtectionTamper) {
        await runPSCommand(
          r'Set-MpPreference -DisableRealtimeMonitoring $true',
        );
        break;
      }

      logger.i('$name: Please disable Realtime and Tamper Protections');
      await const SecurityServiceImpl().openDefenderThreatSettings();

      await Future<void>.delayed(const Duration(seconds: 7));
      count++;
    }
    await Process.run('taskkill', ['/f', '/im', 'SecHealthUI.exe']);

    try {
      await const SecurityServiceImpl().disableDefender();
    } on Exception catch (e) {
      logger.e(
        '$name: Error disabling Windows Defender: $e',
        error: e,
        stackTrace: StackTrace.current,
      );
      exit(1);
    }
  }
}
