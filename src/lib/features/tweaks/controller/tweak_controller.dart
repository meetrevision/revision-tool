import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../inventory/tweak_inventory.dart';
import '../performance/performance_service.dart';
import '../personalization/personalization_service.dart';
import '../security/security_service.dart';
import '../updates/updates_service.dart';
import '../utilities/utilities_service.dart';

typedef TweakDetectCallback = FutureOr<bool> Function();
typedef TweakActionCallback = FutureOr<void> Function();

final class TweakOperation {
  const TweakOperation({
    required this.id,
    required this.detect,
    required this.applyOptimized,
    required this.verifyOptimized,
    required this.rollback,
  });

  factory TweakOperation.noop(String id) {
    return TweakOperation(
      id: id,
      detect: () => false,
      applyOptimized: () {},
      verifyOptimized: () => true,
      rollback: () {},
    );
  }

  final String id;
  final TweakDetectCallback detect;
  final TweakActionCallback applyOptimized;
  final TweakDetectCallback verifyOptimized;
  final TweakActionCallback rollback;
}

final class TweakOperationRegistry {
  TweakOperationRegistry(Map<String, TweakOperation> operations)
    : _operations = Map<String, TweakOperation>.unmodifiable(operations);

  factory TweakOperationRegistry.fromServices({
    PerformanceService performance = const PerformanceServiceImpl(),
    PersonalizationService personalization = const PersonalizationServiceImpl(),
    SecurityService security = const SecurityServiceImpl(),
    UpdatesService updates = const UpdatesServiceImpl(),
    UtilitiesService utilities = const UtilitiesServiceImpl(),
  }) {
    final registeredOperations = <TweakOperation>[
      _operation(
        id: 'performance.powerplan',
        detect: () => performance.statusReviPowerPlan,
        apply: performance.enableReviPowerPlan,
        verify: () => performance.statusReviPowerPlan,
        rollback: performance.disableReviPowerPlan,
      ),
      _operation(
        id: 'performance.powerplan-states-c6',
        detect: () => performance.statusReviPowerPlanC6States,
        apply: performance.enableReviPowerPlanC6States,
        verify: () => performance.statusReviPowerPlanC6States,
        rollback: performance.disableReviPowerPlanC6States,
      ),
      _operation(
        id: 'performance.superfetch',
        detect: () => !performance.statusSuperfetch,
        apply: performance.disableSuperfetch,
        verify: () => !performance.statusSuperfetch,
        rollback: performance.enableSuperfetch,
      ),
      _operation(
        id: 'performance.memory-compression',
        detect: () => !performance.statusMemoryCompression,
        apply: performance.disableMemoryCompression,
        verify: () => !performance.statusMemoryCompression,
        rollback: performance.enableMemoryCompression,
      ),
      _operation(
        id: 'performance.intel-tsx',
        detect: () => performance.statusIntelTSX,
        apply: performance.enableIntelTSX,
        verify: () => performance.statusIntelTSX,
        rollback: performance.disableIntelTSX,
      ),
      _operation(
        id: 'performance.swapchain-fso',
        detect: () => performance.statusFullscreenOptimization,
        apply: performance.enableFullscreenOptimization,
        verify: () => performance.statusFullscreenOptimization,
        rollback: performance.disableFullscreenOptimization,
      ),
      _operation(
        id: 'performance.swapchain-wo',
        detect: () => performance.statusWindowedOptimization,
        apply: performance.enableWindowedOptimization,
        verify: () => performance.statusWindowedOptimization,
        rollback: performance.disableWindowedOptimization,
      ),
      _operation(
        id: 'performance.swapchain-mpo',
        detect: () => !performance.statusMPO,
        apply: performance.disableMPO,
        verify: () => !performance.statusMPO,
        rollback: performance.enableMPO,
      ),
      _operation(
        id: 'performance.background-apps',
        detect: () => !performance.statusBackgroundApps,
        apply: performance.disableBackgroundApps,
        verify: () => !performance.statusBackgroundApps,
        rollback: performance.enableBackgroundApps,
      ),
      _operation(
        id: 'performance.ctfmon-input',
        detect: () => !performance.statusCtfmonInput,
        apply: performance.disableCtfmonInput,
        verify: () => !performance.statusCtfmonInput,
        rollback: performance.enableCtfmonInput,
      ),
      _operation(
        id: 'performance.ntfs-last-access',
        detect: () => !performance.statusLastTimeAccessNTFS,
        apply: performance.disableLastTimeAccessNTFS,
        verify: () => !performance.statusLastTimeAccessNTFS,
        rollback: performance.enableLastTimeAccessNTFS,
      ),
      _operation(
        id: 'performance.ntfs-8dot3-naming',
        detect: () => !performance.status8dot3NamingNTFS,
        apply: performance.disable8dot3NamingNTFS,
        verify: () => !performance.status8dot3NamingNTFS,
        rollback: performance.enable8dot3NamingNTFS,
      ),
      _operation(
        id: 'performance.ntfs-memory-usage',
        detect: () => performance.statusMemoryUsageNTFS,
        apply: performance.enableMemoryUsageNTFS,
        verify: () => performance.statusMemoryUsageNTFS,
        rollback: performance.disableMemoryUsageNTFS,
      ),
      _operation(
        id: 'performance.service-grouping',
        detect: () =>
            performance.statusServicesGrouping == ServiceGrouping.recommended,
        apply: () =>
            performance.setServiceGroupingMode(ServiceGrouping.recommended),
        verify: () =>
            performance.statusServicesGrouping == ServiceGrouping.recommended,
        rollback: () =>
            performance.setServiceGroupingMode(ServiceGrouping.disabled),
      ),
      _operation(
        id: 'performance.background-window-message-rate-limit',
        detect: () => performance.statusBackgroundWindowMessageRateLimit == 125,
        apply: () => performance.setBackgroundWindowMessageRateLimit(8),
        verify: () => performance.statusBackgroundWindowMessageRateLimit == 125,
        rollback: performance.disableBackgroundWindowMessageRateLimit,
      ),
      _operation(
        id: 'personalization.notification',
        detect: () =>
            personalization.statusNotification == NotificationMode.offMinimal,
        apply: () =>
            personalization.setNotificationMode(NotificationMode.offMinimal),
        verify: () =>
            personalization.statusNotification == NotificationMode.offMinimal,
        rollback: () =>
            personalization.setNotificationMode(NotificationMode.on),
      ),
      _operation(
        id: 'personalization.legacy-balloon',
        detect: () => !personalization.statusLegacyBalloon,
        apply: personalization.disableLegacyBalloon,
        verify: () => !personalization.statusLegacyBalloon,
        rollback: personalization.enableLegacyBalloon,
      ),
      _operation(
        id: 'personalization.screen-edge-swipe',
        detect: () => !personalization.statusScreenEdgeSwipe,
        apply: personalization.disableScreenEdgeSwipe,
        verify: () => !personalization.statusScreenEdgeSwipe,
        rollback: personalization.enableScreenEdgeSwipe,
      ),
      _operation(
        id: 'personalization.new-context-menu',
        detect: () => !personalization.statusNewContextMenu,
        apply: personalization.disableNewContextMenu,
        verify: () => !personalization.statusNewContextMenu,
        rollback: personalization.enableNewContextMenu,
      ),
      _operation(
        id: 'personalization.input-personalization',
        detect: () => !personalization.statusInputPersonalization,
        apply: personalization.disableInputPersonalization,
        verify: () => !personalization.statusInputPersonalization,
        rollback: personalization.enableInputPersonalization,
      ),
      _operation(
        id: 'personalization.caps-lock',
        detect: () => personalization.statusCapsLock,
        apply: personalization.disableCapsLock,
        verify: () => personalization.statusCapsLock,
        rollback: personalization.enableCapsLock,
      ),
      _operation(
        id: 'personalization.explorer-home',
        detect: () => !personalization.statusExplorerHome,
        apply: personalization.disableExplorerHome,
        verify: () => !personalization.statusExplorerHome,
        rollback: personalization.enableExplorerHome,
      ),
      _operation(
        id: 'personalization.explorer-gallery',
        detect: () => !personalization.statusExplorerGallery,
        apply: personalization.disableExplorerGallery,
        verify: () => !personalization.statusExplorerGallery,
        rollback: personalization.enableExplorerGallery,
      ),
      _operation(
        id: 'security.defender',
        detect: () => !security.statusDefender,
        apply: security.disableDefenderCLI,
        verify: () => !security.statusDefender,
        rollback: security.enableDefender,
      ),
      _operation(
        id: 'security.uac',
        detect: () => !security.statusUAC,
        apply: security.disableUAC,
        verify: () => !security.statusUAC,
        rollback: security.enableUAC,
      ),
      _operation(
        id: 'security.mitigation.meltdown-spectre',
        detect: () => !security.isMitigationEnabled(Mitigation.meltdownSpectre),
        apply: () => security.disableMitigation(Mitigation.meltdownSpectre),
        verify: () => !security.isMitigationEnabled(Mitigation.meltdownSpectre),
        rollback: () => security.enableMitigation(Mitigation.meltdownSpectre),
      ),
      _operation(
        id: 'security.mitigation.downfall',
        detect: () => !security.isMitigationEnabled(Mitigation.downfall),
        apply: () => security.disableMitigation(Mitigation.downfall),
        verify: () => !security.isMitigationEnabled(Mitigation.downfall),
        rollback: () => security.enableMitigation(Mitigation.downfall),
      ),
      _operation(
        id: 'security.vbs',
        detect: () => !security.statusVbs,
        apply: security.disableVbs,
        verify: () => !security.statusVbs,
        rollback: security.enableVbs,
      ),
      _operation(
        id: 'security.memory-integrity',
        detect: () => !security.statusMemoryIntegrity,
        apply: security.disableMemoryIntegrity,
        verify: () => !security.statusMemoryIntegrity,
        rollback: security.enableMemoryIntegrity,
      ),
      _operation(
        id: 'updates.certificates',
        detect: () => false,
        apply: updates.updateCertificates,
        verify: () => true,
        rollback: () {},
      ),
      _operation(
        id: 'updates.kgl',
        detect: () => false,
        apply: updates.updateKGL,
        verify: () => true,
        rollback: () {},
      ),
      _operation(
        id: 'updates.wu-pause-updates',
        detect: () => updates.statusPauseUpdatesWU,
        apply: updates.enablePauseUpdatesWU,
        verify: () => updates.statusPauseUpdatesWU,
        rollback: updates.disablePauseUpdatesWU,
      ),
      _operation(
        id: 'updates.wu-visibility',
        detect: () => updates.statusVisibilityWU,
        apply: updates.disableVisibilityWU,
        verify: () => updates.statusVisibilityWU,
        rollback: updates.enableVisibilityWU,
      ),
      _operation(
        id: 'updates.wu-drivers',
        detect: () => !updates.statusDriversWU,
        apply: updates.disableDriversWU,
        verify: () => !updates.statusDriversWU,
        rollback: updates.enableDriversWU,
      ),
      _operation(
        id: 'utilities.hibernation',
        detect: () => !utilities.statusHibernation,
        apply: utilities.disableHibernation,
        verify: () => !utilities.statusHibernation,
        rollback: utilities.enableHibernation,
      ),
      _operation(
        id: 'utilities.fast-startup',
        detect: () => !utilities.statusFastStartup,
        apply: utilities.disableFastStartup,
        verify: () => !utilities.statusFastStartup,
        rollback: utilities.enableFastStartup,
      ),
      _operation(
        id: 'utilities.modern-standby',
        detect: () => !utilities.statusModernStandby,
        apply: utilities.disableModernStandby,
        verify: () => !utilities.statusModernStandby,
        rollback: utilities.enableModernStandby,
      ),
      _operation(
        id: 'utilities.tm-monitoring',
        detect: () => !utilities.statusTMMonitoring,
        apply: utilities.disableTMMonitoring,
        verify: () => !utilities.statusTMMonitoring,
        rollback: utilities.enableTMMonitoring,
      ),
      _operation(
        id: 'utilities.usage-reporting',
        detect: () => !utilities.statusUsageReporting,
        apply: utilities.disableUsageReporting,
        verify: () => !utilities.statusUsageReporting,
        rollback: utilities.enableUsageReporting,
      ),
      _operation(
        id: 'playbook.patches',
        detect: () => !updates.statusDriversWU && updates.statusPauseUpdatesWU,
        apply: () async {
          await updates.disableDriversWU();
          await updates.enablePauseUpdatesWU();
        },
        verify: () => !updates.statusDriversWU && updates.statusPauseUpdatesWU,
        rollback: () async {
          await updates.enableDriversWU();
          await updates.disablePauseUpdatesWU();
        },
      ),
    ];
    final operations = <String, TweakOperation>{
      for (final TweakOperation operation in registeredOperations)
        operation.id: operation,
    };

    assert(
      tweakControllerInventoryIds.difference(operations.keys.toSet()).isEmpty,
      'TweakOperationRegistry is missing inventory IDs',
    );
    return TweakOperationRegistry(operations);
  }

