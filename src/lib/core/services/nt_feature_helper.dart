import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../utils.dart';
import '../trusted_installer/trusted_installer_service.dart';

/// Native structure for `RTL_FEATURE_CONFIGURATION_UPDATE` in `ntdll.dll`.
///
/// Layout in memory (all 32-bit uints, 32 bytes total):
/// - `FeatureId`: uint32
/// - `Priority`: uint32 (8 = User)
/// - `EnabledState`: uint32 (0 = Default, 1 = Disabled, 2 = Enabled)
/// - `EnabledStateOptions`: uint32 (0 = None, 1 = WexpConfig)
/// - `Variant`: uint32
/// - `VariantPayloadKind`: uint32
/// - `VariantPayload`: uint32
/// - `Operation`: uint32 (1 = FeatureState, 2 = VariantState, 3 = Both, 4 = ResetState)
final class RtlFeatureConfigurationUpdate() extends Struct {
  @Uint32()
  external int featureId;

  @Uint32()
  external int priority;

  @Uint32()
  external int enabledState;

  @Uint32()
  external int enabledStateOptions;

  @Uint32()
  external int variant;

  @Uint32()
  external int variantPayloadKind;

  @Uint32()
  external int variantPayload;

  @Uint32()
  external int operation;
}

/// Native structure for `RTL_FEATURE_CONFIGURATION` in `ntdll.dll`.
final class RtlFeatureConfiguration() extends Struct {
  @Uint32()
  external int featureId;

  @Uint32()
  external int compactState;

  @Uint32()
  external int variantPayload;
}

typedef _RtlSetFeatureConfigurationsNative = Int32 Function(
  Pointer<Uint64> previousChangeStamp,
  Uint32 configurationType,
  Pointer<RtlFeatureConfigurationUpdate> featureConfigurations,
  Uint32 featureConfigurationCount,
);

typedef _RtlSetFeatureConfigurationsDart = int Function(
  Pointer<Uint64> previousChangeStamp,
  int configurationType,
  Pointer<RtlFeatureConfigurationUpdate> featureConfigurations,
  int featureConfigurationCount,
);

typedef _RtlQueryFeatureConfigurationNative = Int32 Function(
  Uint32 featureId,
  Uint32 configurationType,
  Pointer<Uint64> changeStamp,
  Pointer<RtlFeatureConfiguration> featureConfiguration,
);

typedef _RtlQueryFeatureConfigurationDart = int Function(
  int featureId,
  int configurationType,
  Pointer<Uint64> changeStamp,
  Pointer<RtlFeatureConfiguration> featureConfiguration,
);

typedef _RtlGetSystemBootStatusNative = Int32 Function(
  Uint32 bsdItemType,
  Pointer<Int32> data,
  Uint32 dataLength,
  Pointer<Uint32> returnLength,
);

typedef _RtlGetSystemBootStatusDart = int Function(
  int bsdItemType,
  Pointer<Int32> data,
  int dataLength,
  Pointer<Uint32> returnLength,
);

typedef _RtlSetSystemBootStatusNative = Int32 Function(
  Uint32 bsdItemType,
  Pointer<Int32> data,
  Uint32 dataLength,
  Pointer<Uint32> returnLength,
);

typedef _RtlSetSystemBootStatusDart = int Function(
  int bsdItemType,
  Pointer<Int32> data,
  int dataLength,
  Pointer<Uint32> returnLength,
);

typedef _RtlCreateBootStatusDataFileNative = Int32 Function(Pointer<Utf16> bootStatusPath);

typedef _RtlCreateBootStatusDataFileDart = int Function(Pointer<Utf16> bootStatusPath);

/// Helper for Windows NT feature management APIs exported by `ntdll.dll`.
///
/// Handles runtime in-memory feature state updates (`RtlSetFeatureConfigurations`)
/// and boot-time pending flags (`RtlSetSystemBootStatus`), matching Windows NT ABI.
final class NtFeatureHelper() {
  static const int priorityUser = 8;

  static const int enabledStateDefault = 0;
  static const int enabledStateDisabled = 1;
  static const int enabledStateEnabled = 2;

  static const int operationFeatureState = 1;
  static const int operationVariantState = 2;
  static const int operationResetState = 4;

  static const int storeTypeBoot = 0;
  static const int storeTypeRuntime = 1;

  static const int bsdItemFeatureConfigurationState = 17;
  static const int bsdStateBootPending = 1;

  static const int statusSuccess = 0;
  static const int statusAccessDenied = 0xC0000022;
  static const int statusObjectNameNotFound = 0xC0000034;

  static final DynamicLibrary? _ntdll = () {
    try {
      return DynamicLibrary.open('ntdll.dll');
    } catch (e, st) {
      logger.w('NtFeatureHelper: Failed to load ntdll.dll', error: e, stackTrace: st);
      return null;
    }
  }();

  static final _RtlSetFeatureConfigurationsDart? _rtlSetFeatureConfigurations = () {
    try {
      return _ntdll
          ?.lookupFunction<_RtlSetFeatureConfigurationsNative, _RtlSetFeatureConfigurationsDart>(
            'RtlSetFeatureConfigurations',
          );
    } catch (_) {
      return null;
    }
  }();

