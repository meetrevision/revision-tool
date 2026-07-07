import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter/services.dart';

import '../../../extensions.dart';
import '../../../utils_gui.dart';
import '../inventory/tweak_inventory.dart';
import 'tweak_controller.dart';
import 'tweak_controller_view_model.dart';

class TweakControllerPage extends StatefulWidget {
  const TweakControllerPage({super.key});

  @override
  State<TweakControllerPage> createState() => _TweakControllerPageState();
}

class _TweakControllerPageState extends State<TweakControllerPage> {
  late final TweakController _controller;
  late final ProfileController _profiles;
  late final TextEditingController _searchController;

  OptimizationProfile _selectedProfile = OptimizationProfile.gaming;
  OptimizationProfile? _profileFilter;
  TweakRisk? _riskFilter;
  TweakCategory? _categoryFilter;
  TweakControllerState? _stateFilter;
  bool _dryRun = true;
  bool _includeDangerous = false;
  bool _ignoreOverrides = false;
  bool _showAdvanced = false;
  bool _busy = false;
  String? _activeOperationId;
  String? _selectedTweakId;
  ProfileReport? _report;
  final Map<String, TweakResult> _results = <String, TweakResult>{};

  @override
  void initState() {
    super.initState();
    _controller = TweakController.production();
    _profiles = ProfileController(_controller);
    _searchController = TextEditingController();
    _report = _controller.rollbackManager.latestReport();
    if (_report != null) {
      for (final TweakResult result in _report!.results) {
        _results[result.id] = result;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = TweakControllerViewModel.build(
      tweaks: _controller.tweaks,
      results: _results,
      filters: TweakControllerFilters(
        profile: _profileFilter,
        risk: _riskFilter,
        category: _categoryFilter,
        state: _stateFilter,
        query: _searchController.text,
      ),
    );
    final TweakRowView? selected = _selectedTweakId == null
        ? null
        : model.rowFor(_selectedTweakId!);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Padding(
        padding: kScaffoldPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PageHeader(report: _report),
            const SizedBox(height: 12),
            _CommandSurface(
              selectedProfile: _selectedProfile,
              dryRun: _dryRun,
              includeDangerous: _includeDangerous,
              ignoreOverrides: _ignoreOverrides,
              showAdvanced: _showAdvanced,
              busy: _busy,
              report: _report,
              dangerousTotal: model.rows
                  .where((TweakRowView row) => row.dangerous)
                  .length,
              onProfileChanged: (OptimizationProfile value) {
                setState(() => _selectedProfile = value);
              },
              onDryRunChanged: (bool value) => setState(() => _dryRun = value),
              onIncludeDangerousChanged: (bool value) {
                setState(() => _includeDangerous = value);
              },
              onIgnoreOverridesChanged: (bool value) {
                setState(() => _ignoreOverrides = value);
              },
              onAdvancedChanged: (bool value) {
                setState(() => _showAdvanced = value);
              },
              onApply: _applyProfile,
              onRollback: _confirmRollbackLast,
              onRefresh: _refreshVisibleStatus,
            ),
            const SizedBox(height: 12),
            _SummaryBar(
              counts: model.counts,
              visibleCounts: model.visibleCounts,
              selectedState: _stateFilter,
              onStateSelected: (TweakControllerState? state) {
                setState(() => _stateFilter = state);
              },
            ),
            const SizedBox(height: 12),
            _Filters(
              searchController: _searchController,
              profile: _profileFilter,
              risk: _riskFilter,
              category: _categoryFilter,
              state: _stateFilter,
              hasActiveFilters: model.filters.hasActiveFilters,
              onSearchChanged: (_) => setState(() {}),
              onProfileChanged: (OptimizationProfile? value) {
                setState(() => _profileFilter = value);
              },
              onRiskChanged: (TweakRisk? value) {
                setState(() => _riskFilter = value);
              },
              onCategoryChanged: (TweakCategory? value) {
                setState(() => _categoryFilter = value);
              },
              onStateChanged: (TweakControllerState? value) {
                setState(() => _stateFilter = value);
              },
              onClear: _clearFilters,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool showDetails = constraints.maxWidth >= 1060;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _TweakList(
                          model: model,
                          selectedTweakId: _selectedTweakId,
                          busy: _busy,
                          activeOperationId: _activeOperationId,
                          onSelect: (String id) {
                            setState(() => _selectedTweakId = id);
                          },
                          onToggle: _toggleTweak,
                          onRollback: _rollbackTweak,
                          onClearFilters: _clearFilters,
                        ),
                      ),
                      if (showDetails) ...<Widget>[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 360,
                          child: _DetailsPanel(
                            row: selected,
                            busy: _busy,
                            onVerify: selected == null
                                ? null
                                : () => _verifyTweak(selected.tweak.id),
                            onRollback: selected == null
                                ? null
                                : () => _rollbackTweak(selected.tweak.id),
                            onCopyCommand: selected == null
                                ? null
                                : () => _copyTweakCommand(selected.tweak.id),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyProfile() async {
    if (!_dryRun && _includeDangerous && !await _confirmDangerous()) return;
    setState(() {
      _busy = true;
      _activeOperationId = '__profile__';
    });
    try {
      final ProfileReport report = await _profiles.apply(
        _selectedProfile,
        ProfileApplyOptions(
          dryRun: _dryRun,
          includeDangerous: _includeDangerous,
          assumeYes: _includeDangerous,
          ignoreOverrides: _ignoreOverrides,
        ),
      );
      setState(() {
        _report = report;
        _results
          ..clear()
          ..addEntries(
            report.results.map(
              (TweakResult result) =>
                  MapEntry<String, TweakResult>(result.id, result),
            ),
          );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeOperationId = null;
        });
      }
    }
  }

  Future<void> _toggleTweak(TweakRowView row, bool enabled) async {
    final TweakDefinition tweak = row.tweak;
    if (enabled && tweak.risk == TweakRisk.dangerous) {
      if (!_includeDangerous || !await _confirmDangerous()) return;
    }
    setState(() {
      _busy = true;
      _activeOperationId = tweak.id;
      _selectedTweakId = tweak.id;
    });
    try {
      final TweakResult result = enabled
          ? await _controller.enable(
              tweak.id,
              TweakExecutionOptions(
                dryRun: _dryRun,
                includeDangerous: _includeDangerous,
                assumeYes: _includeDangerous,
              ),
            )
          : await _controller.disable(
              tweak.id,
              TweakExecutionOptions(dryRun: _dryRun),
            );
      setState(() {
        _results[result.id] = result;
        _report = _controller.rollbackManager.latestReport();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeOperationId = null;
        });
      }
    }
  }

  Future<void> _rollbackTweak(String id) async {
    setState(() {
      _busy = true;
      _activeOperationId = id;
      _selectedTweakId = id;
    });
    try {
      final TweakResult result = await _controller.rollback(id);
      setState(() {
        _results[result.id] = result;
        _report = _controller.rollbackManager.latestReport();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeOperationId = null;
        });
      }
    }
  }

  Future<void> _verifyTweak(String id) async {
    setState(() {
      _busy = true;
      _activeOperationId = id;
      _selectedTweakId = id;
    });
    try {
      final TweakResult result = await _controller.verify(id);
      setState(() => _results[result.id] = result);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeOperationId = null;
        });
      }
    }
  }

