enum MSStoreAppType {
  uwp(prefix: '9', installCommand: 'Add-AppxPackage'),
  win32(prefix: 'XP');

  const MSStoreAppType({required this.prefix, this.installCommand});
  final String prefix;
  final String? installCommand;

  static MSStoreAppType? fromProductId(String productId) {
    final String id = productId.toUpperCase();
    if (id.startsWith(uwp.prefix)) return uwp;
    if (id.startsWith(win32.prefix)) return win32;
    return null;
  }
}

/// Release ring/channel for package updates
enum MSStoreRing {
  retail(value: 'Retail', label: 'Retail (Base)'),
  releasePreview(value: 'RP', label: 'Release Preview'),
  insiderSlow(value: 'WIS', label: 'Insider Slow'),
  insiderFast(value: 'WIF', label: 'Insider Fast');

  const MSStoreRing({required this.value, required this.label});
  final String value;
  final String label;
}

/// CPU architecture for package filtering
enum MSStoreArch {
  auto(value: 'auto', label: 'Auto-detect'),
  x64(value: 'x64', label: 'x64'),
  arm64(value: 'arm64', label: 'ARM64'),
  all(value: 'all', label: 'All architectures');

  const MSStoreArch({required this.value, required this.label});
  final String value;
  final String label;
}
