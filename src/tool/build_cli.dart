import 'dart:io';

Future<void> main(List<String> args) async {
  final String version =
      _parseArg(args, '--version') ?? Platform.environment['APP_VERSION'] ?? '1.0.0';
  final String output = _parseArg(args, '--output') ?? _parseArg(args, '-o') ?? '../revitool.exe';
  final bool skipManifest = args.contains('--no-manifest');

  final outputFile = File(output);
  final Directory outputDir = outputFile.parent;
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  stdout.writeln('Building revitool CLI (v$version) -> ${outputFile.path}...');

  // 1. Build the AppX native bridge DLL via build hooks first (it cleans build/cli).
  stdout.writeln('Building native bridge DLL...');
  final ProcessResult bridgeBuildResult = await Process.run('dart', [
    'build',
    'cli',
    '-t',
    'lib/main_cli.dart',
    '-o',
    'build/cli',
  ]);
  if (bridgeBuildResult.exitCode != 0) {
    stderr.writeln(bridgeBuildResult.stderr);
    exit(bridgeBuildResult.exitCode);
  }

  // 2. Compile the executable with the APP_VERSION define.
  stdout.writeln('Compiling executable...');
  final ProcessResult compileResult = await Process.run('dart', [
    'compile',
    'exe',
    'lib/main_cli.dart',
    '-o',
    outputFile.path,
    '--define=APP_VERSION=$version',
  ]);
  if (compileResult.exitCode != 0) {
    stderr.writeln(compileResult.stderr);
    exit(compileResult.exitCode);
  }
  stdout.writeln('Compiled executable successfully.');

  // 3. Stage the native bridge DLL next to the compiled executable.
  final sourceDll = File('build/cli/bundle/lib/revitool_native.dll');
  if (sourceDll.existsSync()) {
    final targetDllPath = '${outputDir.path}/revitool_native.dll';
    sourceDll.copySync(targetDllPath);
    stdout.writeln('Staged native DLL -> $targetDllPath');
  } else {
    stderr.writeln('Warning: native DLL not found at ${sourceDll.path}');
  }

  // 4. On Windows, embed elevation manifest into executable using mt.exe.
  if (Platform.isWindows && !skipManifest) {
    final manifestFile = File('windows/app.manifest');
    if (manifestFile.existsSync()) {
      final String? mtPath = _findMtExe();
      if (mtPath != null) {
        stdout.writeln('Embedding UAC elevation manifest...');
        final ProcessResult mtResult = await Process.run(mtPath, [
          '-nologo',
          '-manifest',
          manifestFile.path,
          '-outputresource:${outputFile.path};1',
        ]);
        if (mtResult.exitCode != 0) {
          stderr.writeln('Warning: mt.exe failed: ${mtResult.stderr}');
        } else {
          stdout.writeln('Manifest embedded successfully.');
        }
      } else {
        stdout.writeln('mt.exe not found in Windows Kits; skipping manifest embedding.');
      }
    }
  }

  stdout.writeln('CLI build complete.');
}

String? _parseArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$name=')) return args[i].substring(name.length + 1);
  }
  return null;
}

String? _findMtExe() {
  final String programFilesX86 =
      Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
  final kitsDir = Directory('$programFilesX86/Windows Kits/10/bin');
  if (!kitsDir.existsSync()) return null;

  final List<Directory> candidates = kitsDir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => b.path.compareTo(a.path));

  for (final dir in candidates) {
    final x64Mt = File('${dir.path}/x64/mt.exe');
    if (x64Mt.existsSync()) return x64Mt.path;
  }
  return null;
}