  Future<void> _refreshVisibleStatus() async {
    final model = TweakControllerViewModel.build(
      tweaks: _controller.tweaks,
      results: _results,
      filters: TweakControllerFilters(
        profile: _profileFilter,
        risk: _riskFilter,
        category: _categoryFilter,
        state: _stateFilter,
        query: _searchController.text,
      ),
    );
    setState(() {
      _busy = true;
      _activeOperationId = '__refresh__';
    });
    try {
      for (final TweakRowView row in model.visibleRows) {
        final TweakResult result = await _controller.status(row.tweak.id);
        if (!mounted) return;
        setState(() => _results[result.id] = result);
      }
      setState(() => _report = _controller.rollbackManager.latestReport());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeOperationId = null;
        });
      }
    }
  }

  Future<void> _confirmRollbackLast() async {
    if (_report == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text('Rollback last report'),
          content: Text(
            'Rollback ${_report!.results.length} tweak result(s) from '
            '${_report!.profile?.displayName ?? 'the last single tweak run'}?',
          ),
          actions: <Widget>[
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              child: const Text('Rollback'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) await _rollbackLast();
  }

  Future<void> _rollbackLast() async {
    setState(() {
      _busy = true;
      _activeOperationId = '__rollback__';
    });
    try {
      final ProfileReport? report = await _profiles.rollbackLast();
      if (report == null) return;
      setState(() {
        _report = report;
        _results
          ..clear()
          ..addEntries(
            report.results.map(
              (TweakResult result) =>
                  MapEntry<String, TweakResult>(result.id, result),
            ),
          );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _activeOperationId = null;
        });
      }
    }
  }

  Future<bool> _confirmDangerous() async {
    final int dangerousCount = _controller.tweaks
        .where(
          (TweakDefinition tweak) =>
              tweak.profiles.contains(_selectedProfile) &&
              tweak.risk == TweakRisk.dangerous,
        )
        .length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text('Dangerous tweaks'),
          content: Text(
            '$dangerousCount dangerous tweak(s) are in scope for '
            '${_selectedProfile.displayName}. Backups, verification, and '
            'rollback are required, but blocked login/input/rollback tweaks '
            'will stay blocked.',
          ),
          actions: <Widget>[
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              child: const Text('Apply dangerous tweaks'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  void _clearFilters() {
    setState(() {
      _profileFilter = null;
      _riskFilter = null;
      _categoryFilter = null;
      _stateFilter = null;
      _searchController.clear();
    });
  }

  Future<void> _copyTweakCommand(String id) async {
    await Clipboard.setData(
      ClipboardData(text: 'revitool tweak enable $id --dry-run --json'),
    );
  }
}

final class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.report});

  final ProfileReport? report;

  @override
  Widget build(BuildContext context) {
    final subtitle = report == null
        ? 'Profiles, guards, reports, and rollback'
        : 'Last run: ${report!.profile?.displayName ?? 'Single tweak'} - '
              '${report!.results.length} result(s) - ${_formatDate(report!.completedAt)}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Tweak Controller', style: context.theme.typography.title),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.theme.resources.textFillColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _CommandSurface extends StatelessWidget {
  const _CommandSurface({
    required this.selectedProfile,
    required this.dryRun,
    required this.includeDangerous,
    required this.ignoreOverrides,
    required this.showAdvanced,
    required this.busy,
    required this.report,
    required this.dangerousTotal,
    required this.onProfileChanged,
    required this.onDryRunChanged,
    required this.onIncludeDangerousChanged,
    required this.onIgnoreOverridesChanged,
    required this.onAdvancedChanged,
    required this.onApply,
    required this.onRollback,
    required this.onRefresh,
  });

  final OptimizationProfile selectedProfile;
  final bool dryRun;
  final bool includeDangerous;
  final bool ignoreOverrides;
  final bool showAdvanced;
  final bool busy;
  final ProfileReport? report;
  final int dangerousTotal;
  final ValueChanged<OptimizationProfile> onProfileChanged;
  final ValueChanged<bool> onDryRunChanged;
  final ValueChanged<bool> onIncludeDangerousChanged;
  final ValueChanged<bool> onIgnoreOverridesChanged;
  final ValueChanged<bool> onAdvancedChanged;
  final VoidCallback onApply;
  final VoidCallback onRollback;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _LabeledControl(
                label: 'Profile',
                width: 220,
                child: ComboBox<OptimizationProfile>(
                  value: selectedProfile,
                  items: OptimizationProfile.values
                      .map(
                        (OptimizationProfile profile) =>
                            ComboBoxItem<OptimizationProfile>(
                              value: profile,
                              child: Text(profile.displayName),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: busy
                      ? null
                      : (OptimizationProfile? value) {
                          if (value != null) onProfileChanged(value);
                        },
                ),
              ),
              Checkbox(
                checked: dryRun,
                content: const Text('Dry run'),
                onChanged: busy
                    ? null
                    : (bool? value) {
                        if (value != null) onDryRunChanged(value);
                      },
              ),
              Button(
                onPressed: busy ? null : () => onAdvancedChanged(!showAdvanced),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(msicons.FluentIcons.settings_20_regular),
                    const SizedBox(width: 8),
                    Text(showAdvanced ? 'Hide advanced' : 'Advanced'),
                  ],
                ),
              ),
              FilledButton(
                onPressed: busy ? null : onApply,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (busy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    else
                      const Icon(msicons.FluentIcons.play_20_regular),
                    const SizedBox(width: 8),
                    Text(dryRun ? 'Run preview' : 'Apply'),
                  ],
                ),
              ),
              Button(
                onPressed: busy || report == null ? null : onRollback,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(msicons.FluentIcons.arrow_undo_20_regular),
                    SizedBox(width: 8),
                    Text('Rollback last'),
                  ],
                ),
              ),
              Button(
                onPressed: busy ? null : onRefresh,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(msicons.FluentIcons.arrow_clockwise_20_regular),
                    SizedBox(width: 8),
                    Text('Refresh status'),
                  ],
                ),
              ),
            ],
          ),
          if (showAdvanced) ...<Widget>[
            const SizedBox(height: 12),
            _AdvancedRiskControls(
              includeDangerous: includeDangerous,
              ignoreOverrides: ignoreOverrides,
              dangerousTotal: dangerousTotal,
              busy: busy,
              onIncludeDangerousChanged: onIncludeDangerousChanged,
              onIgnoreOverridesChanged: onIgnoreOverridesChanged,
            ),
          ],
        ],
      ),
    );
  }
}