  final Map<String, TweakOperation> _operations;

  TweakOperation? operationFor(String id) => _operations[id];

  bool contains(String id) => _operations.containsKey(id);

  List<String> get ids => _operations.keys.toList(growable: false);

  static TweakOperation _operation({
    required String id,
    required TweakDetectCallback detect,
    required TweakActionCallback apply,
    required TweakDetectCallback verify,
    required TweakActionCallback rollback,
  }) {
    return TweakOperation(
      id: id,
      detect: detect,
      applyOptimized: apply,
      verifyOptimized: verify,
      rollback: rollback,
    );
  }
}

final class SystemContext {
  const SystemContext({
    required this.windowsBuild,
    required this.windowsEdition,
    required this.cpuVendor,
    required this.gpuVendors,
    required this.isLaptop,
    required this.hasBattery,
    required this.modernStandby,
    required this.bitLockerEnabled,
    required this.hyperVEnabled,
    required this.wslEnabled,
    required this.storeAvailable,
    required this.xboxInstalled,
    required this.gamePassInstalled,
    required this.gpuDriversPresent,
    required this.audioDevicesPresent,
    required this.bluetoothPresent,
    required this.printersPresent,
    required this.networkSharesPresent,
    required this.windowsUpdateHealthy,
  });

  const SystemContext.testSafe()
    : this(
        windowsBuild: 22631,
        windowsEdition: 'Windows 11 Pro',
        cpuVendor: 'GenuineIntel',
        gpuVendors: const <String>['NVIDIA'],
        isLaptop: false,
        hasBattery: false,
        modernStandby: false,
        bitLockerEnabled: false,
        hyperVEnabled: false,
        wslEnabled: false,
        storeAvailable: true,
        xboxInstalled: true,
        gamePassInstalled: true,
        gpuDriversPresent: true,
        audioDevicesPresent: true,
        bluetoothPresent: true,
        printersPresent: true,
        networkSharesPresent: true,
        windowsUpdateHealthy: true,
      );

