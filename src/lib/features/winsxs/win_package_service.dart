import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_endpoints.dart';
import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import '../ms_store/domain/entities/store_download_info.dart';
import '../ms_store/domain/entities/store_enums.dart';
import '../ms_store/domain/services/store_service.dart';
import '../tweaks/security/security_service.dart';
import 'winsxs_exceptions.dart';

final ProviderFamily<WinPackageService, WinPackageType> winPackageServiceProvider =
    Provider.family<WinPackageService, WinPackageType>((ref, type) {
      final ApiClient api = ref.watch(apiClientProvider);
      return switch (type) {
        .systemComponentsRemoval => SystemPackagesRemovalService(api: api),
        .oneDriveRemoval => OneDriveRemovalService(api: api),
        .defenderRemoval => DefenderRemovalService(
          security: ref.watch(securityServiceProvider),
          api: api,
        ),
        .aiRemoval => AiRemovalService(store: ref.watch(storeServiceProvider), api: api),
        .xboxRemoval => XboxRemovalService(store: ref.watch(storeServiceProvider), api: api),
      };
    });

enum WinPackageType({required final String packageName, required final String cliKey}) {
  systemComponentsRemoval(
    packageName: 'Revision-ReviOS-SystemPackages-Removal',
    cliKey: 'system-components-removal',
  ),
  defenderRemoval(packageName: 'Revision-ReviOS-Defender-Removal', cliKey: 'defender-removal'),
  aiRemoval(packageName: 'Revision-ReviOS-AI-Removal', cliKey: 'ai-removal'),
  oneDriveRemoval(packageName: 'Revision-ReviOS-OneDrive-Removal', cliKey: 'onedrive-removal'),
  xboxRemoval(packageName: 'Revision-ReviOS-Xbox-Removal', cliKey: 'xbox-removal');

  static WinPackageType byCliKey(String key) {
    return WinPackageType.values.firstWhere(
      (e) => e.cliKey == key,
      orElse: () => throw ArgumentError('Invalid CLI key: $key'),
    );
  }
}

typedef WinPackageVersion = (int, int, int, int);

typedef WinPackageDownload = ({String path, WinPackageVersion version});

typedef WinPackageAsset = Map<String, dynamic>;

