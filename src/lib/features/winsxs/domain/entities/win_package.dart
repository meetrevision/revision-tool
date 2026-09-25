import 'package:fast_immutable_collections/fast_immutable_collections.dart';

enum WinPackageType({required final String packageName, required final String cliKey}) {
  systemComponentsRemoval(
    packageName: 'Revision-ReviOS-SystemPackages-Removal',
    cliKey: 'system-components-removal',
  ),
  defenderRemoval(packageName: 'Revision-ReviOS-Defender-Removal', cliKey: 'defender-removal'),
  aiRemoval(packageName: 'Revision-ReviOS-AI-Removal', cliKey: 'ai-removal'),
  oneDriveRemoval(packageName: 'Revision-ReviOS-OneDrive-Removal', cliKey: 'onedrive-removal'),
  xboxRemoval(packageName: 'Revision-ReviOS-Xbox-Removal', cliKey: 'xbox-removal');

  static WinPackageType byCliKey(String key) {
    return WinPackageType.values.firstWhere(
      (e) => e.cliKey == key,
      orElse: () => throw ArgumentError('Invalid CLI key: $key'),
    );
  }
}

typedef WinPackageVersion = (int, int, int, int);

/// Public key token shared by every ReviOS WinSxS removal package name.
const String winPackagePublicKeyToken = '31bf3856ad364e35';

final class const CabAsset({required final String name, required final String downloadUrl});

final class const WinPackageRelease({
  required final String tagName,
  required final IList<CabAsset> assets,
});

final class const DownloadedPackage({
  required final String path,
  required final WinPackageVersion version,
});

/// Matches the version suffix of both installed CBS package names (`~~1.2.3.4`)
/// and cab file names (`~1.2.3.4`), capturing the four version components.
final RegExp _versionSuffixPattern = RegExp(r'~{1,2}(\d+\.\d+\.\d+\.\d+)$');

WinPackageVersion? parsePackageVersion(String packageName) {
  final RegExpMatch? match = _versionSuffixPattern.firstMatch(packageName.trim());
  if (match?.group(1) case final version?) {
    final IList<int> parts = version.split('.').map(int.parse).toIList();
    return (parts[0], parts[1], parts[2], parts[3]);
  }
  return null;
}

int comparePackageVersions(WinPackageVersion left, WinPackageVersion right) {
  for (final (leftPart, rightPart) in [
    (left.$1, right.$1),
    (left.$2, right.$2),
    (left.$3, right.$3),
    (left.$4, right.$4),
  ]) {
    final int result = leftPart.compareTo(rightPart);
    if (result != 0) return result;
  }
  return 0;
}
