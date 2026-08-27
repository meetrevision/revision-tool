enum StoreAppType({required final String prefix, final String? installCommand}) {
  uwp(prefix: '9', installCommand: 'Add-AppxPackage'),
  win32(prefix: 'XP');

  static StoreAppType? fromProductId(String productId) {
    final String id = productId.toUpperCase();
    if (id.startsWith(uwp.prefix)) return uwp;
    if (id.startsWith(win32.prefix)) return win32;
    return null;
  }
}

/// Release ring/channel for package updates
enum StoreRing({required final String value, required final String label}) {
  retail(value: 'Retail', label: 'Retail (Base)'),
  releasePreview(value: 'RP', label: 'Release Preview'),
  insiderSlow(value: 'WIS', label: 'Insider Slow'),
  insiderFast(value: 'WIF', label: 'Insider Fast');

}

/// CPU architecture for package filtering
enum StoreArch({required final String value, required final String label}) {
  auto(value: 'auto', label: 'Auto-detect'),
  x64(value: 'x64', label: 'x64'),
  arm64(value: 'arm64', label: 'ARM64'),
  all(value: 'all', label: 'All architectures');

}
