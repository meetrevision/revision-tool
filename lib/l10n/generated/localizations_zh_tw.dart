import 'localizations.dart';

/// The translations for SimplifiedChinese (`zh_tw`).
class ReviLocalizationsZh_tw extends ReviLocalizations {
  ReviLocalizationsZh([String locale = 'zh_tw']) : super(locale);

  @override
  String get unsupportedTitle => '错误';

  @override
  String get unsupportedContent => '检测到不支持的构建';

  @override
  String get okButton => 'OK';

  @override
  String get notNowButton => '稍后';

  @override
  String get restartDialog => '您必须重新启动应用程序才能使更改生效';

  @override
  String get moreInformation => '更多信息';

  @override
  String get onStatus => '开启';

  @override
  String get offStatus => '关闭';

  @override
  String get pageHome => '主菜单';

  @override
  String get pageSecurity => '安全';

  @override
  String get pageUsability => '易用性';

  @override
  String get pagePerformance => '性能';

  @override
  String get pageUpdates => 'Windows 更新';

  @override
  String get pageMiscellaneous => '杂项';

  @override
  String get pageSettings => '设置';

  @override
  String get suggestionBoxPlaceholder => '查找设置';

  @override
  String get homeWelcome => '欢迎使用  Revision';

  @override
  String get homeDescription => '一款个性化您的ReviOS体验的工具';

  @override
  String get homeReviLink => '关于 Revision';

  @override
  String get homeReviFAQLink => '查看FAQ';

  @override
  String get securityWDLabel => 'Windows 安全中心';

  @override
  String get securityWDDescription => 'Windows 安全中心将会保护您的电脑。保护程序将在后台不断运行，对性能产生影响';

  @override
  String get securityWDButton => '停止保护';

  @override
  String get securityDialog => '请在完全禁用 Windows 安全中心之前，禁用所有保护功能';

  @override
  String get securityUACLabel => '用户账户控制';

  @override
  String get securityUACDescription => '在管理员授权提升权限之前，将应用程序限制为标准用户权限';

  @override
  String get securitySMLabel => '撤销 Spectre & Meltdown';

  @override
  String get securitySMDescription => '可撤销 Spectre 和 Meltdown 漏洞的修补程序';

  @override
  String get usabilityNotifLabel => 'Windows 通知';

  @override
  String get usabilityNotifDescription => '完全关闭 Windows 通知';

  @override
  String get usabilityLBNLabel => '旧版本通知气泡';

  @override
  String get usabilityLBNDescription => '任务栏上的托盘程序使用气泡通知，而不是弹出通知';

  @override
  String get usabilityITPLabel => '墨迹书写和键入个性化';

  @override
  String get usabilityITPDescription => 'Windows 将了解您输入的内容，以便在撰写时改进建议';

  @override
  String get usabilityCPLLabel => '禁用大写锁定键';

  @override
  String get usability11MRCLabel => '新版右键菜单';

  @override
  String get usability11FETLabel => '文件资源管理器标签页';

  @override
  String get perfSuperfetchLabel => '预存取（Superfetch）';

  @override
  String get perfSuperfetchDescription => '通过将所有必要数据预加载到内存中，加快启动时间并更快地加载程序。仅建议硬盘用户启用 Superfetch 功能';

  @override
  String get perfMCLabel => '内存压缩';

  @override
  String get perfMCDescription => '压缩后台运行的闲置程序，节省内存。根据硬件情况，可能会对 CPU 占用率产生轻微影响';

  @override
  String get perfITSXLabel => '英特尔事务同步扩展 （Intel TSX）';

  @override
  String get perfITSXDescription => '增加硬件事务内存支持，有助于加快多线程软件的执行速度，降低安全成本';

  @override
  String get perfFOLabel => '全屏优化';

  @override
  String get perfFODescription => '全屏优化可提高在全屏模式下运行游戏和应用程序时的性能';

  @override
  String get perfOWGLabel => '窗口化游戏优化';

  @override
  String get perfOWGDescription => '通过为在窗口或无边框窗口中显示的 DirectX 10 和 11 游戏使用新的显示模型，改善帧延迟';

  @override
  String get perfCStatesLabel => '禁用 ACPI C2 和 C3 状态';

  @override
  String get perfCStatesDescription => '禁用 ACPI C 状态可能会提高性能和延迟，但在空闲时会消耗更多电能，可能会缩短电源寿命';

