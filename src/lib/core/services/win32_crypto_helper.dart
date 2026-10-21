// ignore_for_file: camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

base class CERT_ENHKEY_USAGE() extends Struct {
  @Uint32()
  external int cUsageIdentifier;
  external Pointer<Pointer<Utf8>> rgpszUsageIdentifier;
}

/// Native Win32 CryptoAPI wrapper for verifying embedded Authenticode signatures and EKUs.
abstract final class Win32CryptoHelper() {
  static final DynamicLibrary _crypt32 = DynamicLibrary.open('crypt32.dll');

  static final int Function(
    int dwObjectType,
    Pointer<Utf16> pvObject,
    int dwExpectedContentTypeFlags,
    int dwExpectedFormatTypeFlags,
    int dwFlags,
    Pointer<Uint32> pdwMsgAndCertEncodingType,
    Pointer<Uint32> pdwContentType,
    Pointer<Uint32> pdwFormatType,
    Pointer<IntPtr> phCertStore,
    Pointer<IntPtr> phMsg,
    Pointer<Pointer> ppvContext,
  )
  _cryptQueryObject = _crypt32
      .lookupFunction<
        Int32 Function(
          Uint32,
          Pointer<Utf16>,
          Uint32,
          Uint32,
          Uint32,
          Pointer<Uint32>,
          Pointer<Uint32>,
          Pointer<Uint32>,
          Pointer<IntPtr>,
          Pointer<IntPtr>,
          Pointer<Pointer>,
        ),
        int Function(
          int,
          Pointer<Utf16>,
          int,
          int,
          int,
          Pointer<Uint32>,
          Pointer<Uint32>,
          Pointer<Uint32>,
          Pointer<IntPtr>,
          Pointer<IntPtr>,
          Pointer<Pointer>,
        )
      >('CryptQueryObject');

  static final Pointer Function(int hCertStore, Pointer pPrevCertContext)
  _certEnumCertificatesInStore = _crypt32
      .lookupFunction<Pointer Function(IntPtr, Pointer), Pointer Function(int, Pointer)>(
        'CertEnumCertificatesInStore',
      );

  static final int Function(
    Pointer pCertContext,
    int dwFlags,
    Pointer pUsage,
    Pointer<Uint32> pcbUsage,
  )
  _certGetEnhancedKeyUsage = _crypt32
      .lookupFunction<
        Int32 Function(Pointer, Uint32, Pointer, Pointer<Uint32>),
        int Function(Pointer, int, Pointer, Pointer<Uint32>)
      >('CertGetEnhancedKeyUsage');

  static final int Function(Pointer pCertContext) _certFreeCertificateContext = _crypt32
      .lookupFunction<Int32 Function(Pointer), int Function(Pointer)>('CertFreeCertificateContext');

  static final int Function(int hCertStore, int dwFlags) _certCloseStore = _crypt32
      .lookupFunction<Int32 Function(IntPtr, Uint32), int Function(int, int)>('CertCloseStore');

  static final int Function(int hCryptMsg) _cryptMsgClose = _crypt32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CryptMsgClose');

  static const int _certQueryObjectFile = 1;
  static const int _certQueryContentFlagAll = 0x00003FFF;
  static const int _certQueryFormatFlagAll = 0x0000000E;

  /// Returns all enhanced key usage OIDs found on certificates embedded in [filePath].
  static List<String> getEnhancedKeyUsages(String filePath) => using((arena) {
    final Pointer<Utf16> path = filePath.toNativeUtf16(allocator: arena);
    final Pointer<IntPtr> phCertStore = arena<IntPtr>();
    final Pointer<IntPtr> phMsg = arena<IntPtr>();

    final int success = _cryptQueryObject(
      _certQueryObjectFile,
      path,
      _certQueryContentFlagAll,
      _certQueryFormatFlagAll,
      0,
      nullptr,
      nullptr,
      nullptr,
      phCertStore,
      phMsg,
      nullptr,
    );

    if (success == 0) return const <String>[];

    final usages = <String>[];
    Pointer pCert = nullptr;
    try {
      if (phCertStore.value != 0) {
        while (true) {
          pCert = _certEnumCertificatesInStore(phCertStore.value, pCert);
          if (pCert == nullptr) break;

          final Pointer<Uint32> pcbUsage = arena<Uint32>();
          _certGetEnhancedKeyUsage(pCert, 0, nullptr, pcbUsage);
          if (pcbUsage.value > 0) {
            final Pointer<Uint8> pUsage = arena<Uint8>(pcbUsage.value);
            if (_certGetEnhancedKeyUsage(pCert, 0, pUsage, pcbUsage) != 0) {
              final CERT_ENHKEY_USAGE usage = pUsage.cast<CERT_ENHKEY_USAGE>().ref;
              for (var i = 0; i < usage.cUsageIdentifier; i++) {
                final Pointer<Utf8> oidPtr = (usage.rgpszUsageIdentifier + i).value;
                if (oidPtr != nullptr) {
                  usages.add(oidPtr.toDartString());
                }
              }
            }
          }
        }
      }
    } catch (_) {
      if (pCert != nullptr) {
        _certFreeCertificateContext(pCert);
      }
      rethrow;
    } finally {
      if (phCertStore.value != 0) _certCloseStore(phCertStore.value, 0);
      if (phMsg.value != 0) _cryptMsgClose(phMsg.value);
    }
    return usages;
  });
}
