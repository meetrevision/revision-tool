import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/widgets/card_highlight.dart';
import '../../extensions.dart';
import '../../i18n/generated/strings.g.dart';
import '../../utils_gui.dart';

class TweaksPage extends ConsumerWidget {
  const TweaksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      children: [
        CardHighlight(
          icon: msicons.FluentIcons.shield_lock_20_regular,
          label: t.pageTweaksSecurity,
          description: t.pageTweaksSecurityDescription,
          onPressed: () => context.push(RouteMeta.tweaksSecurity.path),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.top_speed_20_regular,
          label: t.pageTweaksPerformance,
          description: t.pageTweaksPerformanceDescription,
          onPressed: () => context.push(RouteMeta.tweaksPerformance.path),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.color_20_regular,
          label: t.pageTweaksPersonalization,
          description: t.pageTweaksPersonalizationDescription,
          onPressed: () => context.push(RouteMeta.tweaksPersonalization.path),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.toolbox_20_regular,
          label: t.pageTweaksUtilities,
          description: t.pageTweaksUtilitiesDescription,
          onPressed: () => context.push(RouteMeta.tweaksUtilities.path),
          action: const ChevronRightAction(),
        ),

        CardHighlight(
          icon: msicons.FluentIcons.arrow_download_20_regular,
          label: t.pageTweaksUpdates,
          description: t.pageTweaksUpdatesDescription,
          onPressed: () => context.push(RouteMeta.tweaksUpdates.path),
          action: const ChevronRightAction(),
        ),
      ].withSpacing(5),
    );
  }
}