  @override
  String get perfSectionFS => '文件系统';

  @override
  String get perfLTALabel => '禁用上次访问时间';

  @override
  String get perfLTADescription => '禁用上次访问时间可提高文件和目录访问性能，减少磁盘 I/O 负载和延迟';

  @override
  String get perfEdTLabel => '禁用 8.3 命名';

  @override
  String get perfEdTDescription => '8.3 命名已过时，禁用它将提高 NTFS 性能和安全性';

  @override
  String get perfMULabel => '增加 NTFS 分页池内存限制';

  @override
  String get perfMUDescription => '增加物理内存并不总能增加 NTFS 可用的分页池内存量。将内存使用率设置为 2 会提高分页池内存的上限。如果你的系统正在打开和关闭同一文件集中的许多文件，并且尚未将大量系统内存用于其他应用程序或缓存内存，那么这可能会提高性能。如果计算机已将大量系统内存用于其他应用程序或缓存内存，则增加 NTFS 分页和非分页池内存限制会减少其他进程的可用池内存。这可能会降低系统的整体性能\n\n默认为关闭';

  @override
  String get wuPageLabel => '隐藏 Windows 更新页面';

  @override
  String get wuPageDescription => '显示此页面还将启用更新通知功能';

  @override
  String get wuDriversLabel => '通过 Windows 更新安装驱动程序';

  @override
  String get wuDriversDescription => '要在 ReviOS 中安装驱动程序，您需要在设置中手动检查更新，因为 Windows 不支持自动更新';

  @override
  String get miscHibernateLabel => '休眠';

  @override
  String get miscHibernateDescription => '省电 S4 状态，将当前会话保存到 休眠文件 并关闭设备。默认情况下已禁用，以避免多系统启动或系统升级时的不稳定性';

  @override
  String get miscHibernateModeLabel => '休眠模式';

  @override
  String get miscHibernateModeDescription => '完全 - 支持休眠和快速启动。休眠文件将占用物理内存的 40%。半休眠 - 仅支持不带休眠功能的快速启动，休眠文件占用物理内存的 20%，并在电源菜单中移除休眠功能';

  @override
  String get miscFastStartupLabel => '快速启动';

  @override
  String get miscFastStartupDescription => '将当前会话保存到 C:\\hiberfil.sys，以加快启动速度，但不影响重启。默认情况下已禁用，以避免多系统启动或系统升级时的不稳定性';

  @override
  String get miscTMMonitoringLabel => '网络和 GPU 监控';

  @override
  String get miscTMMonitoringDescription => '激活任务管理器的监控服务';

  @override
  String get miscMpoLabel => '多平面叠加（MPO）';

  @override
  String get miscMpoCodeSnippet => '建议在 Nvidia GTX 16xx、RTX 3xxx 和 AMD RX 5xxx 显卡或更新的显卡上关闭此功能。\n开启此功能可能会导致黑屏、卡顿、闪烁和其他一般显示问题';

  @override
  String get miscBHRLabel => '电池健康报告';

  @override
  String get miscBHRDescription => '报告电池健康状况；启用会增加系统使用率';

  @override
  String get miscCertsLabel => '更新根证书';

  @override
  String get miscCertsDescription => '在遇到证书问题时使用';

  @override
  String get miscCertsDialog => '根证书更新已完成。再次尝试出现问题的软件，如果问题仍然存在，请联系我们的支持人员';

  @override
  String get settingsUpdateLabel => '更新 Revision Tool';

  @override
  String get updateButton => '更新';

  @override
  String get settingsUpdateButton => '检查更新';

  @override
  String get settingsUpdateButtonAvailable => '更新可用';

  @override
  String get settingsUpdateButtonAvailablePrompt => '您是否希望将Revision Tool更新为';

  @override
  String get settingsUpdatingStatus => '更新中';

  @override
  String get settingsUpdatingStatusSuccess => '更新成功';

  @override
  String get settingsUpdatingStatusNotFound => '没有找到更新';

  @override
  String get settingsCTLabel => '颜色主题';

  @override
  String get settingsCTDescription => '在明暗模式之间切换，或跟随 Windows 系统设置自动更换';

  @override
  String get settingsEPTLabel => '显示实验性优化';

  @override
  String get settingsEPTDescription => '';

  @override
  String get restartAppDialog => '您必须重新启动应用程序才能使更改生效';

  @override
  String get settingsLanguageLabel => '语言';
}