abstract base class const WinPackageService({
  required final WinPackageType type,
  required final ApiClient _api,
}) {
  static final String cabPath = p.join(Directory.systemTemp.path, 'Revision-Tool', 'CAB');

  static final String bundledPackagesPath = p.join(directoryExe, 'packages', 'winsxs');

  static const cbsPackagesRegPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';

  static bool checkPackageInstalled(WinPackageType p) {
    final RegistryKey packageRoot = LOCAL_MACHINE.open(cbsPackagesRegPath);
    try {
      final String? key = packageRoot.keys.lastWhereOrNull((e) => e.startsWith(p.packageName));
      if (key == null) return false;

      final int? currentState = WinRegistryService.readInt(
        LOCAL_MACHINE,
        '$cbsPackagesRegPath$key',
        'CurrentState',
      );
      final int? lastError = WinRegistryService.readInt(
        LOCAL_MACHINE,
        '$cbsPackagesRegPath$key',
        'LastError',
      );

      // installation codes - https://forums.ivanti.com/s/article/Understand-Patch-installation-failure-codes?language=en_US
      return currentState != null &&
          (currentState != 5 || currentState != 4294967264) &&
          lastError == null;
    } finally {
      packageRoot.close();
    }
  }

  static String? getBundledPackagePath(WinPackageType packageType) {
    try {
      final bundledDir = Directory(bundledPackagesPath);
      if (!bundledDir.existsSync()) {
        logger.w('Bundled packages directory does not exist: $bundledPackagesPath');
        return null;
      }

      final String? packageFile = bundledDir
          .listSync()
          .whereType<File>()
          .map((file) => p.basename(file.path))
          .firstWhereOrNull(
            (name) =>
                name.startsWith('${packageType.packageName}31bf3856ad364e35') &&
                name.contains(WinRegistryService.cpuArch) &&
                name.endsWith('.cab'),
          );

      if (packageFile != null) {
        final String fullPath = p.join(bundledPackagesPath, packageFile);
        logger.i('Found bundled package: $fullPath');
        return fullPath;
      }
    } catch (e) {
      logger.w('Error checking bundled packages: $e');
    }
    return null;
  }

  /// Matches the version suffix of both installed CBS package names (`~~1.2.3.4`)
  /// and cab file names (`~1.2.3.4`), capturing the four version components.
  static final _versionSuffixPattern = RegExp(r'~{1,2}(\d+\.\d+\.\d+\.\d+)$');

  static WinPackageVersion? parsePackageVersion(String packageName) {
    final RegExpMatch? match = _versionSuffixPattern.firstMatch(packageName.trim());
    if (match?.group(1) case final version?) {
      final IList<int> parts = version.split('.').map(int.parse).toIList();
      return (parts[0], parts[1], parts[2], parts[3]);
    }
    return null;
  }

  static int comparePackageVersions(WinPackageVersion left, WinPackageVersion right) {
    for (final (leftPart, rightPart) in [
      (left.$1, right.$1),
      (left.$2, right.$2),
      (left.$3, right.$3),
      (left.$4, right.$4),
    ]) {
      final int result = leftPart.compareTo(rightPart);
      if (result != 0) return result;
    }
    return 0;
  }

  /// Downloads [type] from GitHub or uses the bundled package if available.
  ///
  /// Returns [WinPackageDownload] with the path and version of the package.
  Future<WinPackageDownload> download({String? path}) async {
    final String downloadPath = path ?? cabPath;

    try {
      logger.i('Attempting to download package from GitHub...');

      Directory(downloadPath).createSync(recursive: true);

      final Response<WinPackageAsset> response = await _api
          .get<WinPackageAsset>(
            NetworkEndpoints.githubLatestRelease(GitHubRepositoryEndpoint.cabPackages),
          )
          .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

      final IMap<String, dynamic> releaseData = response.data!.lock;

      final String tagName = releaseData['tag_name'] as String? ?? '';

      final WinPackageVersion? releaseVersion = parsePackageVersion('~~$tagName');
      if (releaseVersion == null) {
        throw InvalidWinSxSPackageVersionException('Invalid release version: $tagName');
      }

      final IList<WinPackageAsset> assets = List<WinPackageAsset>.from(
        releaseData['assets'] as List<dynamic>,
      ).lock;

      final WinPackageAsset? asset = assets.firstWhereOrNull((e) {
        if (e['name'] case final String name) {
          return name.startsWith('${type.packageName}31bf3856ad364e35') &&
              name.contains(WinRegistryService.cpuArch);
        }
        return false;
      });

      final downloadUrl = asset?['browser_download_url'] as String?;
      final String assetName = asset?['name'] as String? ?? '';

      if (downloadUrl == null) {
        throw WinSxSPackageNotFoundException(
          'No matching package found for ${type.packageName} with architecture ${WinRegistryService.cpuArch}',
        );
      }

      final String filePath = p.join(downloadPath, assetName);

      final Result<Response<dynamic>> downloadResult = await _api.downloadFile(
        Uri.parse(downloadUrl),
        filePath,
      );
      downloadResult.when(success: (_) {}, failure: (exception) => throw exception);
      if (!File(filePath).existsSync()) {
        throw WinSxSPackageDownloadException('Failed to download package: $assetName');
      }

      logger.i('Successfully downloaded package from GitHub: $filePath');
      return (path: filePath, version: releaseVersion);
    } catch (e, stackTrace) {
      logger.w('Failed to download from GitHub', error: e, stackTrace: stackTrace);
      logger.i('Falling back to bundled packages...');

      final String? bundledPath = getBundledPackagePath(type);
      if (bundledPath != null && File(bundledPath).existsSync()) {
        logger.i('Using bundled package: $bundledPath');

        final String targetPath = switch (path) {
          null => bundledPath,
          final dir => p.join(dir, p.basename(bundledPath)),
        };
        if (path case final dir?) {
          Directory(dir).createSync(recursive: true);
          File(bundledPath).copySync(targetPath);
        }
        final WinPackageVersion? bundledVersion = parsePackageVersion(
          p.basenameWithoutExtension(targetPath),
        );
        if (bundledVersion == null) {
          throw InvalidWinSxSPackageVersionException(
            'Invalid bundled package version: $targetPath',
          );
        }
        return (path: targetPath, version: bundledVersion);
      }

      throw WinSxSPackageDownloadException(
        'Failed to download package from GitHub and no bundled package available',
        e,
      );
    }
  }

  Future<void> install({bool force = false}) async {
    logger.i('winsxs: Downloading package=${type.packageName}');
    final (path: String packagePath, version: WinPackageVersion packageVersion) = await download();
    await _installCab(packagePath, packageVersion: packageVersion, force: force);
  }

  Future<void> _installCab(
    String packagePath, {
    required WinPackageVersion packageVersion,
    required bool force,
  }) async {
    logger.i('winsxs: Installing package=${type.packageName}, path=$packagePath');

    if (!File(packagePath).existsSync()) {
      throw WinSxSPackageFileNotFoundException('Package file does not exist: $packagePath');
    }

    final IList<String> installedPackageNames = await _installedPackageNames();
    final IList<WinPackageVersion?> installedVersions = installedPackageNames
        .map(parsePackageVersion)
        .toIList();
    if (installedVersions.any((version) => version == null)) {
      throw InvalidWinSxSPackageVersionException(
        'Invalid installed package version for ${type.packageName}',
      );
    }
    if (installedVersions.isNotEmpty) {
      final WinPackageVersion latestInstalledVersion = installedVersions
          .whereType<WinPackageVersion>()
          .reduce((left, right) => comparePackageVersions(left, right) >= 0 ? left : right);

      if (!force && comparePackageVersions(packageVersion, latestInstalledVersion) <= 0) {
        logger.i('winsxs: Skipping package=${type.packageName}; installed version is current');
        _deleteTemporaryPackage(packagePath);
        return;
      }
    }

    await _installCabOnly(packagePath);
    await _uninstallOlderCabs(p.basenameWithoutExtension(packagePath));
  }

  Future<IList<String>> _installedPackageNames() async {
    final ProcessResult result = await runPSCommand(
      '(Get-WindowsPackage -Online -PackageName "${type.packageName}*").PackageName',
      stdout: true,
    );
    return result.stdout
        .toString()
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toIList();
  }

  Future<void> _installCabOnly(String packagePath, {bool deletePackage = true}) async {
    final String certValue = (await runPSCommand(
      '(Get-AuthenticodeSignature -FilePath "$packagePath").SignerCertificate.Extensions.EnhancedKeyUsages.Value',
    )).stdout.toString().trim();

    if (certValue.isEmpty || certValue != '1.3.6.1.4.1.311.10.3.6') {
      throw InvalidWinSxSPackageSignatureException('Invalid signature: $packagePath');
    }

    WinRegistryService.createKey(
      LOCAL_MACHINE,
      r'Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344',
    );

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await runPSCommand(
      'Add-WindowsPackage -Online -NoRestart -IgnoreCheck -PackagePath "$packagePath"',
    );
    if (deletePackage) _deleteTemporaryPackage(packagePath);
  }

  Future<void> uninstall() async {
    Future<void> uninstallMatchingCabs() => runPSCommand(
      'Get-WindowsPackage -Online -PackageName "${type.packageName}*" | Remove-WindowsPackage -Online -NoRestart',
    );

    try {
      await uninstallMatchingCabs();
    } catch (error) {
      try {
        final String packagePath = (await download()).path;
        await _installCabOnly(packagePath, deletePackage: false);
        await uninstallMatchingCabs();
        _deleteTemporaryPackage(packagePath);
      } catch (retryError) {
        throw Exception(
          'Failed to uninstall ${type.packageName} after recovery attempt. Contact support at https://revi.cc/. Original error: $error; Retry error: $retryError',
        );
      }
    }
  }

  Future<void> _uninstallOlderCabs(String installedPackageName) async => runPSCommand(
    'Get-WindowsPackage -Online -PackageName "${type.packageName}*" | Where-Object { \$_.PackageName -ne "$installedPackageName" } | Remove-WindowsPackage -Online -NoRestart',
  );

  void _deleteTemporaryPackage(String packagePath) {
    if (!p.isWithin(bundledPackagesPath, packagePath)) File(packagePath).deleteSync();
  }
}

