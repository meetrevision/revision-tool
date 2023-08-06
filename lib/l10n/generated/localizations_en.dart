import 'localizations.dart';

/// The translations for English (`en`).
class ReviLocalizationsEn extends ReviLocalizations {
  ReviLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get unsupportedTitle => 'Error';

  @override
  String get unsupportedContent => 'Unsupported build detected';

  @override
  String get okButton => 'OK';

  @override
  String get notNowButton => 'Not now';

  @override
  String get restartDialog => 'You must restart your computer for the changes to take effect';

  @override
  String get moreInformation => 'More information';

  @override
  String get onStatus => 'On';

  @override
  String get offStatus => 'Off';

  @override
  String get pageHome => 'Home';

  @override
  String get pageSecurity => 'Security';

  @override
  String get pageUsability => 'Usability';

  @override
  String get pagePerformance => 'Performance';

  @override
  String get pageUpdates => 'Windows Updates';

  @override
  String get pageMiscellaneous => 'Miscellaneous';

  @override
  String get pageSettings => 'Settings';

  @override
  String get suggestionBoxPlaceholder => 'Find a setting';

  @override
  String get homeWelcome => 'Welcome to Revision';

  @override
  String get homeDescription => 'A tool to personalize ReviOS to your needs';

  @override
  String get homeReviLink => 'Check out Revision';

  @override
  String get homeReviFAQLink => 'Check out FAQ';

  @override
  String get securityWDLabel => 'Windows Defender';

  @override
  String get securityWDDescription => 'Windows Defender will protect your PC. This will have a performance impact due to constantly running in the background';

  @override
  String get securityWDButton => 'Disable protections';

  @override
  String get securityDialog => 'Please disable every protection before completely disabling Windows Defender';

  @override
  String get securityUACLabel => 'User Account Control';

  @override
  String get securityUACDescription => 'Limits application to standard user privileges until an administrator authorizes an elevation';

  @override
  String get securitySMLabel => 'Spectre & Meltdown Mitigation';

  @override
  String get securitySMDescription => 'Patches to enable mitigation against Spectre & Meltdown vulnerabilities';

  @override
  String get usabilityNotifLabel => 'Windows Notifications';

  @override
  String get usabilityNotifDescription => 'Completely toggle Windows notifications';

  @override
  String get usabilityLBNLabel => 'Legacy Notification Balloons';

  @override
  String get usabilityLBNDescription => 'Tray programs on the taskbar will render as balloons instead of toast notifications';

  @override
  String get usabilityITPLabel => 'Inking And Typing Personalization';

  @override
  String get usabilityITPDescription => 'Windows will learn what you type to improve suggestions when writing';

  @override
  String get usabilityCPLLabel => 'Disable CapsLock Key';

  @override
  String get usability11MRCLabel => 'New Context Menu';

  @override
  String get usability11FETLabel => 'File Explorer Tabs';

  @override
  String get perfSuperfetchLabel => 'Superfetch';

  @override
  String get perfSuperfetchDescription => 'Speed up boot time and load programs faster by preloading all of the necessary data into memory. Enabling Superfetch is only recommended for HDD users';

  @override
  String get perfMCLabel => 'Memory Compression';

  @override
  String get perfMCDescription => 'Save memory by compressing unused programs running in the background. Might have a small impact on CPU usage depending on hardware';

  @override
  String get perfITSXLabel => 'Intel TSX';

  @override
  String get perfITSXDescription => 'Add hardware transactional memory support, which helps speed up the execution of multithreaded software in cost of security';

  @override
  String get perfFOLabel => 'Fullscreen Optimizations';

  @override
  String get perfFODescription => 'Fullscreen Optimizations may lead to better gaming and app performance when running in fullscreen mode';

  @override
  String get perfOWGLabel => 'Optimizations for windowed games';

  @override
  String get perfOWGDescription => 'Improves frame latency by using a new presentation model for DirectX 10 and 11 games that appear in a window or in a borderless window';

  @override
  String get perfCStatesLabel => 'Disable the ACPI C2 and C3 states';

  @override
  String get perfCStatesDescription => 'Disabling ACPI C-states may improve performance and latency, but it will consume more power while idle, potentially reducing battery life';

  @override
  String get perfSectionFS => 'Filesystem';

  @override
  String get perfLTALabel => 'Disable Last Access Time';

