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
      children: const [_PauseUpdatesCard(), _VisibilityCard(), _DriversCard()],
    );
  }
}

class _PauseUpdatesCard extends ConsumerWidget {
  const _PauseUpdatesCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pauseUpdatesWUStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.pause_20_regular,
      label: context.l10n.wuPauseLabel,
      description: context.l10n.wuPauseDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(winUpdatesServiceProvider).enablePauseUpdatesWU()
              : await ref
                    .read(winUpdatesServiceProvider)
                    .disablePauseUpdatesWU();
          ref.invalidate(pauseUpdatesWUStatusProvider);
        },
      ),
    );
  }
}

class _VisibilityCard extends ConsumerWidget {
  const _VisibilityCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(visibilityWUStatusProvider);

    return CardHighlight(
      icon: msicons.FluentIcons.arrow_sync_20_regular,
      label: context.l10n.wuPageLabel,
      description: context.l10n.wuPageDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(winUpdatesServiceProvider).disableVisibilityWU()
              : await ref.read(winUpdatesServiceProvider).enableVisibilityWU();
          ref.invalidate(visibilityWUStatusProvider);
        },
      ),
    );
  }
}

class _DriversCard extends ConsumerWidget {
  const _DriversCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(driversWUStatusProvider);

    return CardHighlight(
      icon: FluentIcons.devices4,
      label: context.l10n.wuDriversLabel,
      description: context.l10n.wuDriversDescription,
      action: CardToggleSwitch(
        value: status,
        onChanged: (value) async {
          value
              ? await ref.read(winUpdatesServiceProvider).enableDriversWU()
              : await ref.read(winUpdatesServiceProvider).disableDriversWU();
          ref.invalidate(driversWUStatusProvider);
        },
      ),
    );
  }
}
