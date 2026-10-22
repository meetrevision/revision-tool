import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:revitool/core/services/nt_feature_helper.dart';

void main() {
  group('NtFeatureHelper - Struct and ABI layout', () {
    test('RtlFeatureConfigurationUpdate has expected 32-byte size', () {
      expect(sizeOf<RtlFeatureConfigurationUpdate>(), equals(32));
    });

    test('RtlFeatureConfiguration has expected 12-byte size', () {
      expect(sizeOf<RtlFeatureConfiguration>(), equals(12));
    });

    test('constants match Windows NT Feature Management specifications', () {
      expect(NtFeatureHelper.priorityUser, equals(8));
      expect(NtFeatureHelper.storeTypeBoot, equals(0));
      expect(NtFeatureHelper.storeTypeRuntime, equals(1));
      expect(NtFeatureHelper.bsdItemFeatureConfigurationState, equals(17));
      expect(NtFeatureHelper.bsdStateBootPending, equals(1));
      expect(NtFeatureHelper.enabledStateDefault, equals(0));
      expect(NtFeatureHelper.enabledStateDisabled, equals(1));
      expect(NtFeatureHelper.enabledStateEnabled, equals(2));
      expect(NtFeatureHelper.operationFeatureState, equals(1));
      expect(NtFeatureHelper.operationVariantState, equals(2));
      expect(NtFeatureHelper.operationResetState, equals(4));
    });
  });

  group('NtFeatureHelper - Native ntdll queries', () {
    test('queryFeatureConfiguration successfully queries known feature', () {
      // Feature 58375086 is a Windows App SDK / Explorer feature on Windows 11
      if (NtFeatureHelper.queryFeatureConfiguration(58375086) case final config?) {
        expect(config.$1, isIn([0, 1, 2]));
        expect(config.$2, greaterThanOrEqualTo(0));
      }
    });

    test('handles empty feature sets gracefully', () async {
      await expectLater(NtFeatureHelper.setRuntimeFeatures({}), completion(isFalse));
      await expectLater(NtFeatureHelper.resetRuntimeFeatures([]), completion(isFalse));
    });
  });
}
