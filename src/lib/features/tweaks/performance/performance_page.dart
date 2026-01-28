import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/win_registry_service.dart';
import '../../../core/widgets/card_highlight.dart';
import '../../../extensions.dart';
import '../../../i18n/generated/strings.g.dart';
import '../../../utils_gui.dart';
import 'performance_service.dart';
import 'sections/background_priority_section.dart';
import 'sections/memory_storage_section.dart';
import 'sections/presentation_section.dart';

class PerformancePage extends ConsumerWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        const MemoryStorageSection(),

        if (WinRegistryService.isIntelCpu || kDebugMode) const _IntelTSXCard(),

        const BackgroundManagementSection(),
        const PresentationSection(),

        if (ref.watch(settingsExperimentalStatus)) ...[const _CStatesCard()],
      ].withSpacing(5),
    );
  }
}

class _IntelTSXCard extends ConsumerWidget {
  const _IntelTSXCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(intelTSXStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.transmission_20_regular,
      label: t.tweaksPerformanceIntelTSX,
      description: t.tweaksPerformanceIntelTSXDescription,
      action: CardToggleSwitch(
        value: status,
        requiresRestart: true,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).enableIntelTSX()
              : await ref.read(performanceServiceProvider).disableIntelTSX();
          ref.invalidate(intelTSXStatusProvider);
        },
      ),
    );
  }
}

class _CStatesCard extends ConsumerWidget {
  const _CStatesCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool status = ref.watch(cStatesStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.sleep_20_regular,
      label: t.tweaksPerformanceCStates,
      description: t.tweaksPerformanceCStatesDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(performanceServiceProvider).disableCStates()
              : await ref.read(performanceServiceProvider).enableCStates();
          ref.invalidate(cStatesStatusProvider);
        },
      ),
    );
  }
}
