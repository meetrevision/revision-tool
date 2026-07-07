import '../inventory/tweak_inventory.dart';
import 'tweak_controller.dart';

final class TweakControllerFilters {
  const TweakControllerFilters({
    this.profile,
    this.risk,
    this.category,
    this.state,
    this.query = '',
  });

  final OptimizationProfile? profile;
  final TweakRisk? risk;
  final TweakCategory? category;
  final TweakControllerState? state;
  final String query;

  bool get hasActiveFilters =>
      profile != null ||
      risk != null ||
      category != null ||
      state != null ||
      query.trim().isNotEmpty;
}

final class TweakControllerCounts {
  const TweakControllerCounts({
    required this.total,
    required this.enabled,
    required this.disabled,
    required this.blocked,
    required this.failed,
    required this.pending,
    required this.unknown,
    required this.managedByProfile,
    required this.userOverride,
  });

  factory TweakControllerCounts.fromRows(List<TweakRowView> rows) {
    var enabled = 0;
    var disabled = 0;
    var blocked = 0;
    var failed = 0;
    var pending = 0;
    var unknown = 0;
    var managedByProfile = 0;
    var userOverride = 0;

    for (final row in rows) {
      switch (row.state) {
        case TweakControllerState.enabled:
          enabled++;
        case TweakControllerState.disabled:
          disabled++;
        case TweakControllerState.blocked:
          blocked++;
        case TweakControllerState.failed:
          failed++;
        case TweakControllerState.pendingReboot:
        case TweakControllerState.dangerousPendingConfirmation:
          pending++;
        case TweakControllerState.unknown:
          unknown++;
        case TweakControllerState.managedByProfile:
          managedByProfile++;
        case TweakControllerState.userOverride:
          userOverride++;
      }
    }

    return TweakControllerCounts(
      total: rows.length,
      enabled: enabled,
      disabled: disabled,
      blocked: blocked,
      failed: failed,
      pending: pending,
      unknown: unknown,
      managedByProfile: managedByProfile,
      userOverride: userOverride,
    );
  }

  final int total;
  final int enabled;
  final int disabled;
  final int blocked;
  final int failed;
  final int pending;
  final int unknown;
  final int managedByProfile;
  final int userOverride;
}

final class TweakRowView {
  const TweakRowView({required this.tweak, required this.result});

  final TweakDefinition tweak;
  final TweakResult? result;

  TweakControllerState get state =>
      result?.state ?? TweakControllerState.unknown;

  bool get enabled =>
      state == TweakControllerState.enabled ||
      state == TweakControllerState.managedByProfile;

  bool get dangerous => tweak.risk == TweakRisk.dangerous;

  String? get message => result?.reason ?? result?.error;

  bool matches(TweakControllerFilters filters) {
    if (filters.profile != null && !tweak.profiles.contains(filters.profile)) {
      return false;
    }
    if (filters.risk != null && tweak.risk != filters.risk) return false;
    if (filters.category != null && tweak.category != filters.category) {
      return false;
    }
    if (filters.state != null && state != filters.state) return false;

    final String normalizedQuery = filters.query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return tweak.name.toLowerCase().contains(normalizedQuery) ||
        tweak.id.toLowerCase().contains(normalizedQuery) ||
        tweak.category.displayName.toLowerCase().contains(normalizedQuery) ||
        tweak.technicalDescription.toLowerCase().contains(normalizedQuery);
  }
}

final class TweakCategoryGroup {
  const TweakCategoryGroup({required this.category, required this.rows});

  final TweakCategory category;
  final List<TweakRowView> rows;
}

final class TweakControllerViewModel {
  TweakControllerViewModel._({
    required this.rows,
    required this.visibleRows,
    required this.groups,
    required this.counts,
    required this.visibleCounts,
    required this.filters,
  });

  factory TweakControllerViewModel.build({
    required List<TweakDefinition> tweaks,
    required Map<String, TweakResult> results,
    required TweakControllerFilters filters,
  }) {
    final List<TweakRowView> rows = tweaks
        .map(
          (TweakDefinition tweak) =>
              TweakRowView(tweak: tweak, result: results[tweak.id]),
        )
        .toList(growable: false);
    final List<TweakRowView> visibleRows = rows
        .where((TweakRowView row) => row.matches(filters))
        .toList(growable: false);
    final groups = <TweakCategoryGroup>[];

    for (final TweakCategory category in TweakCategory.values) {
      final List<TweakRowView> categoryRows = visibleRows
          .where((TweakRowView row) => row.tweak.category == category)
          .toList(growable: false);
      if (categoryRows.isNotEmpty) {
        groups.add(TweakCategoryGroup(category: category, rows: categoryRows));
      }
    }

    return TweakControllerViewModel._(
      rows: rows,
      visibleRows: visibleRows,
      groups: List<TweakCategoryGroup>.unmodifiable(groups),
      counts: TweakControllerCounts.fromRows(rows),
      visibleCounts: TweakControllerCounts.fromRows(visibleRows),
      filters: filters,
    );
  }

  final List<TweakRowView> rows;
  final List<TweakRowView> visibleRows;
  final List<TweakCategoryGroup> groups;
  final TweakControllerCounts counts;
  final TweakControllerCounts visibleCounts;
  final TweakControllerFilters filters;

  TweakRowView? rowFor(String id) {
    for (final TweakRowView row in rows) {
      if (row.tweak.id == id) return row;
    }
    return null;
  }
}

extension TweakControllerStateLabel on TweakControllerState {
  String get displayName {
    return switch (this) {
      TweakControllerState.enabled => 'enabled',
      TweakControllerState.disabled => 'disabled',
      TweakControllerState.blocked => 'blocked',
      TweakControllerState.failed => 'failed',
      TweakControllerState.pendingReboot => 'pending reboot',
      TweakControllerState.unknown => 'unknown',
      TweakControllerState.managedByProfile => 'managed by profile',
      TweakControllerState.userOverride => 'user override',
      TweakControllerState.dangerousPendingConfirmation => 'needs confirmation',
    };
  }
}
