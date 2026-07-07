import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/settings/tool_update_service.dart';

void main() {
  group('ToolUpdateService', () {
    setUp(() {
      ToolUpdateService().data.clear();
    });

    test('compares semantic version segments numerically', () {
      final service = ToolUpdateService()
        ..data['tag_name'] = '24.10.1';

      expect(
        service.getLatestVersion,
        greaterThan(ToolUpdateService.versionComparableValue('24.9.30')),
      );
    });

    test('accepts release tag prefixes and suffixes', () {
      expect(
        ToolUpdateService.versionComparableValue('v2.10.0-beta.1'),
        ToolUpdateService.versionComparableValue('2.10.0'),
      );
    });

    test('selects the installer asset instead of the first release asset', () {
      final service = ToolUpdateService()
        ..data['assets'] = <Map<String, String>>[
          {
            'name': 'checksums.txt',
            'browser_download_url': 'https://example.test/checksums.txt',
          },
          {
            'name': 'RevisionTool-Setup.exe',
            'browser_download_url': 'https://example.test/setup.exe',
          },
        ];

      expect(
        service.installerAssetDownloadUrl,
        'https://example.test/setup.exe',
      );
    });
  });
}