final class const SystemPackagesRemovalService({required super.api}) extends WinPackageService {
  this : super(type: .systemComponentsRemoval);
}

final class const OneDriveRemovalService({required super.api}) extends WinPackageService {
  this : super(type: .oneDriveRemoval);
}

/// [install] and [uninstall] methods are overridden to call [SecurityService] methods instead of the base class methods, to ensure that Defender is properly disabled/enabled.
///
/// The [installPackage] and [uninstallPackage] methods are provided to allow calling the base class methods directly when needed.
final class const DefenderRemovalService({
  required final SecurityService _security,
  required super.api,
}) extends WinPackageService {
  this : super(type: .defenderRemoval);

  @override
  Future<void> install({bool force = false}) => _security.disableDefenderCLI(force: force);

  @override
  Future<void> uninstall() => _security.enableDefenderCLI();

  Future<void> installPackage({bool force = false}) => super.install(force: force);

  Future<void> uninstallPackage() => super.uninstall();
}

final class const AiRemovalService({required final StoreService _store, required super.api})
    extends WinPackageService {
  this : super(type: .aiRemoval);

  static const _copilotStoreId = '9nht9rb2f4hd';
  static const _fabricAIPath =
      r'C:\Windows\SystemApps\Microsoft.AIFabric.CBS.1.6_8wekyb3d8bbwe\AppxManifest.xml';

  @override
  Future<void> install({bool force = false}) async {
    await WinRegistryService.hidePageVisibilitySettings('aicomponents');
    await WinRegistryService.hidePageVisibilitySettings('privacy-systemaimodels');
    await runPSCommand('Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart');
    await runPSCommand('Get-AppxPackage -AllUsers Microsoft.Copilot* | Remove-AppxPackage');

    await runPSCommand(
      r"Get-AppxPackage -Name 'Microsoft.AIFabric.CBS.1.6*' | Remove-AppxPackage -PreserveRoamableApplicationData",
    );
    // Since 26200.9278 update, removing AIFabric components reverts Explorer ribbon to Win10 style. 58375086 aka 1561856655 should be set to 0 to keep the Win11 style ribbon.
    await WinRegistryService.writeRegistryValue(
      LOCAL_MACHINE,
      r'SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides',
      '1561856655',
      0,
    );

    await super.install(force: force);
  }

  @override
  Future<void> uninstall() async {
    await WinRegistryService.unhidePageVisibilitySettings('aicomponents');
    await WinRegistryService.unhidePageVisibilitySettings('privacy-systemaimodels');

    await super.uninstall();

    await runPSCommand('Enable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart');
    await _installStorePackages(store: _store, ids: {_copilotStoreId}.lock);
    if (File(_fabricAIPath).existsSync()) {
      logger.i('winsxs: Re-registering Microsoft.AIFabric.CBS.1.6 package...');
      await runPSCommand(
        'Add-AppxPackage -Register -DisableDevelopmentMode -Path "$_fabricAIPath"',
      );
      await WinRegistryService.deleteValue(
        LOCAL_MACHINE,
        r'SYSTEM\ControlSet001\Policies\Microsoft\FeatureManagement\Overrides',
        '1561856655',
      );
    }
  }
}

