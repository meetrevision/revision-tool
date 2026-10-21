import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/services/win32_crypto_helper.dart';

void main() {
  group('Win32CryptoHelper.getEnhancedKeyUsages', () {
    test('returns empty list for non-existent file', () {
      final List<String> usages = Win32CryptoHelper.getEnhancedKeyUsages(
        r'C:\nonexistent\file.cab',
      );
      expect(usages, isEmpty);
    });

    test('returns empty list for unsigned file', () {
      final Directory tempDir = Directory.systemTemp.createTempSync('crypto_test');
      final tempFile = File('${tempDir.path}\\unsigned.bin')
        ..writeAsStringSync('not a signed file');
      try {
        final List<String> usages = Win32CryptoHelper.getEnhancedKeyUsages(tempFile.path);
        expect(usages, isEmpty);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('extracts OID from signed CAB if present in temp', () {
      final cabFile = File(
        r'C:\Users\User\AppData\Local\Temp\Revision-Tool\CAB\Revision-ReviOS-AI-Removal.31bf3856ad364e35.amd64.2.4.0.0.cab',
      );
      if (cabFile.existsSync()) {
        final List<String> usages = Win32CryptoHelper.getEnhancedKeyUsages(cabFile.path);
        expect(usages, contains('1.3.6.1.4.1.311.10.3.6'));
      }
    });
  });
}
