import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/winsxs/win_package_service.dart';

void main() {
  group('WinPackageService package versions', () {
    test('parses the version after the final double separator', () {
      expect(
        WinPackageService.parsePackageVersion(
          'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~1.0.0.0',
        ),
        equals((1, 0, 0, 0)),
      );
    });

    test('rejects package names without a four-part version', () {
      expect(
        WinPackageService.parsePackageVersion(
          'Revision-ReviOS-AI-Removal~31bf3856ad364e35~amd64~~1.0',
        ),
        isNull,
      );
    });

    test('compares version components numerically', () {
      expect(WinPackageService.comparePackageVersions((1, 10, 0, 0), (1, 2, 0, 0)), greaterThan(0));
      expect(WinPackageService.comparePackageVersions((1, 0, 0, 0), (1, 0, 0, 0)), equals(0));
    });
  });
}
