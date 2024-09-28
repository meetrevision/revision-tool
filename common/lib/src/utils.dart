import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

final String mainPath = Platform.resolvedExecutable;
final String directoryExe = Directory(
        "${mainPath.substring(0, mainPath.lastIndexOf("\\"))}\\data\\flutter_assets\\additionals")
    .path;
final ameTemp =
    p.join(Directory.systemTemp.path, 'AME', 'Playbooks', 'Revision-ReviOS');

final tempReviPath = p.join(Directory.systemTemp.path, 'Revision-Tool', 'Logs');

final logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(),
  output: FileOutput(
    overrideExisting: true,
    file: File.fromUri(
      Uri(path: p.join(tempReviPath, 'log.txt')),
    ),
  ),
);