final class const XboxRemovalService({required final StoreService _store, required super.api})
    extends WinPackageService {
  this : super(type: .xboxRemoval);

  static const _callableUiManifestPath =
      r'C:\Windows\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy\AppxManifest.xml';

  static const _storePackages = <String, String>{
    'Microsoft.Xbox.TCUI': '9MV0B5HZVK9Z',
    // 'Microsoft.XboxApp': '9WZDNCRFJBD8', // Deprecated package
    'Microsoft.GamingApp': '9MV0B5HZVK9Z',
    'Microsoft.GamingServices': '9MWPM2CQNLHN',
    'Microsoft.Edge.GameAssist': '',
    'Microsoft.XboxGamingOverlay': '9NZKPSTSNW4P',
    'Microsoft.XboxIdentityProvider': '9WZDNCRD1HKW',
  };

  @override
  Future<void> install({bool force = false}) async {
    await runPSCommand(
      r"Get-AppxPackage -Name 'Microsoft.XboxGameCallableUI' | Remove-AppxPackage -PreserveRoamableApplicationData",
    );
    await runPSCommand(
      r"'Microsoft.Xbox.TCUI','Microsoft.XboxApp','Microsoft.GamingApp','Microsoft.GamingServices','Microsoft.Edge.GameAssist','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider' | ForEach-Object { Get-AppxPackage -AllUsers -Name $_ | Remove-AppxPackage -AllUsers }",
    );
    await super.install(force: force);
  }

  @override
  Future<void> uninstall() async {
    await super.uninstall();
    if (File(_callableUiManifestPath).existsSync()) {
      logger.i('winsxs: Re-registering XboxGameCallableUI package...');
      await runPSCommand(
        'Add-AppxPackage -Register -DisableDevelopmentMode -Path "$_callableUiManifestPath"',
      );
    }
    logger.i('winsxs: Reinstalling Xbox packages from Microsoft Store...');
    final xboxStoreIds = <String>{};
    for (final MapEntry(:key, :value) in _storePackages.entries) {
      if (value.isEmpty) {
        logger.w('winsxs: No Store ID for $key, skipping reinstallation.');
      } else {
        xboxStoreIds.add(value);
      }
    }
    await _installStorePackages(store: _store, ids: xboxStoreIds.lock);
  }
}

Future<void> _installStorePackages({
  required StoreService store,
  required ISet<String> ids,
  StoreRing ring = .releasePreview,
  StoreArch arch = .auto,
}) async {
  final StorePackagesByProductId packagesByProductId = await store
      .getPackages(productIds: ids, ring: ring, arch: arch)
      .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

  final ISet<StorePackageFileDownload> downloads = await store
      .download(
        ring: ring,
        packagesByProductId: packagesByProductId,
        cancelToken: CancelToken(),
        onProgress: (_) {},
      )
      .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

  final IMap<String, ProcessResult> installResults = await store
      .install(downloads: downloads)
      .then((r) => r.when(success: (v) => v, failure: (e) => throw e));

  final IList<ProcessResult> failed = installResults.values.where((r) => r.exitCode != 0).toIList();

  if (failed.isNotEmpty) {
    throw Exception(failed.map((r) => r.stderr).join('\n'));
  }
}
