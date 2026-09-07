import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/package_info.dart';
import '../../domain/entities/product_details.dart';

final storeCacheProvider = Provider<StoreCache>((ref) => StoreCache());

final class const _PackageCacheEntry({
  required final ISet<PackageInfo> packages,
  required final DateTime expiryDate,
}) {
  bool get isExpired => DateTime.now().isAfter(expiryDate);
}

final class StoreCache() {
  final _details = <String, ProductDetails>{};
  final _packages = <String, _PackageCacheEntry>{};

  static const _maxCacheLength = 64;

  ProductDetails? getDetails(String key) => _details[key];

  void putDetails(String key, ProductDetails value) {
    if (_details.length >= _maxCacheLength) {
      _details.remove(_details.keys.first);
    }
    _details[key] = value;
  }

  /// Returns the cached immutable set directly. ISet is already immutable and
  /// value-equal, so no defensive [Set.unmodifiable] wrapper (O(n)) is needed.
  ISet<PackageInfo>? getPackages(String key) {
    final _PackageCacheEntry? entry = _packages.remove(key);
    if (entry == null) return null;
    if (entry.isExpired) return null;
    _packages[key] = entry;
    return entry.packages;
  }

  void putPackages(String key, ISet<PackageInfo> packages, DateTime expiry) {
    if (_packages.length >= _maxCacheLength) {
      _packages.remove(_packages.keys.first);
    }

    if (!expiry.isAfter(.now())) return;

    _packages[key] = _PackageCacheEntry(packages: packages, expiryDate: expiry);
  }

  void clear() {
    _details.clear();
    _packages.clear();
  }
}