  static final _RtlQueryFeatureConfigurationDart? _rtlQueryFeatureConfiguration = () {
    try {
      return _ntdll
          ?.lookupFunction<_RtlQueryFeatureConfigurationNative, _RtlQueryFeatureConfigurationDart>(
            'RtlQueryFeatureConfiguration',
          );
    } catch (_) {
      return null;
    }
  }();

  static final _RtlGetSystemBootStatusDart? _rtlGetSystemBootStatus = () {
    try {
      return _ntdll?.lookupFunction<_RtlGetSystemBootStatusNative, _RtlGetSystemBootStatusDart>(
        'RtlGetSystemBootStatus',
      );
    } catch (_) {
      return null;
    }
  }();

  static final _RtlSetSystemBootStatusDart? _rtlSetSystemBootStatus = () {
    try {
      return _ntdll?.lookupFunction<_RtlSetSystemBootStatusNative, _RtlSetSystemBootStatusDart>(
        'RtlSetSystemBootStatus',
      );
    } catch (_) {
      return null;
    }
  }();

  static final _RtlCreateBootStatusDataFileDart? _rtlCreateBootStatusDataFile = () {
    try {
      return _ntdll
          ?.lookupFunction<_RtlCreateBootStatusDataFileNative, _RtlCreateBootStatusDataFileDart>(
            'RtlCreateBootStatusDataFile',
          );
    } catch (_) {
      return null;
    }
  }();

  /// Applies runtime in-memory feature configuration updates via `RtlSetFeatureConfigurations`.
  ///
  /// Retries with TrustedInstaller privileges if access is denied.
  static Future<bool> setRuntimeFeatures(
    Map<int, bool> features, {
    int retryCount = 0,
    bool useTrustedInstaller = false,
  }) async {
    if (_rtlSetFeatureConfigurations case final rtlSetFeatureConfigurations?
        when features.isNotEmpty) {
      if (useTrustedInstaller) {
        return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
          () => setRuntimeFeatures(features, retryCount: retryCount),
        );
      }

      final int count = features.length;
      final int status = using((arena) {
        final Pointer<RtlFeatureConfigurationUpdate> updates = arena<RtlFeatureConfigurationUpdate>(
          count,
        );
        var index = 0;

        for (final MapEntry<int, bool> entry in features.entries) {
          final RtlFeatureConfigurationUpdate update = updates[index];
          update.featureId = entry.key;
          update.priority = priorityUser;
          update.enabledState = entry.value ? enabledStateEnabled : enabledStateDisabled;
          update.enabledStateOptions = 0;
          update.variant = 0;
          update.variantPayloadKind = 0;
          update.variantPayload = 0;
          update.operation = operationFeatureState | operationVariantState;
          index++;
        }

        final Pointer<Uint64> previousStamp = arena<Uint64>()..value = 0;
        return rtlSetFeatureConfigurations(previousStamp, storeTypeRuntime, updates, count);
      });

      if (status == statusSuccess) {
        logger.i('NtFeatureHelper: Applied ${features.length} runtime feature configuration(s)');
        return true;
      }

      final int unsignedStatus = status & 0xFFFFFFFF;
      if (unsignedStatus == statusAccessDenied) {
        logger.w(
          'NtFeatureHelper: RtlSetFeatureConfigurations access denied (0xC0000022), retrying with TrustedInstaller',
        );
        if (retryCount > 0) return false;
        try {
          return await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () => setRuntimeFeatures(features, retryCount: retryCount + 1),
          );
        } catch (e, st) {
          logger.w(
            'NtFeatureHelper: RtlSetFeatureConfigurations failed with TrustedInstaller',
            error: e,
            stackTrace: st,
          );
          return false;
        }
      }

