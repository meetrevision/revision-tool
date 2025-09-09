import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/core/win_updates/updates_service.dart';
import 'package:revitool/extensions.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

class WinUpdatesPage extends ConsumerWidget {
  const WinUpdatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageUpdates)),
      children: [
        _PauseUpdatesCard(),
        _VisibilityCard(),
        _DriversCard(),
      ],
    );
  }
}

class _PauseUpdatesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pauseUpdatesWUStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.pause_20_regular,
      label: context.l10n.wuPauseLabel,
      description: context.l10n.wuPauseDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? WinUpdatesService.enablePauseUpdatesWU()
            : WinUpdatesService.disablePauseUpdatesWU();
        ref.invalidate(pauseUpdatesWUStatusProvider);
      },
    );
  }
}

class _VisibilityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(visibilityWUStatusProvider);

    return CardHighlightSwitch(
      icon: msicons.FluentIcons.arrow_sync_20_regular,
      label: context.l10n.wuPageLabel,
      description: context.l10n.wuPageDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? WinUpdatesService.disableVisibilityWU()
            : WinUpdatesService.enableVisibilityWU();
        ref.invalidate(visibilityWUStatusProvider);
      },
    );
  }
}

class _DriversCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(driversWUStatusProvider);

    return CardHighlightSwitch(
      icon: FluentIcons.devices4,
      label: context.l10n.wuDriversLabel,
      description: context.l10n.wuDriversDescription,
      switchBool: ValueNotifier(status),
      function: (value) {
        value
            ? WinUpdatesService.enableDriversWU()
            : WinUpdatesService.disableDriversWU();
        ref.invalidate(driversWUStatusProvider);
      },
    );
  }
}