final class _AdvancedRiskControls extends StatelessWidget {
  const _AdvancedRiskControls({
    required this.includeDangerous,
    required this.ignoreOverrides,
    required this.dangerousTotal,
    required this.busy,
    required this.onIncludeDangerousChanged,
    required this.onIgnoreOverridesChanged,
  });

  final bool includeDangerous;
  final bool ignoreOverrides;
  final int dangerousTotal;
  final bool busy;
  final ValueChanged<bool> onIncludeDangerousChanged;
  final ValueChanged<bool> onIgnoreOverridesChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(6),
        color: Colors.orange.withOpacity(0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(msicons.FluentIcons.warning_20_regular),
                SizedBox(width: 8),
                Text('Advanced risk controls'),
              ],
            ),
            Text('$dangerousTotal dangerous tweak(s) in inventory'),
            Checkbox(
              checked: includeDangerous,
              content: const Text('Include dangerous'),
              onChanged: busy
                  ? null
                  : (bool? value) {
                      if (value != null) onIncludeDangerousChanged(value);
                    },
            ),
            Checkbox(
              checked: ignoreOverrides,
              content: const Text('Ignore overrides'),
              onChanged: busy
                  ? null
                  : (bool? value) {
                      if (value != null) onIgnoreOverridesChanged(value);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

final class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.counts,
    required this.visibleCounts,
    required this.selectedState,
    required this.onStateSelected,
  });

  final TweakControllerCounts counts;
  final TweakControllerCounts visibleCounts;
  final TweakControllerState? selectedState;
  final ValueChanged<TweakControllerState?> onStateSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _StatChip(
          label: 'Total',
          value: visibleCounts.total,
          total: counts.total,
          selected: selectedState == null,
          onPressed: () => onStateSelected(null),
        ),
        _StatChip(
          label: 'Enabled',
          value: visibleCounts.enabled + visibleCounts.managedByProfile,
          total: counts.enabled + counts.managedByProfile,
          state: TweakControllerState.enabled,
          selected: selectedState == TweakControllerState.enabled,
          onPressed: () => onStateSelected(TweakControllerState.enabled),
        ),
        _StatChip(
          label: 'Blocked',
          value: visibleCounts.blocked,
          total: counts.blocked,
          state: TweakControllerState.blocked,
          selected: selectedState == TweakControllerState.blocked,
          onPressed: () => onStateSelected(TweakControllerState.blocked),
        ),
        _StatChip(
          label: 'Pending',
          value: visibleCounts.pending,
          total: counts.pending,
          state: TweakControllerState.dangerousPendingConfirmation,
          selected:
              selectedState ==
              TweakControllerState.dangerousPendingConfirmation,
          onPressed: () => onStateSelected(
            TweakControllerState.dangerousPendingConfirmation,
          ),
        ),
        _StatChip(
          label: 'Failed',
          value: visibleCounts.failed,
          total: counts.failed,
          state: TweakControllerState.failed,
          selected: selectedState == TweakControllerState.failed,
          onPressed: () => onStateSelected(TweakControllerState.failed),
        ),
        _StatChip(
          label: 'Unknown',
          value: visibleCounts.unknown,
          total: counts.unknown,
          state: TweakControllerState.unknown,
          selected: selectedState == TweakControllerState.unknown,
          onPressed: () => onStateSelected(TweakControllerState.unknown),
        ),
      ],
    );
  }
}

