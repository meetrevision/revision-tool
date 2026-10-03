/// Native bridge for AppX package management.
///
/// Exposes package query, removal, and deprovisioning operations through
/// domain types without leaking WinRT primitives.
library;

export 'src/rust/api/appx.dart';
export 'src/rust/frb_generated.dart' show RustLib;
