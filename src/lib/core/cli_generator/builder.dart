import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/cli_command_generator.dart';

Builder cliCommandBuilder(BuilderOptions options) {
  return SharedPartBuilder([CliCommandGenerator()], 'cli_command_builder');
}
