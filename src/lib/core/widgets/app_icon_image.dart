import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win32/win32.dart';

/// Our exe icon bytes, preloaded in main() and shared by every consumer.
final Provider<Uint8List?> appIconProvider = Provider<Uint8List?>((ref) => findExeIconPng());

/// Reads the largest PNG icon from our own executable resources.
///
/// Windows stores each ICO entry as an RT_ICON resource, and PNG entries
/// keep their exact bytes. The result feeds [Image.memory], so no image
/// asset is bundled. It returns null outside Windows or when no PNG entry
/// exists.
Uint8List? findExeIconPng() {
  if (!Platform.isWindows) return null;
  try {
    final HMODULE hModule = GetModuleHandle(null).value;
    if (!hModule.isValid) return null;

    Uint8List? best;
    var bestArea = 0;
    for (var id = 1; id <= 256; id++) {
      final Uint8List? bytes = _pngResourceBytes(hModule, id);
      if (bytes == null) continue;
      final ({int width, int height})? dimensions = pngDimensions(bytes);
      if (dimensions == null) continue;
      if (dimensions.width * dimensions.height > bestArea) {
        bestArea = dimensions.width * dimensions.height;
        best = bytes;
      }
    }
    return best;
  } catch (_) {
    return null;
  }
}

/// Reads one RT_ICON resource as PNG bytes. Null when missing or not a PNG.
Uint8List? _pngResourceBytes(HMODULE module, int id) {
  final HRSRC hRes = FindResource(
    module,
    PCWSTR(.fromAddress(id)),
    PCWSTR(.fromAddress(3)), // RT_ICON
  );
  if (!hRes.isValid) return null;

  final int size = SizeofResource(module, hRes).value;
  if (size < 33) return null;

  final HGLOBAL hGlobal = LoadResource(module, hRes).value;
  if (!hGlobal.isValid) return null;

  final Pointer<Uint8> data = LockResource(hGlobal).cast<Uint8>();
  if (data == nullptr) return null;

  final Uint8List bytes = data.asTypedList(size);
  if (pngDimensions(bytes) == null) return null;
  return .fromList(bytes);
}

const _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// Reads width and height from PNG IHDR bytes. Null when not a PNG.
({int width, int height})? pngDimensions(Uint8List bytes) {
  if (bytes.length < 33) return null;
  for (var k = 0; k < 8; k++) {
    if (bytes[k] != _pngMagic[k]) return null;
  }
  final view = ByteData.sublistView(bytes);
  return (width: view.getUint32(16), height: view.getUint32(20));
}

/// Shows our exe icon, falling back when unavailable.
final class const AppIconImage({
  super.key,
  required final double size,
  required final Widget fallback,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? bytes = ref.watch(appIconProvider);
    if (bytes == null) return fallback;
    return Image.memory(bytes, width: size, height: size, filterQuality: .high);
  }
}
