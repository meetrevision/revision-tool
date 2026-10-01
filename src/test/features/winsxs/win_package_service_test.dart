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
      final model = ReleaseModel.fromJson(<String, dynamic>{
        'tag_name': '10.0.26200.6725',
        'assets': [
          {
            'name': 'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab',
            'browser_download_url': 'https://example.com/ai.cab',
          },
        ],
      });

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

  group('WinSxS asset matching', () {
    test('selects the dot-named cab for ai-removal on amd64', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.3.1.0.cab',
          .aiRemoval,
          'amd64',
        ),
        isTrue,
      );
    });

    test('rejects the txt checksum beside the cab', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.3.1.0.txt',
          .aiRemoval,
          'amd64',
        ),
        isFalse,
      );
    });

    test('rejects other architectures and packages', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal.31bf3856ad364e35.arm64.2.3.1.0.cab',
          .aiRemoval,
          'amd64',
        ),
        isFalse,
      );
      expect(
        isWinPackageFile(
          'Revision-ReviOS-Defender-Removal.31bf3856ad364e35.amd64.2.3.1.0.cab',
          .aiRemoval,
          'amd64',
        ),
        isFalse,
      );
    });

    test('keeps accepting legacy tilde-named cabs', () {
      expect(
        isWinPackageFile(
          'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~10.0.26200.6725.cab',
          .aiRemoval,
          'amd64',
        ),
        isTrue,
      );
    });

    test('parses versions from dot-named bundled files', () {
      expect(
        parsePackageVersion('Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.3.1.0'),
        equals((2, 3, 1, 0)),
      );
    });
  });
}