  factory SystemContext.detect() {
    if (!Platform.isWindows) return const SystemContext.testSafe();

    return SystemContext(
      windowsBuild:
          int.tryParse(_ps(r'[Environment]::OSVersion.Version.Build')) ?? 0,
      windowsEdition: _ps(
        r'(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName',
      ),
      cpuVendor: _ps(
        r'(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Manufacturer)',
      ),
      gpuVendors: _psLines(
        r'Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }',
      ),
      isLaptop:
          _ps(
            r'(Get-CimInstance Win32_SystemEnclosure).ChassisTypes -contains 9',
          ).toLowerCase() ==
          'true',
      hasBattery:
          _ps(
            r'@(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      modernStandby:
          _ps(
            r'powercfg /a | Select-String -Quiet "Standby \(S0 Low Power Idle\)"',
          ).toLowerCase() ==
          'true',
      bitLockerEnabled:
          _ps(
            r'(Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue).ProtectionStatus -eq "On"',
          ).toLowerCase() ==
          'true',
      hyperVEnabled:
          _ps(
            r'(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue).State -eq "Enabled"',
          ).toLowerCase() ==
          'true',
      wslEnabled:
          _ps(
            r'(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue).State -eq "Enabled"',
          ).toLowerCase() ==
          'true',
      storeAvailable:
          _ps(
            r'@(Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      xboxInstalled:
          _ps(
            r'@(Get-AppxPackage -Name Microsoft.XboxGamingOverlay -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      gamePassInstalled:
          _ps(
            r'@(Get-AppxPackage -Name Microsoft.GamingApp -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      gpuDriversPresent:
          _ps(
            r'@(Get-CimInstance Win32_VideoController | Where-Object { $_.PNPDeviceID }).Count -gt 0',
          ).toLowerCase() ==
          'true',
      audioDevicesPresent:
          _ps(
            r'@(Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      bluetoothPresent:
          _ps(
            r'@(Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      printersPresent:
          _ps(
            r'@(Get-Printer -ErrorAction SilentlyContinue).Count -gt 0',
          ).toLowerCase() ==
          'true',
      networkSharesPresent:
          _ps(
            r'@(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object Name -NotIn @("ADMIN$","C$","IPC$")).Count -gt 0',
          ).toLowerCase() ==
          'true',
      windowsUpdateHealthy:
          _ps(
            r'(Get-Service wuauserv -ErrorAction SilentlyContinue).Status -ne "Disabled"',
          ).toLowerCase() ==
          'true',
    );
  }

  final int windowsBuild;
  final String windowsEdition;
  final String cpuVendor;
  final List<String> gpuVendors;
  final bool isLaptop;
  final bool hasBattery;
  final bool modernStandby;
  final bool bitLockerEnabled;
  final bool hyperVEnabled;
  final bool wslEnabled;
  final bool storeAvailable;
  final bool xboxInstalled;
  final bool gamePassInstalled;
  final bool gpuDriversPresent;
  final bool audioDevicesPresent;
  final bool bluetoothPresent;
  final bool printersPresent;
  final bool networkSharesPresent;
  final bool windowsUpdateHealthy;
}

final class CompatibilityChecker {
  const CompatibilityChecker({required this.context});

  factory CompatibilityChecker.detected() {
    return CompatibilityChecker(context: SystemContext.detect());
  }

  final SystemContext context;

  String? blockReason(TweakDefinition tweak, TweakExecutionOptions options) {
    if (_alwaysBlocked.contains(tweak.id)) {
      return 'Blocked because this tweak can break login, input, or rollback.';
    }

    if (tweak.id == 'security.vbs' || tweak.id == 'security.memory-integrity') {
      if (context.bitLockerEnabled) {
        return 'Blocked by BitLocker recovery guard.';
      }
      if (context.hyperVEnabled || context.wslEnabled) {
        return 'Blocked because Hyper-V or WSL depends on virtualization.';
      }
    }

    if (tweak.id == 'utilities.hibernation' &&
        (context.isLaptop || context.hasBattery || context.modernStandby)) {
      return 'Blocked by laptop, battery, or Modern Standby guard.';
    }

    if (tweak.category == TweakCategory.windowsUpdateDrivers &&
        !context.windowsUpdateHealthy) {
      return 'Blocked because Windows Update service health is unknown.';
    }

    final OptimizationProfile? profile = options.sourceProfile;
    if ((profile == OptimizationProfile.compatibility ||
            profile == OptimizationProfile.gaming) &&
        _ecosystemBreakingCategories.contains(tweak.category) &&
        tweak.risk == TweakRisk.dangerous) {
      return 'Blocked because compatibility and gaming profiles must preserve Store, Xbox/Game Pass, Windows Update, drivers, audio, network, Bluetooth, and login.';
    }

    return null;
  }

  static const Set<String> _alwaysBlocked = <String>{
    'security.uac',
    'performance.ctfmon-input',
  };

  static const Set<TweakCategory> _ecosystemBreakingCategories =
      <TweakCategory>{
        TweakCategory.windowsDefender,
        TweakCategory.windowsUpdateDrivers,
        TweakCategory.networkLatency,
        TweakCategory.compatibility,
      };
}

final class TweakExecutionOptions {
  const TweakExecutionOptions({
    this.dryRun = false,
    this.includeDangerous = false,
    this.assumeYes = false,
    this.ignoreOverrides = false,
    this.sourceProfile,
    this.recordReport = true,
  });

  final bool dryRun;
  final bool includeDangerous;
  final bool assumeYes;
  final bool ignoreOverrides;
  final OptimizationProfile? sourceProfile;
  final bool recordReport;
}

final class ProfileApplyOptions {
  const ProfileApplyOptions({
    this.dryRun = false,
    this.includeDangerous = false,
    this.assumeYes = false,
    this.ignoreOverrides = false,
  });

  final bool dryRun;
  final bool includeDangerous;
  final bool assumeYes;
  final bool ignoreOverrides;
}

final class TweakResult {
  const TweakResult({
    required this.id,
    required this.state,
    this.reason,
    this.profile,
    this.backupId,
    this.error,
  });

  factory TweakResult.fromJson(Map<String, dynamic> json) {
    return TweakResult(
      id: json['id'] as String,
      state: TweakControllerState.values.byName(json['state'] as String),
      reason: json['reason'] as String?,
      profile: _profileFromJson(json['profile']),
      backupId: json['backupId'] as String?,
      error: json['error'] as String?,
    );
  }

  final String id;
  final TweakControllerState state;
  final String? reason;
  final OptimizationProfile? profile;
  final String? backupId;
  final String? error;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'state': state.name,
      if (reason != null) 'reason': reason,
      if (profile != null) 'profile': profile!.name,
      if (backupId != null) 'backupId': backupId,
      if (error != null) 'error': error,
    };
  }
}

final class ProfileReport {
  const ProfileReport({
    required this.applicationId,
    required this.startedAt,
    required this.completedAt,
    required this.results,
    this.profile,
  });

  factory ProfileReport.single(TweakResult result) {
    final DateTime now = DateTime.now().toUtc();
    return ProfileReport(
      applicationId: _newApplicationId('tweak'),
      startedAt: now,
      completedAt: now,
      results: <TweakResult>[result],
      profile: result.profile,
    );
  }

  factory ProfileReport.fromJson(Map<String, dynamic> json) {
    return ProfileReport(
      applicationId: json['applicationId'] as String,
      profile: _profileFromJson(json['profile']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      results: (json['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TweakResult.fromJson)
          .toList(growable: false),
    );
  }

  final String applicationId;
  final OptimizationProfile? profile;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<TweakResult> results;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'applicationId': applicationId,
      if (profile != null) 'profile': profile!.name,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'completedAt': completedAt.toUtc().toIso8601String(),
      'results': results.map((TweakResult result) => result.toJson()).toList(),
    };
  }
}

final class RollbackManager {
  factory RollbackManager({required Directory rootDirectory}) {
    return RollbackManager._(rootDirectory);
  }

  RollbackManager._(this._rootDirectory);

  RollbackManager.inMemory() : this._(null);

  factory RollbackManager.defaultStore() {
    final String? programData = Platform.environment['ProgramData'];
    if (programData != null && programData.isNotEmpty) {
      return RollbackManager(
        rootDirectory: Directory(
          _join(programData, <String>[
            'Revision',
            'Revision Tool',
            'tweak-controller',
          ]),
        ),
      );
    }

    return RollbackManager(rootDirectory: _fallbackRoot());
  }

  Directory? _rootDirectory;
  ProfileReport? _latestReport;

  Future<String> createBackup({
    required String tweakId,
    required bool beforeEnabled,
  }) async {
    final String backupId = _newApplicationId(tweakId.replaceAll('.', '-'));
    final Directory? root = await _writableRoot();
    if (root == null) return backupId;

    final backups = Directory(_join(root.path, <String>['backups']));
    await backups.create(recursive: true);
    final file = File(_join(backups.path, <String>['$backupId.json']));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'backupId': backupId,
        'tweakId': tweakId,
        'beforeEnabled': beforeEnabled,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return backupId;
  }

  Future<void> saveReport(ProfileReport report) async {
    _latestReport = report;

    final Directory? root = await _writableRoot();
    if (root == null) return;

    final reports = Directory(_join(root.path, <String>['reports']));
    await reports.create(recursive: true);
    final String encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert(report.toJson());
    await File(
      _join(root.path, <String>['last-report.json']),
    ).writeAsString(encoded);
    await File(
      _join(reports.path, <String>['${report.applicationId}.json']),
    ).writeAsString(encoded);
  }

  ProfileReport? latestReport() {
    if (_latestReport != null) return _latestReport;

    final Directory? root = _rootDirectory;
    if (root == null) return null;

    final file = File(_join(root.path, <String>['last-report.json']));
    if (!file.existsSync()) return null;

    try {
      final Object? decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        _latestReport = ProfileReport.fromJson(decoded);
      }
    } on Object {
      return null;
    }
    return _latestReport;
  }

  ProfileReport? reportByApplicationId(String applicationId) {
    if (_latestReport?.applicationId == applicationId) return _latestReport;

    final Directory? root = _rootDirectory;
    if (root == null) return null;

    final file = File(
      _join(root.path, <String>['reports', '$applicationId.json']),
    );
    if (!file.existsSync()) return null;

    try {
      final Object? decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) {
        return ProfileReport.fromJson(decoded);
      }
    } on Object {
      return null;
    }
    return null;
  }

  Future<Directory?> _writableRoot() async {
    final Directory? root = _rootDirectory;
    if (root == null) return null;

    try {
      await root.create(recursive: true);
      return root;
    } on FileSystemException {
      final Directory fallback = _fallbackRoot();
      await fallback.create(recursive: true);
      _rootDirectory = fallback;
      return fallback;
    }
  }
}

final class TweakController {
  TweakController({
    required this.registry,
    required this.compatibilityChecker,
    required this.rollbackManager,
    List<TweakDefinition> inventory = tweakInventory,
  }) : _inventory = Map<String, TweakDefinition>.unmodifiable(
         <String, TweakDefinition>{
           for (final TweakDefinition tweak in inventory) tweak.id: tweak,
         },
       );

  factory TweakController.production() {
    return TweakController(
      registry: TweakOperationRegistry.fromServices(),
      compatibilityChecker: CompatibilityChecker.detected(),
      rollbackManager: RollbackManager.defaultStore(),
    );
  }

  final TweakOperationRegistry registry;
  final CompatibilityChecker compatibilityChecker;
  final RollbackManager rollbackManager;
  final Map<String, TweakDefinition> _inventory;
  final Map<String, bool> _manualOverrides = <String, bool>{};

  List<TweakDefinition> get tweaks => _inventory.values.toList(growable: false);

  TweakDefinition? definitionFor(String id) => _inventory[id];

  Future<void> setOverride(String id, {required bool enabled}) async {
    _manualOverrides[id] = enabled;
  }

  Future<void> clearOverride(String id) async {
    _manualOverrides.remove(id);
  }

  bool hasOverride(String id) => _manualOverrides.containsKey(id);

  Future<TweakResult> status(String id) async {
    final TweakDefinition? tweak = _inventory[id];
    final TweakOperation? operation = registry.operationFor(id);
    if (tweak == null || operation == null) {
      return TweakResult(
        id: id,
        state: TweakControllerState.unknown,
        reason: 'Unknown tweak id.',
      );
    }

    try {
      final bool optimized = await Future<bool>.value(operation.detect());
      return TweakResult(
        id: tweak.id,
        state: optimized
            ? TweakControllerState.enabled
            : TweakControllerState.disabled,
      );
    } on Object catch (error) {
      return TweakResult(
        id: tweak.id,
        state: TweakControllerState.unknown,
        error: error.toString(),
      );
    }
  }

  Future<TweakResult> enable([
    String? id,
    TweakExecutionOptions options = const TweakExecutionOptions(),
  ]) async {
    final tweakId = id;
    if (tweakId == null) {
      return const TweakResult(
        id: '<missing>',
        state: TweakControllerState.failed,
        reason: 'Missing tweak id.',
      );
    }

    final TweakResult result = await _enable(tweakId, options);
    if (options.recordReport) {
      await rollbackManager.saveReport(ProfileReport.single(result));
    }
    return result;
  }

  Future<TweakResult> disable(
    String id, [
    TweakExecutionOptions options = const TweakExecutionOptions(),
  ]) {
    return rollback(id, options);
  }

  Future<TweakResult> verify(String id) async {
    final TweakOperation? operation = registry.operationFor(id);
    if (operation == null) {
      return TweakResult(
        id: id,
        state: TweakControllerState.unknown,
        reason: 'Unknown tweak id.',
      );
    }

    try {
      final bool verified = await Future<bool>.value(
        operation.verifyOptimized(),
      );
      return TweakResult(
        id: id,
        state: verified
            ? TweakControllerState.enabled
            : TweakControllerState.failed,
      );
    } on Object catch (error) {
      return TweakResult(
        id: id,
        state: TweakControllerState.failed,
        error: error.toString(),
      );
    }
  }

  Future<TweakResult> rollback(
    String id, [
    TweakExecutionOptions options = const TweakExecutionOptions(),
  ]) async {
    final TweakOperation? operation = registry.operationFor(id);
    if (operation == null) {
      return TweakResult(
        id: id,
        state: TweakControllerState.unknown,
        reason: 'Unknown tweak id.',
      );
    }

    TweakResult result;
    if (options.dryRun) {
      result = TweakResult(id: id, state: TweakControllerState.disabled);
    } else {
      try {
        await Future<void>.value(operation.rollback());
        result = TweakResult(id: id, state: TweakControllerState.disabled);
      } on Object catch (error) {
        result = TweakResult(
          id: id,
          state: TweakControllerState.failed,
          error: error.toString(),
        );
      }
    }

    if (options.recordReport) {
      await rollbackManager.saveReport(ProfileReport.single(result));
    }
    return result;
  }

  Future<ProfileReport> rollbackReport(ProfileReport report) async {
    final DateTime startedAt = DateTime.now().toUtc();
    final results = <TweakResult>[];
    for (final TweakResult result in report.results.reversed) {
      if (registry.contains(result.id)) {
        results.add(
          await rollback(
            result.id,
            const TweakExecutionOptions(recordReport: false),
          ),
        );
      }
    }

    final rollbackReport = ProfileReport(
      applicationId: _newApplicationId('rollback'),
      profile: report.profile,
      startedAt: startedAt,
      completedAt: DateTime.now().toUtc(),
      results: results,
    );
    await rollbackManager.saveReport(rollbackReport);
    return rollbackReport;
  }

  Future<TweakResult> _enable(String id, TweakExecutionOptions options) async {
    final TweakDefinition? tweak = _inventory[id];
    if (tweak == null) {
      return TweakResult(
        id: id,
        state: TweakControllerState.unknown,
        reason: 'Unknown tweak id.',
      );
    }

    final TweakOperation? operation = registry.operationFor(id);
    if (operation == null) {
      return TweakResult(
        id: id,
        state: TweakControllerState.failed,
        reason: 'No operation registered for tweak.',
        profile: options.sourceProfile,
      );
    }

    if (options.sourceProfile != null &&
        !options.ignoreOverrides &&
        _manualOverrides.containsKey(id)) {
      return TweakResult(
        id: id,
        state: TweakControllerState.userOverride,
        profile: options.sourceProfile,
        reason: 'Manual override is set for this tweak.',
      );
    }

    if (tweak.risk == TweakRisk.dangerous &&
        (!options.includeDangerous || !options.assumeYes)) {
      return TweakResult(
        id: id,
        state: TweakControllerState.dangerousPendingConfirmation,
        profile: options.sourceProfile,
        reason:
            'Dangerous tweak requires explicit confirmation with --include-dangerous --yes.',
      );
    }

    final String? blockReason = compatibilityChecker.blockReason(
      tweak,
      options,
    );
    if (blockReason != null) {
      return TweakResult(
        id: id,
        state: TweakControllerState.blocked,
        profile: options.sourceProfile,
        reason: blockReason,
      );
    }

    if (options.dryRun) {
      return TweakResult(
        id: id,
        state: options.sourceProfile == null
            ? TweakControllerState.enabled
            : TweakControllerState.managedByProfile,
        profile: options.sourceProfile,
        reason: 'Dry run; no operation was applied.',
      );
    }

    try {
      final bool beforeEnabled = await Future<bool>.value(operation.detect());
      final String backupId = await rollbackManager.createBackup(
        tweakId: id,
        beforeEnabled: beforeEnabled,
      );
      await Future<void>.value(operation.applyOptimized());
      final bool verified = await Future<bool>.value(
        operation.verifyOptimized(),
      );

      return TweakResult(
        id: id,
        state: verified
            ? TweakControllerState.enabled
            : TweakControllerState.failed,
        profile: options.sourceProfile,
        backupId: backupId,
        reason: verified ? null : 'Verification failed after apply.',
      );
    } on Object catch (error) {
      return TweakResult(
        id: id,
        state: TweakControllerState.failed,
        profile: options.sourceProfile,
        error: error.toString(),
      );
    }
  }
}

final class ProfileController {
  const ProfileController(this.tweaks);

  final TweakController tweaks;

  Future<ProfileReport> apply(
    OptimizationProfile profile, [
    ProfileApplyOptions options = const ProfileApplyOptions(),
  ]) async {
    final DateTime startedAt = DateTime.now().toUtc();
    final List<TweakDefinition> selected = tweaks.tweaks
        .where((TweakDefinition tweak) => tweak.profiles.contains(profile))
        .toList(growable: false);
    final results = <TweakResult>[];

    for (final tweak in selected) {
      results.add(
        await tweaks.enable(
          tweak.id,
          TweakExecutionOptions(
            dryRun: options.dryRun,
            includeDangerous: options.includeDangerous,
            assumeYes: options.assumeYes,
            ignoreOverrides: options.ignoreOverrides,
            sourceProfile: profile,
            recordReport: false,
          ),
        ),
      );
    }

    final report = ProfileReport(
      applicationId: _newApplicationId(profile.name),
      profile: profile,
      startedAt: startedAt,
      completedAt: DateTime.now().toUtc(),
      results: results,
    );
    await tweaks.rollbackManager.saveReport(report);
    return report;
  }

  Future<ProfileReport?> rollbackLast() async {
    final ProfileReport? latest = tweaks.rollbackManager.latestReport();
    if (latest == null) return null;
    return tweaks.rollbackReport(latest);
  }

  Future<ProfileReport?> rollbackApplication(String applicationId) async {
    final ProfileReport? report = tweaks.rollbackManager.reportByApplicationId(
      applicationId,
    );
    if (report == null) return null;
    return tweaks.rollbackReport(report);
  }
}

OptimizationProfile? _profileFromJson(Object? value) {
  if (value is! String) return null;
  return OptimizationProfile.values.byName(value);
}

String _newApplicationId(String prefix) {
  return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}

Directory _fallbackRoot() {
  return Directory(
    _join(Directory.systemTemp.path, <String>[
      'Revision-Tool',
      'tweak-controller',
    ]),
  );
}

String _join(String root, List<String> segments) {
  return <String>[root, ...segments].join(Platform.pathSeparator);
}

String _ps(String command) {
  try {
    final ProcessResult result = Process.runSync('powershell.exe', <String>[
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      command,
    ]);
    if (result.exitCode != 0) return '';
    return result.stdout.toString().trim();
  } on Object {
    return '';
  }
}

List<String> _psLines(String command) {
  return _ps(command)
      .split(RegExp(r'\r?\n'))
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList(growable: false);
}