      logger.w(
        'NtFeatureHelper: RtlSetFeatureConfigurations returned status 0x${unsignedStatus.toRadixString(16)}',
      );
      return false;
    }

    return false;
  }

  /// Resets runtime in-memory feature configurations back to default via `RtlSetFeatureConfigurations`.
  static Future<bool> resetRuntimeFeatures(
    Iterable<int> featureIds, {
    int retryCount = 0,
    bool useTrustedInstaller = false,
  }) async {
    if (_rtlSetFeatureConfigurations case final rtlSetFeatureConfigurations?
        when featureIds.isNotEmpty) {
      if (useTrustedInstaller) {
        return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
          () => resetRuntimeFeatures(featureIds, retryCount: retryCount),
        );
      }

      final List<int> ids = featureIds.toList();
      final int count = ids.length;
      final int status = using((arena) {
        final Pointer<RtlFeatureConfigurationUpdate> updates = arena<RtlFeatureConfigurationUpdate>(
          count,
        );

        for (var i = 0; i < count; i++) {
          final RtlFeatureConfigurationUpdate update = updates[i];
          update.featureId = ids[i];
          update.priority = priorityUser;
          update.enabledState = enabledStateDefault;
          update.enabledStateOptions = 0;
          update.variant = 0;
          update.variantPayloadKind = 0;
          update.variantPayload = 0;
          update.operation = operationResetState;
        }

        final Pointer<Uint64> previousStamp = arena<Uint64>()..value = 0;
        return rtlSetFeatureConfigurations(previousStamp, storeTypeRuntime, updates, count);
      });

      if (status == statusSuccess) {
        logger.i('NtFeatureHelper: Reset ${ids.length} runtime feature configuration(s)');
        return true;
      }

      final int unsignedStatus = status & 0xFFFFFFFF;
      if (unsignedStatus == statusAccessDenied) {
        logger.w(
          'NtFeatureHelper: RtlSetFeatureConfigurations reset access denied (0xC0000022), retrying with TrustedInstaller',
        );
        if (retryCount > 0) return false;
        try {
          return await TrustedInstallerServiceImpl().executeWithTrustedInstaller(
            () => resetRuntimeFeatures(featureIds, retryCount: retryCount + 1),
          );
        } catch (e, st) {
          logger.w(
            'NtFeatureHelper: RtlSetFeatureConfigurations reset failed with TrustedInstaller',
            error: e,
            stackTrace: st,
          );
          return false;
        }
      }

      logger.w(
        'NtFeatureHelper: RtlSetFeatureConfigurations reset returned status 0x${unsignedStatus.toRadixString(16)}',
      );
      return false;
    }

    return false;
  }

  /// Sets the system boot status to `BootPending` for Feature Management.
  ///
  /// This signals the Windows kernel to process and commit boot registry overrides
  /// on reboot, preventing them from being reverted to Last Known Good (LKG).
  static Future<bool> updateBootStatusPending({
    int retryCount = 0,
    bool useTrustedInstaller = false,
  }) async {
    if ((_rtlSetSystemBootStatus, _rtlGetSystemBootStatus) case (
      final setBootStatus?,
      final getBootStatus?,
    )) {
      if (useTrustedInstaller) {
        return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
          () => updateBootStatusPending(retryCount: retryCount),
        );
      }

      return using((arena) {
        final Pointer<Int32> statusData = arena<Int32>();
        int res = getBootStatus(
          bsdItemFeatureConfigurationState,
          statusData,
          sizeOf<Int32>(),
          nullptr,
        );

        final int unsignedRes = res & 0xFFFFFFFF;
        if (unsignedRes == statusObjectNameNotFound) {
          if (_rtlCreateBootStatusDataFile case final createDataFile?) {
            createDataFile(nullptr);
            res = getBootStatus(
              bsdItemFeatureConfigurationState,
              statusData,
              sizeOf<Int32>(),
              nullptr,
            );
          }
        }

        if (statusData.value == bsdStateBootPending) {
          return true;
        }

        statusData.value = bsdStateBootPending;
        final int setRes = setBootStatus(
          bsdItemFeatureConfigurationState,
          statusData,
          sizeOf<Int32>(),
          nullptr,
        );

        if (setRes == statusSuccess) {
          logger.i('NtFeatureHelper: Set boot feature configuration state to BootPending');
          return true;
        }

        final int unsignedSetRes = setRes & 0xFFFFFFFF;
        if (unsignedSetRes == statusAccessDenied) {
          logger.w(
            'NtFeatureHelper: RtlSetSystemBootStatus access denied (0xC0000022), retrying with TrustedInstaller',
          );
          if (retryCount > 0) return false;
          try {
            return TrustedInstallerServiceImpl().executeWithTrustedInstaller(
              () => updateBootStatusPending(retryCount: retryCount + 1),
            );
          } catch (e, st) {
            logger.w(
              'NtFeatureHelper: RtlSetSystemBootStatus failed with TrustedInstaller',
              error: e,
              stackTrace: st,
            );
            return false;
          }
        }

        logger.w(
          'NtFeatureHelper: RtlSetSystemBootStatus returned 0x${unsignedSetRes.toRadixString(16)}',
        );
        return false;
      });
    }

    return false;
  }

  /// Queries the active configuration of a feature in either runtime or boot store.
  ///
  /// Returns a record of `(enabledState, priority)` or null if query fails.
  static (int enabledState, int priority)? queryFeatureConfiguration(
    int featureId, {
    bool runtime = true,
  }) {
    if (_rtlQueryFeatureConfiguration case final queryFeature?) {
      return using((arena) {
        final Pointer<Uint64> changeStamp = arena<Uint64>()..value = 0;
        final Pointer<RtlFeatureConfiguration> config = arena<RtlFeatureConfiguration>();
        final int storeType = runtime ? storeTypeRuntime : storeTypeBoot;

        final int res = queryFeature(featureId, storeType, changeStamp, config);

        if (res != statusSuccess) return null;

        final int compactState = config.ref.compactState;
        final int priority = compactState & 0xF;
        final int enabledState = (compactState & 0x30) >> 4;
        return (enabledState, priority);
      });
    }

    return null;
  }
}
