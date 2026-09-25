import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/winsxs/winsxs.dart';

void main() {
  group('win_package versions', () {
    test('parses the version after the final double separator', () {
      expect(
        parsePackageVersion('Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~1.0.0.0'),
        equals((1, 0, 0, 0)),
      );
    });

    test('rejects package names without a four-part version', () {
      expect(parsePackageVersion('Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~1.0'), isNull);
    });

    test('compares version components numerically', () {
      expect(comparePackageVersions((1, 10, 0, 0), (1, 2, 0, 0)), greaterThan(0));
      expect(comparePackageVersions((1, 0, 0, 0), (1, 0, 0, 0)), equals(0));
    });
  });

  group('ReleaseModel', () {
    test('maps the release payload to domain entities', () {
      final model = ReleaseModel.fromJson(
        <String, dynamic>{
          'tag_name': '10.0.26200.6725',
          'assets': [
            {
              'name': 'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab',
              'browser_download_url': 'https://example.com/ai.cab',
            },
          ],
        },
      );

      final WinPackageRelease release = model.toDomain();

      expect(release.tagName, equals('10.0.26200.6725'));
      expect(release.assets, hasLength(1));
      expect(
        release.assets.first.name,
        equals('Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab'),
      );
      expect(release.assets.first.downloadUrl, equals('https://example.com/ai.cab'));
    });
  });
}
