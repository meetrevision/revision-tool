import 'package:riverpod/riverpod.dart';

import '../models/package_info.dart';
import '../models/product_details/product_details.dart';

final storeCacheProvider = Provider<StoreCache>((ref) => StoreCache());

final class _PackageCacheEntry {
  const _PackageCacheEntry({required this.packages, required this.expiryDate});

  final Set<PackageInfo> packages;
  final DateTime expiryDate;

  bool get isExpired => DateTime.now().isAfter(expiryDate);
}

final class StoreCache {
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

  Set<PackageInfo>? getPackages(String key) {
    final _PackageCacheEntry? entry = _packages.remove(key);
    if (entry == null) return null;
    if (entry.isExpired) return null;
    _packages[key] = entry;
    return .unmodifiable(entry.packages);
  }

  void putPackages(String key, Set<PackageInfo> packages, DateTime expiry) {
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
