import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/features/ms_store/data/models/uwp/uwp_package.dart';
import 'package:revitool/features/ms_store/domain/entities/package_info.dart';
import 'package:revitool/features/ms_store/domain/entities/package_version.dart';

const String _family = 'Microsoft.WindowsCalculator_8wekyb3d8bbwe';

Matcher _isVersion(String version) =>
    isA<PackageVersion>().having((v) => v.toString(), 'version', version);

PackageInfo _package(String moniker, {bool isDependency = false}) => PackageInfo(
  id: moniker,
  isDependency: isDependency,
  uri: '',
  arch: 'x64',
  fileModel: FileModel(fileName: moniker),
);

void main() {
  group('PackageVersion', () {
    test('parses four parts', () {
      expect(PackageVersion.tryParse('11.2210.0.0'), _isVersion('11.2210.0.0'));
    });

    test('pads missing parts with zero', () {
      expect(PackageVersion.tryParse('1.2'), _isVersion('1.2.0.0'));
    });

    test('rejects text that is not a version', () {
      expect(PackageVersion.tryParse(''), isNull);
      expect(PackageVersion.tryParse('1.x.0.0'), isNull);
      expect(PackageVersion.tryParse('1.2.3.4.5'), isNull);
    });

    test('compares parts as numbers, not text', () {
      const newer = PackageVersion(1, 10, 0, 0);
      const older = PackageVersion(1, 9, 0, 0);

      expect(newer.compareTo(older), greaterThan(0));
      expect(older.compareTo(newer), lessThan(0));
      expect(PackageVersion.tryParse('2.0'), _isVersion('2.0.0.0'));
    });

    test('reads the version from a package full name', () {
      expect(
        PackageVersion.fromPackageName(
          'Microsoft.WindowsCalculator_11.2210.0.0_x64__8wekyb3d8bbwe',
        ),
        _isVersion('11.2210.0.0'),
      );
      expect(PackageVersion.fromPackageName('NoVersionHere'), isNull);
    });
  });

  group('latestPackageVersion', () {
    test('picks the newest main package of the family', () {
      final PackageVersion? latest = latestPackageVersion([
        _package('Microsoft.WindowsCalculator_11.2210.0.0_x64__8wekyb3d8bbwe'),
        _package('Microsoft.WindowsCalculator_11.2405.2.0_neutral_~_8wekyb3d8bbwe'),
      ], familyName: _family);

      expect(latest, _isVersion('11.2405.2.0'));
    });

    test('ignores dependencies and other families', () {
      final PackageVersion? latest = latestPackageVersion([
        _package(
          'Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe',
          isDependency: true,
        ),
        _package('Microsoft.WindowsNotepad_11.2409.9.0_x64__8wekyb3d8bbwe'),
        _package('Microsoft.WindowsCalculator_11.2210.0.0_x64__8wekyb3d8bbwe'),
      ], familyName: _family);

      expect(latest, _isVersion('11.2210.0.0'));
    });

    test('matches the family regardless of case', () {
      final PackageVersion? latest = latestPackageVersion([
        _package('microsoft.windowscalculator_11.2210.0.0_x64__8WEKYB3D8BBWE'),
      ], familyName: _family);

      expect(latest, isNotNull);
    });

    test('returns null when no package belongs to the family', () {
      expect(
        latestPackageVersion([
          _package('Microsoft.WindowsNotepad_11.2409.9.0_x64__8wekyb3d8bbwe'),
        ], familyName: _family),
        isNull,
      );
    });
  });
}
