import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:go_router/go_router.dart';
import 'package:revitool/core/routing/app_routes.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/core/widgets/card_highlight.dart';
import 'package:revitool/utils_gui.dart';

class TweaksPage extends ConsumerWidget {
  const TweaksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        CardHighlight(
          icon: msicons.FluentIcons.shield_lock_20_regular,
          label: context.l10n.pageTweaksSecurity,
          description: context.l10n.pageTweaksSecurityDescription,
          onPressed: () => context.push(AppRoutes.security),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.top_speed_20_filled,
          label: context.l10n.pageTweaksPerformance,
          description: context.l10n.pageTweaksPerformanceDescription,
          onPressed: () => context.push(AppRoutes.performance),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.color_line_20_regular,
          label: context.l10n.pageTweaksPersonalization,
          description: context.l10n.pageTweaksPersonalizationDescription,
          onPressed: () => context.push(AppRoutes.personalization),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.data_usage_toolbox_20_regular,
          label: context.l10n.pageTweaksUtilities,
          description: context.l10n.pageTweaksUtilitiesDescription,
          onPressed: () => context.push(AppRoutes.utilities),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.arrow_download_20_regular,
          label: context.l10n.pageTweaksUpdates,
          description: context.l10n.pageTweaksUpdatesDescription,
          onPressed: () => context.push(AppRoutes.updates),
          action: const ChevronRightAction(),
        ),
      ].withSpacing(5),
    );
  }
}
