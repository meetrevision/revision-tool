import 'dart:typed_data';

extension IntBytes on int {
  static const _units = [
    [75, 66], // KB
    [77, 66], // MB
    [71, 66], // GB
    [84, 66], // TB
    [80, 66], // PB
  ];

  String formatBytes() {
    if (this < 1024) return '$this B';

    final buffer = Uint8List(10);
    int tier = (bitLength - 1) ~/ 10;
    if (tier > 5) tier = 5;

    final int shift = tier * 10;
    final int divisor = 1 << shift;
    int whole = this >> shift;
    int frac = ((this & (divisor - 1)) * 10 + (divisor >> 1)) >> shift;
    if (frac == 10) {
      whole++;
      frac = 0;
    }

    var p = 0;
    if (whole >= 1000) {
      buffer[p++] = 48 + (whole ~/ 1000);
      whole %= 1000;
    }
    if (whole >= 100) {
      buffer[p++] = 48 + (whole ~/ 100);
      whole %= 100;
    }
    if (whole >= 10) {
      buffer[p++] = 48 + (whole ~/ 10);
      whole %= 10;
    }
    buffer[p++] = 48 + whole;
    buffer[p++] = 46;
    buffer[p++] = 48 + frac;
    buffer[p++] = 32;
    buffer[p++] = _units[tier - 1][0];
    buffer[p++] = _units[tier - 1][1];

    return .fromCharCodes(buffer, 0, p);
  }

  int clampBytes(int total) => total > 0 && this > total ? total : this;
}
