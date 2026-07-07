enum OptimizationProfile { compatibility, gaming, performance, extreme }

extension OptimizationProfileLabel on OptimizationProfile {
  String get displayName {
    return switch (this) {
      OptimizationProfile.compatibility => 'Compatibility',
      OptimizationProfile.gaming => 'Gaming',
      OptimizationProfile.performance => 'Performance',
      OptimizationProfile.extreme => 'Extreme',
    };
  }
}

enum TweakControllerState {
  enabled,
  disabled,
  blocked,
  failed,
  pendingReboot,
  unknown,
  managedByProfile,
  userOverride,
  dangerousPendingConfirmation,
}

enum TweakCategory {
  cpu,
  gpu,
  ram,
  storageNvme,
  networkLatency,
  gaming,
  services,
  scheduledTasks,
  registry,
  powerPlan,
  debloat,
  telemetry,
  windowsDefender,
  xboxGameBarGameDvr,
  windowsUpdateDrivers,
  amd,
  nvidia,
  intel,
  privacy,
  compatibility,
  experimental,
}

extension TweakCategoryLabel on TweakCategory {
  String get displayName {
    return switch (this) {
      TweakCategory.cpu => 'CPU',
      TweakCategory.gpu => 'GPU',
      TweakCategory.ram => 'RAM',
      TweakCategory.storageNvme => 'Storage/NVMe',
      TweakCategory.networkLatency => 'Network latency',
      TweakCategory.gaming => 'Gaming',
      TweakCategory.services => 'Services',
      TweakCategory.scheduledTasks => 'Scheduled Tasks',
      TweakCategory.registry => 'Registry',
      TweakCategory.powerPlan => 'Power Plan',
      TweakCategory.debloat => 'Debloat',
      TweakCategory.telemetry => 'Telemetry',
      TweakCategory.windowsDefender => 'Windows Defender',
      TweakCategory.xboxGameBarGameDvr => 'Xbox/Game Bar/Game DVR',
      TweakCategory.windowsUpdateDrivers => 'Windows Update/Drivers',
      TweakCategory.amd => 'AMD',
      TweakCategory.nvidia => 'NVIDIA',
      TweakCategory.intel => 'Intel',
      TweakCategory.privacy => 'Privacy',
      TweakCategory.compatibility => 'Compatibility',
      TweakCategory.experimental => 'Experimental',
    };
  }
}

enum TweakRisk { low, medium, high, dangerous }

extension TweakRiskLabel on TweakRisk {
  String get displayName {
    return switch (this) {
      TweakRisk.low => 'low',
      TweakRisk.medium => 'medium',
      TweakRisk.high => 'high',
      TweakRisk.dangerous => 'dangerous',
    };
  }
}

final class TweakDefinition {
  const TweakDefinition({
    required this.id,
    required this.category,
    required this.name,
    required this.technicalDescription,
    required this.expectedImpact,
    required this.risk,
    required this.profiles,
    required this.dependencies,
    required this.detection,
    required this.apply,
    required this.verify,
    required this.rollback,
    required this.logs,
    required this.reason,
    required this.warnings,
    required this.evidence,
  });

  final String id;
  final TweakCategory category;
  final String name;
  final String technicalDescription;
  final String expectedImpact;
  final TweakRisk risk;
  final List<OptimizationProfile> profiles;
  final List<String> dependencies;
  final String detection;
  final String apply;
  final String verify;
  final String rollback;
  final String logs;
  final String reason;
  final List<String> warnings;
  final List<String> evidence;
}

const String tweakInventoryYamlPath = 'additionals/tweaks/tweak_inventory.yaml';

const List<OptimizationProfile> _compatibilityPlus = <OptimizationProfile>[
  OptimizationProfile.compatibility,
  OptimizationProfile.gaming,
  OptimizationProfile.performance,
  OptimizationProfile.extreme,
];

const List<OptimizationProfile> _gamingPlus = <OptimizationProfile>[
  OptimizationProfile.gaming,
  OptimizationProfile.performance,
  OptimizationProfile.extreme,
];

const List<OptimizationProfile> _performancePlus = <OptimizationProfile>[
  OptimizationProfile.performance,
  OptimizationProfile.extreme,
];

const List<OptimizationProfile> _extremeOnly = <OptimizationProfile>[
  OptimizationProfile.extreme,
];

const List<String> _registryDependency = <String>[
  'Administrator rights',
  'Windows registry access',
];

const List<String> _registryExplorerDependency = <String>[
  'Administrator rights',
  'Windows registry access',
  'Explorer restart allowed',
];

const List<String> _powerDependency = <String>[
  'Administrator rights',
  'powercfg.exe',
  'AC power guard for laptops',
];

const List<String> _networkDependency = <String>[
  'Administrator rights',
  'Network access',
  'Windows Update service health',
];

const List<String> _tiDependency = <String>[
  'Administrator rights',
  'TrustedInstaller access',
  'Rollback snapshot',
];

const List<String> _safeWarning = <String>[
  'Back up the previous value before profile automation.',
];

const List<String> _restartWarning = <String>[
  'May require restart or sign out before verification is final.',
];

