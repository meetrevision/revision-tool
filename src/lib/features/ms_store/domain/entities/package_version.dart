import 'package_info.dart';

final class const PackageVersion(
  final int major,
  final int minor,
  final int build,
  final int revision,
) implements Comparable<PackageVersion> {
  static const _partCount = 4;

  static PackageVersion? tryParse(String version) {
    final List<int?> parts = version.trim().split('.').map(int.tryParse).toList();
    if (parts.length > _partCount || parts.contains(null)) return null;
    final List<int> padded = [...parts.nonNulls, for (var i = parts.length; i < _partCount; i++) 0];
    return PackageVersion(padded[0], padded[1], padded[2], padded[3]);
  }

  static PackageVersion? fromPackageName(String name) => switch (name.split('_')) {
    [_, final String version, ...] => tryParse(version),
    _ => null,
  };

  @override
  int compareTo(PackageVersion other) {
    for (final (mine, theirs) in [
      (major, other.major),
      (minor, other.minor),
      (build, other.build),
      (revision, other.revision),
    ]) {
      if (mine != theirs) return mine.compareTo(theirs);
    }
    return 0;
  }

  bool operator >(PackageVersion other) => compareTo(other) > 0;

  @override
  String toString() => '$major.$minor.$build.$revision';
}

PackageVersion? latestPackageVersion(Iterable<PackageInfo> packages, {required String familyName}) {
  if (familyName.toLowerCase().split('_') case [final name, final publisherId]) {
    PackageVersion? latest;
    for (final package in packages) {
      if (package.isDependency) continue;
      final String moniker = package.fileModel?.fileName?.toLowerCase() ?? '';
      if (moniker.split('_') case [final monikerName, _, ..., final monikerPublisher]
          when monikerName == name && monikerPublisher == publisherId) {
        final PackageVersion? version = PackageVersion.fromPackageName(moniker);
        if (version != null && (latest == null || version > latest)) latest = version;
      }
    }
    return latest;
  }
  return null;
}
