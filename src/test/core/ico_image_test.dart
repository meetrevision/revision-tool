import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/widgets/app_icon_image.dart';

const _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

void main() {
  test('parses PNG dimensions from the real icon entry', () {
    final Uint8List ico = File(
      'windows/runner/resources/app_icon.ico',
    ).readAsBytesSync();
    var start = -1;
    for (var i = 0; i + 8 <= ico.length; i++) {
      var match = true;
      for (var k = 0; k < 8; k++) {
        if (ico[i + k] != _pngMagic[k]) {
          match = false;
          break;
        }
      }
      if (match) {
        start = i;
        break;
      }
    }
    expect(start, greaterThanOrEqualTo(0));
    final ({int width, int height})? dimensions = pngDimensions(ico.sublist(start));
    expect(dimensions, isNotNull);
    expect(dimensions!.width, 256);
    expect(dimensions.height, 256);
  });

  test('returns null for malformed input', () {
    expect(pngDimensions(Uint8List(0)), isNull);
    expect(pngDimensions(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