const List<String> _guardedWarning = <String>[
  'Guard with hardware and workload detection before profile automation.',
];

const List<String> _dangerousWarning = <String>[
  'Requires explicit Extreme confirmation, backup, verification, and rollback.',
];

const String _standardLogs =
    'Log detection input, requested action, exit code, registry writes, '
    'verification result, and rollback snapshot id.';

const List<TweakDefinition> tweakInventory = <TweakDefinition>[
  TweakDefinition(
    id: 'performance.powerplan',
    category: TweakCategory.powerPlan,
    name: 'Revision ultra performance power plan',
    technicalDescription:
        'Creates and activates the Revision power scheme through '
        'PerformanceService.enableReviPowerPlan.',
    expectedImpact:
        'Improves CPU response and disables selected AC power saving behavior.',
    risk: TweakRisk.medium,
    profiles: _gamingPlus,
    dependencies: _powerDependency,
    detection:
        'PerformanceService.statusReviPowerPlan checks the Revision power '
        'scheme registry key.',
    apply: 'PerformanceService.enableReviPowerPlan',
    verify: 'PerformanceService.statusReviPowerPlan',
    rollback: 'PerformanceService.disableReviPowerPlan',
    logs: _standardLogs,
    reason:
        'Gaming and higher profiles need an existing aggressive AC power baseline.',
    warnings: _restartWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
      'playbook/src/Configuration/Tasks/start.yml',
    ],
  ),
  TweakDefinition(
    id: 'performance.powerplan-states-c6',
    category: TweakCategory.cpu,
    name: 'C-state latency tuning',
    technicalDescription:
        'Changes Revision power plan idle promote and demote thresholds and '
        'removes the legacy processor Capabilities value.',
    expectedImpact:
        'Reduces latency from deep idle transitions on tuned desktop systems.',
    risk: TweakRisk.high,
    profiles: _gamingPlus,
    dependencies: _powerDependency,
    detection:
        'PerformanceService.statusReviPowerPlanC6States reads idle threshold '
        'settings under the Revision power scheme.',
    apply: 'PerformanceService.enableReviPowerPlanC6States',
    verify: 'PerformanceService.statusReviPowerPlanC6States',
    rollback: 'PerformanceService.disableReviPowerPlanC6States',
    logs: _standardLogs,
    reason:
        'Gaming and Performance profiles prioritize latency over idle efficiency.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.superfetch',
    category: TweakCategory.services,
    name: 'SysMain and Superfetch',
    technicalDescription:
        'Controls SysMain, ReadyBoost, prefetcher, and related cache policy '
        'registry values.',
    expectedImpact:
        'Can reduce background disk and memory churn on SSD-focused systems.',
    risk: TweakRisk.high,
    profiles: _performancePlus,
    dependencies: _registryDependency,
    detection:
        'PerformanceService.statusSuperfetch checks SysMain and ReadyBoost '
        'service start values.',
    apply: 'PerformanceService.disableSuperfetch',
    verify: 'PerformanceService.statusSuperfetch',
    rollback: 'PerformanceService.enableSuperfetch',
    logs: _standardLogs,
    reason:
        'Performance profile can trade Windows caching behavior for lower background load.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.memory-compression',
    category: TweakCategory.ram,
    name: 'Memory Compression',
    technicalDescription:
        'Uses Enable-MMAgent and Disable-MMAgent to control Windows memory '
        'compression.',
    expectedImpact:
        'Can reduce CPU overhead at the cost of higher memory pressure.',
    risk: TweakRisk.high,
    profiles: _performancePlus,
    dependencies: <String>[
      'Administrator rights',
      'PowerShell MMAgent',
      'RAM capacity guard',
    ],
    detection:
        'PerformanceService.statusMemoryCompression checks the Memory '
        'Compression process.',
    apply: 'PerformanceService.disableMemoryCompression',
    verify: 'PerformanceService.statusMemoryCompression',
    rollback: 'PerformanceService.enableMemoryCompression',
    logs: _standardLogs,
    reason:
        'Performance and Extreme may disable it only when memory headroom is adequate.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.intel-tsx',
    category: TweakCategory.intel,
    name: 'Intel TSX',
    technicalDescription:
        'Controls the DisableTsx kernel registry value for compatible Intel CPUs.',
    expectedImpact:
        'May improve specific transactional memory workloads and benchmarks.',
    risk: TweakRisk.dangerous,
    profiles: _extremeOnly,
    dependencies: <String>['Intel CPU guard', 'Administrator rights', 'Reboot'],
    detection:
        'PerformanceService.statusIntelTSX reads DisableTsx under Session '
        'Manager Kernel.',
    apply: 'PerformanceService.enableIntelTSX',
    verify: 'PerformanceService.statusIntelTSX',
    rollback: 'PerformanceService.disableIntelTSX',
    logs: _standardLogs,
    reason:
        'Extreme exposes legacy and hardware-specific tweaks behind confirmation.',
    warnings: _dangerousWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
      'lib/features/tweaks/performance/performance_page.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.swapchain-fso',
    category: TweakCategory.gaming,
    name: 'Fullscreen Optimizations',
    technicalDescription:
        'Normalizes GameConfigStore fullscreen optimization values for current '
        'and default users.',
    expectedImpact:
        'Keeps compatible fullscreen presentation behavior for games.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryDependency,
    detection:
        'PerformanceService.statusFullscreenOptimization reads '
        'GameDVR_FSEBehaviorMode.',
    apply: 'PerformanceService.enableFullscreenOptimization',
    verify: 'PerformanceService.statusFullscreenOptimization',
    rollback: 'PerformanceService.disableFullscreenOptimization',
    logs: _standardLogs,
    reason: 'All profiles keep a compatible gaming presentation baseline.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.swapchain-wo',
    category: TweakCategory.gaming,
    name: 'Windowed Optimizations',
    technicalDescription:
        'Controls DirectXUserGlobalSettings SwapEffectUpgradeEnable.',
    expectedImpact:
        'Improves modern windowed and borderless game presentation.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryDependency,
    detection:
        'PerformanceService.statusWindowedOptimization reads '
        'DirectXUserGlobalSettings.',
    apply: 'PerformanceService.enableWindowedOptimization',
    verify: 'PerformanceService.statusWindowedOptimization',
    rollback: 'PerformanceService.disableWindowedOptimization',
    logs: _standardLogs,
    reason:
        'All profiles should preserve modern compatible presentation behavior.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.swapchain-mpo',
    category: TweakCategory.gpu,
    name: 'Multiplane Overlay',
    technicalDescription:
        'Controls DWM OverlayTestMode to enable or disable multiplane overlay.',
    expectedImpact:
        'Can reduce flicker, overlay issues, or game capture stutter.',
    risk: TweakRisk.medium,
    profiles: _gamingPlus,
    dependencies: _registryDependency,
    detection: 'PerformanceService.statusMPO reads DWM OverlayTestMode.',
    apply: 'PerformanceService.disableMPO',
    verify: 'PerformanceService.statusMPO',
    rollback: 'PerformanceService.enableMPO',
    logs: _standardLogs,
    reason:
        'Gaming profiles expose display-path tweaks while preserving rollback.',
    warnings: _restartWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.background-apps',
    category: TweakCategory.services,
    name: 'Background Apps',
    technicalDescription:
        'Controls app background execution policy and user background toggles.',
    expectedImpact: 'Reduces resident app activity and background wakeups.',
    risk: TweakRisk.high,
    profiles: _performancePlus,
    dependencies: _registryDependency,
    detection:
        'PerformanceService.statusBackgroundApps reads AppPrivacy, Search, '
        'and BackgroundAccessApplications values.',
    apply: 'PerformanceService.disableBackgroundApps',
    verify: 'PerformanceService.statusBackgroundApps',
    rollback: 'PerformanceService.enableBackgroundApps',
    logs: _standardLogs,
    reason:
        'Existing global control is too broad for Compatibility and Gaming allowlists.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.ctfmon-input',
    category: TweakCategory.compatibility,
    name: 'CTFMon Input',
    technicalDescription:
        'Controls Microsoft input service values and TextInputManagementService DLL.',
    expectedImpact: 'Can reduce text input service activity.',
    risk: TweakRisk.dangerous,
    profiles: _performancePlus,
    dependencies: _registryDependency,
    detection:
        'PerformanceService.statusCtfmonInput reads Microsoft Input policy '
        'values.',
    apply: 'PerformanceService.disableCtfmonInput',
    verify: 'PerformanceService.statusCtfmonInput',
    rollback: 'PerformanceService.enableCtfmonInput',
    logs: _standardLogs,
    reason: 'Only aggressive profiles should touch input infrastructure.',
    warnings: _dangerousWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.ntfs-last-access',
    category: TweakCategory.storageNvme,
    name: 'NTFS Last Access Updates',
    technicalDescription:
        'Uses fsutil to disable last access timestamp updates.',
    expectedImpact: 'Reduces filesystem metadata writes.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: <String>['Administrator rights', 'fsutil.exe'],
    detection:
        'PerformanceService.statusLastTimeAccessNTFS reads filesystem policy.',
    apply: 'PerformanceService.disableLastTimeAccessNTFS',
    verify: 'PerformanceService.statusLastTimeAccessNTFS',
    rollback: 'PerformanceService.enableLastTimeAccessNTFS',
    logs: _standardLogs,
    reason: 'Safe storage optimization for all profiles.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
      'playbook/src/Configuration/Tasks/final.yml',
    ],
  ),
  TweakDefinition(
    id: 'performance.ntfs-8dot3-naming',
    category: TweakCategory.storageNvme,
    name: 'NTFS 8.3 Naming',
    technicalDescription:
        'Uses fsutil to disable 8.3 name creation where safe.',
    expectedImpact: 'Reduces legacy filename generation overhead.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: <String>[
      'Administrator rights',
      'fsutil.exe',
      'Legacy application guard',
    ],
    detection:
        'PerformanceService.status8dot3NamingNTFS reads NtfsDisable8dot3NameCreation.',
    apply: 'PerformanceService.disable8dot3NamingNTFS',
    verify: 'PerformanceService.status8dot3NamingNTFS',
    rollback: 'PerformanceService.enable8dot3NamingNTFS',
    logs: _standardLogs,
    reason: 'Compatibility profile may apply it when legacy app guards pass.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
      'playbook/src/Configuration/Tasks/final.yml',
    ],
  ),
  TweakDefinition(
    id: 'performance.ntfs-memory-usage',
    category: TweakCategory.storageNvme,
    name: 'NTFS Memory Usage',
    technicalDescription: 'Uses fsutil to set NTFS memory usage policy.',
    expectedImpact:
        'Allows more filesystem cache behavior for storage throughput.',
    risk: TweakRisk.medium,
    profiles: _performancePlus,
    dependencies: <String>[
      'Administrator rights',
      'fsutil.exe',
      'RAM capacity guard',
    ],
    detection:
        'PerformanceService.statusMemoryUsageNTFS reads NtfsMemoryUsage.',
    apply: 'PerformanceService.enableMemoryUsageNTFS',
    verify: 'PerformanceService.statusMemoryUsageNTFS',
    rollback: 'PerformanceService.disableMemoryUsageNTFS',
    logs: _standardLogs,
    reason:
        'Performance profile can spend more memory on filesystem throughput.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'performance.service-grouping',
    category: TweakCategory.services,
    name: 'Service Grouping',
    technicalDescription:
        'Controls SvcHostSplitThresholdInKB and service SvcHostSplitDisable values.',
    expectedImpact:
        'Reduces service host process count while preserving an allowlist.',
    risk: TweakRisk.medium,
    profiles: _gamingPlus,
    dependencies: _tiDependency,
    detection:
        'PerformanceService.statusServicesGrouping reads service grouping registry state.',
    apply:
        'PerformanceService.setServiceGroupingMode(ServiceGrouping.recommended)',
    verify: 'PerformanceService.statusServicesGrouping',
    rollback:
        'PerformanceService.setServiceGroupingMode(ServiceGrouping.disabled)',
    logs: _standardLogs,
    reason:
        'Gaming and higher profiles need a controlled background process reduction.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
      'playbook/src/Configuration/Tasks/final.yml',
    ],
  ),
  TweakDefinition(
    id: 'performance.background-window-message-rate-limit',
    category: TweakCategory.gaming,
    name: 'Background Window Message Rate Limit',
    technicalDescription:
        'Writes RawMouseThrottleEnabled and RawMouseThrottleDuration for the '
        'current user.',
    expectedImpact:
        'Can improve input consistency during background window activity.',
    risk: TweakRisk.medium,
    profiles: _gamingPlus,
    dependencies: _registryDependency,
    detection:
        'PerformanceService.statusBackgroundWindowMessageRateLimit reads mouse throttle state.',
    apply: 'PerformanceService.setBackgroundWindowMessageRateLimit(8)',
    verify: 'PerformanceService.statusBackgroundWindowMessageRateLimit',
    rollback: 'Restore previous RawMouseThrottle values from tweak backup.',
    logs: _standardLogs,
    reason: 'Gaming profiles target input consistency and 1 percent lows.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/performance/performance_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.notification',
    category: TweakCategory.privacy,
    name: 'Notifications',
    technicalDescription:
        'Sets notification mode through PersonalizationService.setNotificationMode.',
    expectedImpact:
        'Reduces notification noise while allowing compatible operation.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryExplorerDependency,
    detection:
        'PersonalizationService.statusNotification reads toast and notification center state.',
    apply:
        'PersonalizationService.setNotificationMode(NotificationMode.offMinimal)',
    verify: 'PersonalizationService.statusNotification',
    rollback: 'PersonalizationService.setNotificationMode(NotificationMode.on)',
    logs: _standardLogs,
    reason:
        'Compatibility and higher profiles reduce prompts without removing shell support.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.legacy-balloon',
    category: TweakCategory.compatibility,
    name: 'Legacy Balloon Notifications',
    technicalDescription: 'Controls EnableLegacyBalloonNotifications.',
    expectedImpact:
        'Keeps modern notification behavior and removes legacy UI noise.',
    risk: TweakRisk.low,
    profiles: _gamingPlus,
    dependencies: _registryExplorerDependency,
    detection:
        'PersonalizationService.statusLegacyBalloon reads Explorer policy.',
    apply: 'PersonalizationService.disableLegacyBalloon',
    verify: 'PersonalizationService.statusLegacyBalloon',
    rollback: 'PersonalizationService.enableLegacyBalloon',
    logs: _standardLogs,
    reason:
        'Gaming and higher profiles remove nonessential shell legacy surfaces.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.screen-edge-swipe',
    category: TweakCategory.compatibility,
    name: 'Screen Edge Swipe',
    technicalDescription: 'Controls EdgeUI AllowEdgeSwipe policy.',
    expectedImpact:
        'Prevents accidental edge gestures during games or fullscreen use.',
    risk: TweakRisk.medium,
    profiles: _gamingPlus,
    dependencies: <String>[
      'Administrator rights',
      'Touch/tablet guard',
      'Windows registry access',
    ],
    detection:
        'PersonalizationService.statusScreenEdgeSwipe reads EdgeUI policy.',
    apply: 'PersonalizationService.disableScreenEdgeSwipe',
    verify: 'PersonalizationService.statusScreenEdgeSwipe',
    rollback: 'PersonalizationService.enableScreenEdgeSwipe',
    logs: _standardLogs,
    reason:
        'Gaming profiles reduce accidental shell gestures with tablet guard.',
    warnings: _guardedWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.new-context-menu',
    category: TweakCategory.compatibility,
    name: 'Windows 11 Context Menu',
    technicalDescription:
        'Controls the CLSID override that restores the legacy Explorer context menu.',
    expectedImpact: 'Reduces Explorer interaction friction for power users.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryExplorerDependency,
    detection:
        'PersonalizationService.statusNewContextMenu reads the Explorer CLSID override.',
    apply: 'PersonalizationService.disableNewContextMenu',
    verify: 'PersonalizationService.statusNewContextMenu',
    rollback: 'PersonalizationService.enableNewContextMenu',
    logs: _standardLogs,
    reason:
        'All profiles may prefer direct shell actions over the modern compact menu.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.input-personalization',
    category: TweakCategory.privacy,
    name: 'Input Personalization',
    technicalDescription:
        'Controls implicit ink/text collection and trained data store registry values.',
    expectedImpact:
        'Reduces personalization telemetry and background data collection.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryDependency,
    detection:
        'PersonalizationService.statusInputPersonalization reads InputPersonalization policy.',
    apply: 'PersonalizationService.disableInputPersonalization',
    verify: 'PersonalizationService.statusInputPersonalization',
    rollback: 'PersonalizationService.enableInputPersonalization',
    logs: _standardLogs,
    reason: 'All profiles reduce nonessential personalization data collection.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
      'playbook/src/Configuration/Tasks/registry/explorer/win-settings.yml',
    ],
  ),
  TweakDefinition(
    id: 'personalization.caps-lock',
    category: TweakCategory.compatibility,
    name: 'Caps Lock',
    technicalDescription: 'Controls the keyboard layout Scancode Map value.',
    expectedImpact:
        'Optional keyboard behavior change for users who never use Caps Lock.',
    risk: TweakRisk.medium,
    profiles: _extremeOnly,
    dependencies: <String>[
      'Administrator rights',
      'Keyboard layout guard',
      'Windows registry access',
    ],
    detection: 'PersonalizationService.statusCapsLock reads Scancode Map.',
    apply: 'PersonalizationService.disableCapsLock',
    verify: 'PersonalizationService.statusCapsLock',
    rollback: 'PersonalizationService.enableCapsLock',
    logs: _standardLogs,
    reason:
        'This is user-preference behavior, so profiles should only expose it manually.',
    warnings: _restartWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.explorer-home',
    category: TweakCategory.debloat,
    name: 'Explorer Home',
    technicalDescription: 'Controls Explorer Home namespace pinning.',
    expectedImpact: 'Removes a low-value Explorer entry point.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryExplorerDependency,
    detection:
        'PersonalizationService.statusExplorerHome reads the Explorer Home CLSID pin.',
    apply: 'PersonalizationService.disableExplorerHome',
    verify: 'PersonalizationService.statusExplorerHome',
    rollback: 'PersonalizationService.enableExplorerHome',
    logs: _standardLogs,
    reason:
        'Compatibility profile can clean shell noise without removing core components.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'personalization.explorer-gallery',
    category: TweakCategory.debloat,
    name: 'Explorer Gallery',
    technicalDescription: 'Controls Explorer Gallery namespace pinning.',
    expectedImpact: 'Removes a low-value Explorer media entry point.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _registryExplorerDependency,
    detection:
        'PersonalizationService.statusExplorerGallery reads the Explorer Gallery CLSID pin.',
    apply: 'PersonalizationService.disableExplorerGallery',
    verify: 'PersonalizationService.statusExplorerGallery',
    rollback: 'PersonalizationService.enableExplorerGallery',
    logs: _standardLogs,
    reason:
        'Compatibility profile can clean shell noise without removing core components.',
    warnings: _safeWarning,
    evidence: <String>[
      'lib/features/tweaks/personalization/personalization_service.dart',
    ],
  ),
  TweakDefinition(
    id: 'security.defender',
    category: TweakCategory.windowsDefender,
    name: 'Windows Defender',
    technicalDescription:
        'Controls Defender policy, services, package removal, and SmartScreen state.',
    expectedImpact:
        'Reduces security stack overhead only when user accepts major risk.',
    risk: TweakRisk.dangerous,
    profiles: _extremeOnly,
    dependencies: _tiDependency,
    detection:
        'SecurityService.statusDefender checks package removal, DisableAntiSpyware, and WinDefend.',
    apply: 'SecurityService.disableDefenderCLI',
    verify: 'SecurityService.statusDefender',
    rollback: 'SecurityService.enableDefender',
    logs: _standardLogs,
    reason:
        'Only Extreme may reduce Defender, and only after explicit confirmation.',
    warnings: _dangerousWarning,
    evidence: <String>[
      'lib/features/tweaks/security/security_service.dart',
      'packages/defender-removal-amd64.yaml',
      'packages/defender-removal-arm64.yaml',
    ],
  ),
  TweakDefinition(
    id: 'security.uac',
    category: TweakCategory.compatibility,
    name: 'User Account Control',
    technicalDescription:
        'Controls UAC and consent prompt policy values under Policies/System.',
    expectedImpact:
        'Can reduce prompts, but weakens Windows elevation boundaries.',
    risk: TweakRisk.dangerous,
    profiles: _extremeOnly,
    dependencies: _registryDependency,
    detection: 'SecurityService.statusUAC reads EnableLUA.',
    apply: 'SecurityService.disableUAC',
    verify: 'SecurityService.statusUAC',
    rollback: 'SecurityService.enableUAC',
    logs: _standardLogs,
    reason: 'UAC changes are preserved as manual Extreme-only toggles.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/security/security_service.dart'],
  ),
  TweakDefinition(
    id: 'security.mitigation.meltdown-spectre',
    category: TweakCategory.cpu,
    name: 'Meltdown and Spectre Mitigations',
    technicalDescription:
        'Controls FeatureSettingsOverride bits through SecurityService.disableMitigation.',
    expectedImpact: 'May improve CPU performance on affected workloads.',
    risk: TweakRisk.dangerous,
    profiles: _performancePlus,
    dependencies: <String>[
      'Administrator rights',
      'CPU vulnerability guard',
      'Restore point recommended',
    ],
    detection:
        'SecurityService.isMitigationEnabled(Mitigation.meltdownSpectre).',
    apply: 'SecurityService.disableMitigation(Mitigation.meltdownSpectre)',
    verify: 'SecurityService.isMitigationEnabled(Mitigation.meltdownSpectre)',
    rollback: 'SecurityService.enableMitigation(Mitigation.meltdownSpectre)',
    logs: _standardLogs,
    reason:
        'Performance may expose mitigation changes only with guard and warning.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/security/security_service.dart'],
  ),
  TweakDefinition(
    id: 'security.mitigation.downfall',
    category: TweakCategory.cpu,
    name: 'Downfall Mitigation',
    technicalDescription:
        'Controls the Downfall FeatureSettingsOverride bit through SecurityService.',
    expectedImpact: 'May improve CPU performance on affected Intel systems.',
    risk: TweakRisk.dangerous,
    profiles: _performancePlus,
    dependencies: <String>[
      'Intel CPU guard',
      'Administrator rights',
      'Restore point recommended',
    ],
    detection: 'SecurityService.isMitigationEnabled(Mitigation.downfall).',
    apply: 'SecurityService.disableMitigation(Mitigation.downfall)',
    verify: 'SecurityService.isMitigationEnabled(Mitigation.downfall)',
    rollback: 'SecurityService.enableMitigation(Mitigation.downfall)',
    logs: _standardLogs,
    reason:
        'Performance may expose mitigation changes only with guard and warning.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/security/security_service.dart'],
  ),
  TweakDefinition(
    id: 'security.vbs',
    category: TweakCategory.experimental,
    name: 'Virtualization Based Security',
    technicalDescription:
        'Controls Device Guard policy and BCD values for VBS launch behavior.',
    expectedImpact: 'Can reduce virtualization security overhead.',
    risk: TweakRisk.dangerous,
    profiles: _performancePlus,
    dependencies: <String>[
      'Administrator rights',
      'Hyper-V and WSL guard',
      'BitLocker recovery guard',
    ],
    detection:
        'SecurityService.statusVbs reads Device Guard and Memory Integrity state.',
    apply: 'SecurityService.disableVbs',
    verify: 'SecurityService.statusVbs',
    rollback: 'SecurityService.enableVbs',
    logs: _standardLogs,
    reason:
        'Performance may expose VBS changes only when virtualization dependencies permit.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/security/security_service.dart'],
  ),
  TweakDefinition(
    id: 'security.memory-integrity',
    category: TweakCategory.experimental,
    name: 'Memory Integrity',
    technicalDescription:
        'Controls HypervisorEnforcedCodeIntegrity Enabled and related state values.',
    expectedImpact:
        'Can reduce HVCI overhead on systems that do not require it.',
    risk: TweakRisk.dangerous,
    profiles: _performancePlus,
    dependencies: <String>[
      'Administrator rights',
      'Driver compatibility guard',
      'BitLocker recovery guard',
    ],
    detection:
        'SecurityService.statusMemoryIntegrity reads HVCI Enabled state.',
    apply: 'SecurityService.disableMemoryIntegrity',
    verify: 'SecurityService.statusMemoryIntegrity',
    rollback: 'SecurityService.enableMemoryIntegrity',
    logs: _standardLogs,
    reason:
        'Performance may expose HVCI changes only with driver and rollback guards.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/security/security_service.dart'],
  ),
  TweakDefinition(
    id: 'updates.certificates',
    category: TweakCategory.windowsUpdateDrivers,
    name: 'Root Certificates Update',
    technicalDescription:
        'Downloads the Windows root certificate SST and imports root stores.',
    expectedImpact: 'Improves compatibility with software and TLS chains.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _networkDependency,
    detection:
        'No status getter; verify command success and certificate import result.',
    apply: 'UpdatesService.updateCertificates',
    verify: 'Process exit code and certificate store inspection',
    rollback:
        'No direct rollback method; remove imported certificates manually if needed.',
    logs: _standardLogs,
    reason:
        'Compatibility profile should keep trust store compatibility healthy.',
    warnings: _safeWarning,
    evidence: <String>['lib/features/tweaks/updates/updates_service.dart'],
  ),
  TweakDefinition(
    id: 'updates.kgl',
    category: TweakCategory.xboxGameBarGameDvr,
    name: 'Known Game List Update',
    technicalDescription:
        'Fetches Microsoft Known Game List settings and writes KGL registry values.',
    expectedImpact:
        'Improves Windows game detection and Game DVR/Game Mode behavior.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _networkDependency,
    detection:
        'No status getter; verify KGL registry version and API response.',
    apply: 'UpdatesService.updateKGL',
    verify: 'KGL registry Version and Hash values',
    rollback: 'Restore previous KGL registry values from tweak backup.',
    logs: _standardLogs,
    reason:
        'All profiles preserve the gaming ecosystem while improving detection.',
    warnings: _safeWarning,
    evidence: <String>['lib/features/tweaks/updates/updates_service.dart'],
  ),
  TweakDefinition(
    id: 'updates.wu-pause-updates',
    category: TweakCategory.windowsUpdateDrivers,
    name: 'Pause Windows Update',
    technicalDescription:
        'Writes Windows Update pause timestamps through UpdatesService.',
    expectedImpact:
        'Prevents update activity and reboot prompts during tuned sessions.',
    risk: TweakRisk.dangerous,
    profiles: _extremeOnly,
    dependencies: _registryDependency,
    detection:
        'UpdatesService.statusPauseUpdatesWU checks PauseUpdatesExpiryTime.',
    apply: 'UpdatesService.enablePauseUpdatesWU',
    verify: 'UpdatesService.statusPauseUpdatesWU',
    rollback: 'UpdatesService.disablePauseUpdatesWU',
    logs: _standardLogs,
    reason:
        'Windows Update is protected unless Extreme confirmation is provided.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/updates/updates_service.dart'],
  ),
  TweakDefinition(
    id: 'updates.wu-visibility',
    category: TweakCategory.windowsUpdateDrivers,
    name: 'Windows Update Settings Visibility',
    technicalDescription: 'Hides or unhides the Windows Update settings page.',
    expectedImpact:
        'Reduces accidental Windows Update changes in locked-down profiles.',
    risk: TweakRisk.high,
    profiles: _extremeOnly,
    dependencies: _registryDependency,
    detection:
        'UpdatesService.statusVisibilityWU checks SettingsPageVisibility.',
    apply: 'UpdatesService.disableVisibilityWU',
    verify: 'UpdatesService.statusVisibilityWU',
    rollback: 'UpdatesService.enableVisibilityWU',
    logs: _standardLogs,
    reason: 'Hiding update controls is too aggressive outside Extreme.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/updates/updates_service.dart'],
  ),
  TweakDefinition(
    id: 'updates.wu-drivers',
    category: TweakCategory.windowsUpdateDrivers,
    name: 'Windows Update Driver Delivery',
    technicalDescription:
        'Controls driver search, metadata, and ExcludeWUDriversInQualityUpdate policy.',
    expectedImpact:
        'Prevents Windows Update from changing GPU and device drivers.',
    risk: TweakRisk.dangerous,
    profiles: _extremeOnly,
    dependencies: _registryDependency,
    detection:
        'UpdatesService.statusDriversWU reads PreventDeviceMetadataFromNetwork.',
    apply: 'UpdatesService.disableDriversWU',
    verify: 'UpdatesService.statusDriversWU',
    rollback: 'UpdatesService.enableDriversWU',
    logs: _standardLogs,
    reason: 'Driver blocking requires explicit Extreme confirmation.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/updates/updates_service.dart'],
  ),
  TweakDefinition(
    id: 'utilities.hibernation',
    category: TweakCategory.powerPlan,
    name: 'Hibernation',
    technicalDescription:
        'Controls HibernateEnabled, ShowHibernateOption, and powercfg hibernation state.',
    expectedImpact:
        'Frees disk space and removes hibernation resume overhead on desktops.',
    risk: TweakRisk.high,
    profiles: _performancePlus,
    dependencies: _powerDependency,
    detection: 'UtilitiesService.statusHibernation reads HibernateEnabled.',
    apply: 'UtilitiesService.disableHibernation',
    verify: 'UtilitiesService.statusHibernation',
    rollback: 'UtilitiesService.enableHibernation',
    logs: _standardLogs,
    reason:
        'Performance profile can disable hibernation when desktop and standby guards pass.',
    warnings: _guardedWarning,
    evidence: <String>['lib/features/tweaks/utilities/utilities_service.dart'],
  ),
  TweakDefinition(
    id: 'utilities.fast-startup',
    category: TweakCategory.powerPlan,
    name: 'Fast Startup',
    technicalDescription:
        'Controls HiberbootEnabled policy and session manager values.',
    expectedImpact:
        'Avoids hybrid boot state that can retain driver and kernel issues.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _powerDependency,
    detection: 'UtilitiesService.statusFastStartup reads HiberbootEnabled.',
    apply: 'UtilitiesService.disableFastStartup',
    verify: 'UtilitiesService.statusFastStartup',
    rollback: 'UtilitiesService.enableFastStartup',
    logs: _standardLogs,
    reason: 'All profiles prefer deterministic cold boot behavior.',
    warnings: _safeWarning,
    evidence: <String>['lib/features/tweaks/utilities/utilities_service.dart'],
  ),
  TweakDefinition(
    id: 'utilities.modern-standby',
    category: TweakCategory.powerPlan,
    name: 'Modern Standby',
    technicalDescription:
        'Controls PlatformAoAcOverride to enable or disable Modern Standby.',
    expectedImpact:
        'Can reduce standby drain or latency surprises on selected systems.',
    risk: TweakRisk.dangerous,
    profiles: _performancePlus,
    dependencies: <String>[
      'Administrator rights',
      'Laptop and Modern Standby guard',
      'Windows registry access',
    ],
    detection:
        'UtilitiesService.statusModernStandby reads PlatformAoAcOverride.',
    apply: 'UtilitiesService.disableModernStandby',
    verify: 'UtilitiesService.statusModernStandby',
    rollback: 'UtilitiesService.enableModernStandby',
    logs: _standardLogs,
    reason: 'Only aggressive profiles should touch standby platform behavior.',
    warnings: _dangerousWarning,
    evidence: <String>['lib/features/tweaks/utilities/utilities_service.dart'],
  ),
  TweakDefinition(
    id: 'utilities.tm-monitoring',
    category: TweakCategory.services,
    name: 'Task Manager Monitoring',
    technicalDescription:
        'Controls GraphicsPerfSvc, Ndu, and DPS service startup values.',
    expectedImpact: 'Reduces monitoring services that can run during gameplay.',
    risk: TweakRisk.medium,
    profiles: _gamingPlus,
    dependencies: _registryDependency,
    detection:
        'UtilitiesService.statusTMMonitoring reads GraphicsPerfSvc and Ndu service state.',
    apply: 'UtilitiesService.disableTMMonitoring',
    verify: 'UtilitiesService.statusTMMonitoring',
    rollback: 'UtilitiesService.enableTMMonitoring',
    logs: _standardLogs,
    reason:
        'Gaming profiles reduce nonessential monitoring without touching drivers.',
    warnings: _guardedWarning,
    evidence: <String>['lib/features/tweaks/utilities/utilities_service.dart'],
  ),
  TweakDefinition(
    id: 'utilities.usage-reporting',
    category: TweakCategory.telemetry,
    name: 'Usage Reporting',
    technicalDescription:
        'Controls diagnostic event channels, SleepStudyDisabled, DPS, diagsvc, '
        'WdiServiceHost, and WdiSystemHost.',
    expectedImpact:
        'Reduces diagnostic reporting and background diagnostic services.',
    risk: TweakRisk.low,
    profiles: _compatibilityPlus,
    dependencies: _tiDependency,
    detection: 'UtilitiesService.statusUsageReporting reads DPS service state.',
    apply: 'UtilitiesService.disableUsageReporting',
    verify: 'UtilitiesService.statusUsageReporting',
    rollback: 'UtilitiesService.enableUsageReporting',
    logs: _standardLogs,
    reason:
        'Compatibility profile reduces nonessential diagnostics while preserving core services.',
    warnings: _safeWarning,
    evidence: <String>['lib/features/tweaks/utilities/utilities_service.dart'],
  ),
  TweakDefinition(
    id: 'playbook.patches',
    category: TweakCategory.windowsUpdateDrivers,
    name: 'Main Playbook Patches',
    technicalDescription:
        'Runs TweaksPatchesCommand, which disables WU driver delivery and pauses updates.',
    expectedImpact:
        'Applies current playbook micro patches without a full playbook release.',
    risk: TweakRisk.dangerous,
    profiles: _extremeOnly,
    dependencies: _registryDependency,
    detection:
        'No direct status getter; verify underlying WU pause and driver states.',
    apply: 'TweaksPatchesCommand.run',
    verify:
        'UpdatesService.statusDriversWU and UpdatesService.statusPauseUpdatesWU',
    rollback:
        'UpdatesService.enableDriversWU and UpdatesService.disablePauseUpdatesWU',
    logs: _standardLogs,
    reason:
        'Aggregate update patches are represented so the future controller hides no tweak.',
    warnings: _dangerousWarning,
    evidence: <String>[
      'lib/features/tweaks/tweaks_command.dart',
      'playbook/src/Configuration/Tasks/final.yml',
    ],
  ),
];

final Set<String> tweakControllerInventoryIds = Set<String>.unmodifiable(
  tweakInventory.map((tweak) => tweak.id),
);

Map<OptimizationProfile, List<TweakDefinition>> buildTweakProfileMatrix(
  List<TweakDefinition> tweaks,
) {
  return Map<OptimizationProfile, List<TweakDefinition>>.unmodifiable(
    <OptimizationProfile, List<TweakDefinition>>{
      for (final OptimizationProfile profile in OptimizationProfile.values)
        profile: tweaks
            .where((TweakDefinition tweak) => tweak.profiles.contains(profile))
            .toList(growable: false),
    },
  );
}