  @override
  String get perfLTADescription => 'Disabling Last Time Access improves the performance of file and directory access, reduces disk I/O load and latency';

  @override
  String get perfEdTLabel => 'Disable 8.3 Naming';

  @override
  String get perfEdTDescription => '8.3 naming is ancient and disabling it will improve NTFS performance and security';

  @override
  String get perfMULabel => 'Increase the limit of paged pool memory to NTFS';

  @override
  String get perfMUDescription => 'Increasing the physical memory doesn\'t always increase the amount of paged pool memory available to NTFS. Setting memoryusage to 2 raises the limit of paged pool memory. This might improve performance if your system is opening and closing many files in the same fileset and is not already using large amounts of system memory for other apps or for cache memory. If your computer is already using large amounts of system memory for other apps or for cache memory, increasing the limit of NTFS paged and non-paged pool memory reduces the available pool memory for other processes. This might reduce overall system performance.\n\nDefault is Off';

  @override
  String get wuPageLabel => 'Hide the Windows Updates page';

  @override
  String get wuPageDescription => 'Showing this page will also enable update notifications';

  @override
  String get wuDriversLabel => 'Drivers install through Windows Updates';

  @override
  String get wuDriversDescription => 'To install drivers in ReviOS, you need to manually check for updates in Settings, as automatic Windows Updates are not supported';

  @override
  String get miscHibernateLabel => 'Hibernate';

  @override
  String get miscHibernateDescription => 'A power-saving S4 state, saves the current session to hiberfile and turns off the device. Disabled by default to avoid instability during dual-booting or system upgrades';

  @override
  String get miscHibernateModeLabel => 'Hibernate Mode';

  @override
  String get miscHibernateModeDescription => 'Full - Supports hibernate and fast startup. The hiberfile will be 40% of physical RAM installed. Hibernate is available to be added to the power menu.\n\nReduced - Only supports Fast Startup without hibernate, The hiberfile will be 20% of physical RAM installed and removes hibernate from the power menu';

  @override
  String get miscFastStartupLabel => 'Fast Startup';

  @override
  String get miscFastStartupDescription => 'Save the current session to C:\\hiberfil.sys for faster startup, does not affect reboots. Disabled by default to avoid instability during dual-booting or system upgrades';

  @override
  String get miscTMMonitoringLabel => 'Network and GPU monitoring';

  @override
  String get miscTMMonitoringDescription => 'Activate the monitoring services for Task Manager';

  @override
  String get miscMpoLabel => 'Multiplane overlay (MPO)';

  @override
  String get miscMpoCodeSnippet => 'Recommended to turn off on Nvidia GTX 16xx, RTX 3xxx and AMD RX 5xxx cards or newer.\nLeaving this on could cause black screens, stuttering, flickering, and other general display problems';

  @override
  String get miscBHRLabel => 'Battery Health Reporting';

  @override
  String get miscBHRDescription => 'Reports Battery health status; Enabling will increase system usage';

  @override
  String get miscCertsLabel => 'Update Root Certificates';

  @override
  String get miscCertsDescription => 'Use it when having issues with certificates';

  @override
  String get miscCertsDialog => 'Updating of root certificates has finished. Try the software that you had issues with again, and if the issue persists, please contact our support.';

  @override
  String get settingsUpdateLabel => 'Update Revision Tool';

  @override
  String get updateButton => 'Update';

  @override
  String get settingsUpdateButton => 'Check for Updates';

  @override
  String get settingsUpdateButtonAvailable => 'Update Available';

  @override
  String get settingsUpdateButtonAvailablePrompt => 'Would you like to update Revision Tool to';

  @override
  String get settingsUpdatingStatus => 'Updating';

  @override
  String get settingsUpdatingStatusSuccess => 'Updated successfully';

  @override
  String get settingsUpdatingStatusNotFound => 'No update was found';

  @override
  String get settingsCTLabel => 'Color Theme';

  @override
  String get settingsCTDescription => 'Switch between light and dark mode, or automatically change the theme with Windows';

  @override
  String get settingsEPTLabel => 'Show experimental tweaks';

  @override
  String get settingsEPTDescription => '';

  @override
  String get restartAppDialog => 'You must restart your app for the changes to take effect';

  @override
  String get settingsLanguageLabel => 'Language';
}
