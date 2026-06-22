enum StoreAppType {
  uwp(prefix: '9', installCommand: 'Add-AppxPackage'),
  win32(prefix: 'XP');

  const StoreAppType({required this.prefix, this.installCommand});
  final String prefix;
  final String? installCommand;

  static StoreAppType? fromProductId(String productId) {
    final String id = productId.toUpperCase();
    if (id.startsWith(uwp.prefix)) return uwp;
    if (id.startsWith(win32.prefix)) return win32;
    return null;
  }
}

/// Release ring/channel for package updates
enum StoreRing {
  retail(value: 'Retail', label: 'Retail (Base)'),
  releasePreview(value: 'RP', label: 'Release Preview'),
  insiderSlow(value: 'WIS', label: 'Insider Slow'),
  insiderFast(value: 'WIF', label: 'Insider Fast');

  const StoreRing({required this.value, required this.label});
  final String value;
  final String label;
}

/// CPU architecture for package filtering
enum StoreArch {
  auto(value: 'auto', label: 'Auto-detect'),
  x64(value: 'x64', label: 'x64'),
  arm64(value: 'arm64', label: 'ARM64'),
  all(value: 'all', label: 'All architectures');

  const StoreArch({required this.value, required this.label});
  final String value;
  final String label;
}
