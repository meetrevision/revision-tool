import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final targetDir = Directory(
    _parseArg(args, '--output') ?? _parseArg(args, '-o') ?? 'additionals/packages/winsxs',
  );
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final String? token = Platform.environment['GH_TOKEN'] ?? Platform.environment['GITHUB_TOKEN'];
  stdout.writeln('Fetching latest packages from meetrevision/packages...');

  final client = HttpClient();
  try {
    final Uri uri = Uri.parse('https://api.github.com/repos/meetrevision/packages/releases/latest');
    final HttpClientRequest request = await client.getUrl(uri);
    request.headers.set(
      'User-Agent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0',
    );
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    if (token != null && token.isNotEmpty) {
      request.headers.set('Authorization', 'Bearer $token');
    }

    final HttpClientResponse response = await request.close();
    if (response.statusCode != 200) {
      final String body = await utf8.decodeStream(response);
      stderr.writeln('GitHub API failed (${response.statusCode}): $body');
      exit(1);
    }

    final json = jsonDecode(await utf8.decodeStream(response)) as Map<String, dynamic>;
    final List<Map<String, dynamic>> assets = (json['assets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .where((a) => (a['name'] as String).endsWith('.cab'))
        .toList();

    stdout.writeln('Found ${assets.length} packages to bundle.');

    for (final asset in assets) {
      final name = asset['name'] as String;
      final downloadUrl = asset['browser_download_url'] as String;
      final int size = asset['size'] as int? ?? 0;
      final destination = File('${targetDir.path}/$name');

      if (destination.existsSync() && destination.lengthSync() == size) {
        stdout.writeln('  Skipping $name (already up to date)');
        continue;
      }

      stdout.writeln('  Downloading $name...');
      final HttpClientRequest downloadReq = await client.getUrl(Uri.parse(downloadUrl));
      downloadReq.headers.set('User-Agent', 'Revitool-Build');
      if (token != null && token.isNotEmpty) {
        downloadReq.headers.set('Authorization', 'Bearer $token');
      }
      final HttpClientResponse downloadRes = await downloadReq.close();
      if (downloadRes.statusCode == 200) {
        final IOSink sink = destination.openWrite();
        await downloadRes.pipe(sink);
      } else {
        stderr.writeln('  Failed to download $name (${downloadRes.statusCode})');
      }
    }
    stdout.writeln('WinSxS bundling complete.');
  } finally {
    client.close();
  }
}

String? _parseArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1];
    if (args[i].startsWith('$name=')) return args[i].substring(name.length + 1);
  }
  return null;
}