final class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.total,
    required this.selected,
    required this.onPressed,
    this.state,
  });

  final String label;
  final int value;
  final int total;
  final bool selected;
  final TweakControllerState? state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color color = state == null ? Colors.grey : _stateColor(state!);
    return Button(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (selected) ...<Widget>[
            const Icon(msicons.FluentIcons.checkmark_20_regular, size: 14),
            const SizedBox(width: 6),
          ],
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: 8),
          Text('$label $value/$total'),
        ],
      ),
    );
  }
}

final class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.profile,
    required this.risk,
    required this.category,
    required this.state,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onProfileChanged,
    required this.onRiskChanged,
    required this.onCategoryChanged,
    required this.onStateChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final OptimizationProfile? profile;
  final TweakRisk? risk;
  final TweakCategory? category;
  final TweakControllerState? state;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<OptimizationProfile?> onProfileChanged;
  final ValueChanged<TweakRisk?> onRiskChanged;
  final ValueChanged<TweakCategory?> onCategoryChanged;
  final ValueChanged<TweakControllerState?> onStateChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          _LabeledControl(
            label: 'Search',
            width: 280,
            child: TextBox(
              controller: searchController,
              placeholder: 'Name, id, category, description',
              onChanged: onSearchChanged,
            ),
          ),
          _LabeledControl(
            label: 'Profile',
            width: 190,
            child: _combo<OptimizationProfile>(
              value: profile,
              allLabel: 'All profiles',
              values: OptimizationProfile.values,
              label: (OptimizationProfile value) => value.displayName,
              onChanged: onProfileChanged,
            ),
          ),
          _LabeledControl(
            label: 'Risk',
            width: 150,
            child: _combo<TweakRisk>(
              value: risk,
              allLabel: 'All risks',
              values: TweakRisk.values,
              label: (TweakRisk value) => value.displayName,
              onChanged: onRiskChanged,
            ),
          ),
          _LabeledControl(
            label: 'Category',
            width: 230,
            child: _combo<TweakCategory>(
              value: category,
              allLabel: 'All categories',
              values: TweakCategory.values,
              label: (TweakCategory value) => value.displayName,
              onChanged: onCategoryChanged,
            ),
          ),
          _LabeledControl(
            label: 'State',
            width: 210,
            child: _combo<TweakControllerState>(
              value: state,
              allLabel: 'All states',
              values: TweakControllerState.values,
              label: (TweakControllerState value) => value.displayName,
              onChanged: onStateChanged,
            ),
          ),
          Button(
            onPressed: hasActiveFilters ? onClear : null,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(msicons.FluentIcons.dismiss_20_regular),
                SizedBox(width: 8),
                Text('Clear filters'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _combo<T>({
    required T? value,
    required String allLabel,
    required List<T> values,
    required String Function(T value) label,
    required ValueChanged<T?> onChanged,
  }) {
    return ComboBox<T?>(
      value: value,
      items: <ComboBoxItem<T?>>[
        ComboBoxItem<T?>(child: Text(allLabel)),
        ...values.map(
          (T item) => ComboBoxItem<T?>(
            value: item,
            child: Text(label(item), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

final class _TweakList extends StatelessWidget {
  const _TweakList({
    required this.model,
    required this.selectedTweakId,
    required this.busy,
    required this.activeOperationId,
    required this.onSelect,
    required this.onToggle,
    required this.onRollback,
    required this.onClearFilters,
  });

  final TweakControllerViewModel model;
  final String? selectedTweakId;
  final bool busy;
  final String? activeOperationId;
  final ValueChanged<String> onSelect;
  final void Function(TweakRowView row, bool enabled) onToggle;
  final ValueChanged<String> onRollback;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (model.visibleRows.isEmpty) {
      return _EmptyState(onClearFilters: onClearFilters);
    }

    final entries = <_ListEntry>[];
    for (final TweakCategoryGroup group in model.groups) {
      entries.add(_ListEntry.header(group.category, group.rows.length));
      entries.addAll(group.rows.map(_ListEntry.row));
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        final _ListEntry entry = entries[index];
        if (entry.category != null) {
          return _CategoryHeader(category: entry.category!, count: entry.count);
        }
        final TweakRowView row = entry.row!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TweakRowCard(
            row: row,
            selected: row.tweak.id == selectedTweakId,
            busy: busy,
            active: activeOperationId == row.tweak.id,
            onSelect: () => onSelect(row.tweak.id),
            onToggle: (bool value) => onToggle(row, value),
            onRollback: () => onRollback(row.tweak.id),
          ),
        );
      },
    );
  }
}

final class _TweakRowCard extends StatelessWidget {
  const _TweakRowCard({
    required this.row,
    required this.selected,
    required this.busy,
    required this.active,
    required this.onSelect,
    required this.onToggle,
    required this.onRollback,
  });

  final TweakRowView row;
  final bool selected;
  final bool busy;
  final bool active;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRollback;

  @override
  Widget build(BuildContext context) {
    final Color stateColor = _stateColor(row.state);
    return GestureDetector(
      onTap: onSelect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? context.theme.accentColor
                : context.theme.resources.cardStrokeColorDefault,
          ),
          borderRadius: BorderRadius.circular(6),
          color: selected
              ? context.theme.accentColor.withOpacity(0.08)
              : context.theme.cardColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: stateColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const SizedBox(width: 4, height: 48),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            row.tweak.name,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.bodyStrong,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RiskBadge(risk: row.tweak.risk),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.tweak.id,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.theme.resources.textFillColorSecondary,
                      ),
                    ),
                    if (row.message != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        row.message!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: row.state == TweakControllerState.failed
                              ? Colors.red
                              : context.theme.resources.textFillColorSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (active)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: ProgressRing(strokeWidth: 2),
                )
              else
                _StatusBadge(state: row.state),
              const SizedBox(width: 10),
              Tooltip(
                message: row.enabled
                    ? 'Rollback optimization'
                    : 'Apply optimization',
                child: ToggleSwitch(
                  checked: row.enabled,
                  onChanged: busy ? null : onToggle,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Rollback tweak',
                child: IconButton(
                  icon: const Icon(msicons.FluentIcons.arrow_undo_20_regular),
                  onPressed: busy ? null : onRollback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.row,
    required this.busy,
    required this.onVerify,
    required this.onRollback,
    required this.onCopyCommand,
  });

  final TweakRowView? row;
  final bool busy;
  final VoidCallback? onVerify;
  final VoidCallback? onRollback;
  final VoidCallback? onCopyCommand;

  @override
  Widget build(BuildContext context) {
    final TweakRowView? selected = row;
    return _Surface(
      child: selected == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tweak details', style: context.theme.typography.subtitle),
                const SizedBox(height: 8),
                Text(
                  'Select a tweak to inspect impact, warnings, commands, and rollback state.',
                  style: TextStyle(
                    color: context.theme.resources.textFillColorSecondary,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  selected.tweak.name,
                  style: context.theme.typography.subtitle,
                ),
                const SizedBox(height: 6),
                Text(
                  selected.tweak.id,
                  style: TextStyle(
                    color: context.theme.resources.textFillColorSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _StatusBadge(state: selected.state),
                    _RiskBadge(risk: selected.tweak.risk),
                    _Pill(label: selected.tweak.category.displayName),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailBlock(
                  label: 'Impact',
                  value: selected.tweak.expectedImpact,
                ),
                _DetailBlock(
                  label: 'Technical action',
                  value: selected.tweak.technicalDescription,
                ),
                if (selected.message != null)
                  _DetailBlock(label: 'Last result', value: selected.message!),
                if (selected.result?.backupId != null)
                  _DetailBlock(
                    label: 'Backup',
                    value: selected.result!.backupId!,
                  ),
                if (selected.tweak.warnings.isNotEmpty)
                  _DetailBlock(
                    label: 'Warnings',
                    value: selected.tweak.warnings.join('\n'),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Button(
                      onPressed: busy ? null : onVerify,
                      child: const Text('Verify'),
                    ),
                    Button(
                      onPressed: busy ? null : onRollback,
                      child: const Text('Rollback'),
                    ),
                    Button(
                      onPressed: onCopyCommand,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(msicons.FluentIcons.copy_20_regular),
                          SizedBox(width: 8),
                          Text('Copy CLI'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

final class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: context.theme.typography.bodyStrong),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: context.theme.resources.textFillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

final class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.count});

  final TweakCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: <Widget>[
          Text(
            category.displayName,
            style: context.theme.typography.bodyStrong,
          ),
          const SizedBox(width: 8),
          _Pill(label: '$count'),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(msicons.FluentIcons.search_20_regular, size: 28),
            const SizedBox(height: 10),
            Text(
              'No tweaks match these filters',
              style: context.theme.typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Clear filters or use a broader search.',
              style: TextStyle(
                color: context.theme.resources.textFillColorSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Button(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LabeledControl extends StatelessWidget {
  const _LabeledControl({
    required this.label,
    required this.child,
    required this.width,
  });

  final String label;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: context.theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final TweakControllerState state;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: state.displayName,
      color: _stateColor(state),
      icon: _stateIcon(state),
    );
  }
}

final class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});

  final TweakRisk risk;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (risk) {
      TweakRisk.low => Colors.green,
      TweakRisk.medium => Colors.blue,
      TweakRisk.high => Colors.orange,
      TweakRisk.dangerous => Colors.red,
    };
    final IconData? icon = risk == TweakRisk.dangerous
        ? msicons.FluentIcons.warning_20_regular
        : null;
    return _Pill(label: risk.displayName, color: color, icon: icon);
  }
}

final class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color baseColor =
        color ?? context.theme.resources.controlStrokeColorDefault;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: baseColor.withOpacity(color == null ? 0.08 : 0.14),
        border: Border.all(
          color: baseColor.withOpacity(color == null ? 0.35 : 0.60),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

final class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.theme.resources.cardStrokeColorDefault,
        ),
        borderRadius: BorderRadius.circular(6),
        color: context.theme.cardColor,
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

final class _ListEntry {
  const _ListEntry._({this.category, this.row, this.count = 0});

  factory _ListEntry.header(TweakCategory category, int count) {
    return _ListEntry._(category: category, count: count);
  }

  factory _ListEntry.row(TweakRowView row) {
    return _ListEntry._(row: row);
  }

  final TweakCategory? category;
  final TweakRowView? row;
  final int count;
}

Color _stateColor(TweakControllerState state) {
  return switch (state) {
    TweakControllerState.enabled => Colors.green,
    TweakControllerState.managedByProfile => Colors.blue,
    TweakControllerState.disabled => Colors.grey,
    TweakControllerState.blocked => Colors.orange,
    TweakControllerState.failed => Colors.red,
    TweakControllerState.pendingReboot => Colors.purple,
    TweakControllerState.dangerousPendingConfirmation => Colors.orange,
    TweakControllerState.userOverride => Colors.teal,
    TweakControllerState.unknown => Colors.grey,
  };
}

IconData _stateIcon(TweakControllerState state) {
  return switch (state) {
    TweakControllerState.enabled => msicons.FluentIcons.checkmark_20_regular,
    TweakControllerState.managedByProfile =>
      msicons.FluentIcons.shield_checkmark_20_regular,
    TweakControllerState.disabled => msicons.FluentIcons.dismiss_20_regular,
    TweakControllerState.blocked =>
      msicons.FluentIcons.shield_prohibited_20_regular,
    TweakControllerState.failed =>
      msicons.FluentIcons.dismiss_circle_20_regular,
    TweakControllerState.pendingReboot =>
      msicons.FluentIcons.arrow_clockwise_20_regular,
    TweakControllerState.dangerousPendingConfirmation =>
      msicons.FluentIcons.warning_20_regular,
    TweakControllerState.userOverride =>
      msicons.FluentIcons.settings_20_regular,
    TweakControllerState.unknown => msicons.FluentIcons.search_20_regular,
  };
}

String _formatDate(DateTime value) {
  final DateTime local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
