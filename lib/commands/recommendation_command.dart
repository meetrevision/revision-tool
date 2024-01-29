import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:revitool/services/miscellaneous_service.dart';
import 'package:revitool/services/performance_service.dart';
import 'package:revitool/services/security_service.dart';
import 'package:revitool/services/updates_service.dart';
import 'package:revitool/services/usability_service.dart';

class RecommendationCommand extends Command<String> {
  RecommendationCommand() {
    argParser.addOption(
      'mode',
      defaultsTo: 'all',
      allowed: const [
        'all',
        'security',
        'performance',
        'usability',
        'updates',
        'misc',
      ],
      help: 'Applies Revision\'s recommended tweaks (default in ReviOS)',
    );
  }

  @override
  String get description =>
      "Applies Revision's recommended tweaks (default in ReviOS)";

  @override
  String get name => "recommendation";

  @override
  FutureOr<String>? run() {
    final mode = argResults?["mode"];
    switch (mode) {
      case 'all':
        stdout.writeln('[Recommendation] Applying all recommendations...');
        SecurityService().recommendation();
        PerformanceService().recommendation();
        UsabilityService().recommendation();
        UpdatesService().recommendation();
        MiscellaneousService().recommendation();
        break;
      case 'security':
        stdout.writeln('[Recommendation] Applying security recommendations...');
        SecurityService().recommendation();
        break;
      case 'performance':
        stdout.writeln(
            '[Recommendation] Applying performance recommendations...');
        PerformanceService().recommendation();
        break;
      case 'usability':
        stdout
            .writeln('[Recommendation] Applying usability recommendations...');
        UsabilityService().recommendation();
        break;
      case 'updates':
        stdout.writeln('[Recommendation] Applying updates recommendations...');
        UpdatesService().recommendation();
        break;
      case 'misc':
        stdout.writeln(
            '[Recommendation] Applying miscellaneous recommendations...');
        MiscellaneousService().recommendation();
        break;
      // Add other cases for other recommendations...
      default:
        stderr.writeln('[Recommendation] Invalid recommendation specified.');
        exit(1);
    }
    exit(0);
  }
}
