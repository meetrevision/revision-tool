import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:process_run/shell_run.dart';
import 'package:revitool/services/security_service.dart';
import 'package:revitool/utils.dart';

class DefenderCommand extends Command<String> {
  static final _securityService = SecurityService();
  static final _shell = Shell();
  String get tag => "[Security - Defender]";

  @override
  String get description => '[$tag] A command to manage Windows Defender';

  @override
  String get name => 'defender';

  DefenderCommand() {
    argParser.addCommand('status');
    argParser.addCommand('enable');
    argParser.addCommand('disable');
  }

  @override
  FutureOr<String>? run() async {
    switch (argResults?.command?.name) {
      case 'enable':
        if (_securityService.statusDefender) {
          stdout.writeln('$tag Windows Defender is already enabled');
          exit(0);
        }
        await _securityService.enableDefender();
        break;
      case 'disable':
        await _disableDefender();
        break;
      default:
        stdout.writeln('''
Defender Status: ${_securityService.statusDefender.toString()}
Virus and Threat Protections Status: ${_securityService.statusDefenderProtections.toString()}
''');
    }
    exit(0);
  }

  Future<void> _disableDefender() async {
    if (!_securityService.statusDefender) {
      stdout.writeln('$tag Windows Defender is already disabled');
      exit(0);
    }

    // TODO: Remove this whenever a new playbook gets released
    final isAMETempAvailable = await Directory(ameTemp).exists();
    if (isAMETempAvailable) {
      await Process.run('explorer.exe', const []);
      await Future.delayed(const Duration(seconds: 5));
    }
    //

    stdout.writeln('$tag Disabling Windows Defender...');

    stdout.writeln(
        '$tag Checking if Virus and Threat Protections are enabled...');

    while (_securityService.statusDefenderProtections) {
      if (!_securityService.statusDefenderProtectionTamper) {
        await _shell.run(
            'PowerShell -EP Unrestricted -NonInteractive -NoLogo -NoP Set-MpPreference -DisableRealtimeMonitoring \$true');
        continue;
      }

      stdout.writeln('$tag Please disable Realtime and Tamper Protections');
      await _securityService.openDefenderThreatSettings();

      await Future.delayed(const Duration(seconds: 7));
    }
    await Process.run('taskkill', ['/f', '/im', 'SecHealthUI.exe']);

    if (isAMETempAvailable) {
      await Process.run('taskkill', ['/f', '/im', 'explorer.exe']);
    }

    try {
      await _securityService.disableDefender();
    } catch (e) {
      stderr.writeln('$tag Error disabling Windows Defender: $e');
      exit(1);
    }
  }
}
