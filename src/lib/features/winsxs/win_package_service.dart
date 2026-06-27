import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:win32_registry/win32_registry.dart';

import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_endpoints.dart';
import '../../core/services/win_registry_service.dart';
import '../../utils.dart';
import '../ms_store/models/store_download_info.dart';
import '../ms_store/store_enums.dart';
import '../ms_store/store_service.dart';
import '../tweaks/security/security_service.dart';
import 'winsxs_exceptions.dart';

final ProviderFamily<WinPackageService, WinPackageType>
winPackageServiceProvider = Provider.family<WinPackageService, WinPackageType>((
  ref,
  type,
) {
  final ApiClient api = ref.watch(apiClientProvider);
  return switch (type) {
    .systemComponentsRemoval => SystemPackagesRemovalService(api: api),
    .oneDriveRemoval => OneDriveRemovalService(api: api),
    .defenderRemoval => DefenderRemovalService(
      security: ref.watch(securityServiceProvider),
      api: api,
    ),
    .aiRemoval => AiRemovalService(
      store: ref.watch(storeServiceProvider),
      api: api,
    ),
    .xboxRemoval => XboxRemovalService(
      store: ref.watch(storeServiceProvider),
      api: api,
    ),
  };
});

enum WinPackageType {
  systemComponentsRemoval(
    packageName: 'Revision-ReviOS-SystemPackages-Removal',
    cliKey: 'system-components-removal',
  ),
  defenderRemoval(
    packageName: 'Revision-ReviOS-Defender-Removal',
    cliKey: 'defender-removal',
  ),
  aiRemoval(packageName: 'Revision-ReviOS-AI-Removal', cliKey: 'ai-removal'),
  oneDriveRemoval(
    packageName: 'Revision-ReviOS-OneDrive-Removal',
    cliKey: 'onedrive-removal',
  ),
  xboxRemoval(
    packageName: 'Revision-ReviOS-Xbox-Removal',
    cliKey: 'xbox-removal',
  );

  const WinPackageType({required this.packageName, required this.cliKey});

  final String packageName;
  final String cliKey;

  static WinPackageType byCliKey(final String key) {
    return WinPackageType.values.firstWhere(
      (e) => e.cliKey == key,
      orElse: () => throw ArgumentError('Invalid CLI key: $key'),
    );
  }
}

abstract base class WinPackageService {
  const WinPackageService({required this.type, required this._api});

  final WinPackageType type;
  final ApiClient _api;

  static final String cabPath = p.join(
    Directory.systemTemp.path,
    'Revision-Tool',
    'CAB',
  );

  static final String bundledPackagesPath = p.join(
    directoryExe,
    'packages',
    'winsxs',
  );

  static const cbsPackagesRegPath =
      r'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\';

  static bool checkPackageInstalled(final WinPackageType packageType) {
    final String? key =
        Registry.openPath(
          RegistryHive.localMachine,
          path: cbsPackagesRegPath,
        ).subkeyNames.lastWhereOrNull(
          (final element) => element.startsWith(packageType.packageName),
        );

    if (key == null) {
      return false;
    }

    final int currentState = WinRegistryService.readInt(
      RegistryHive.localMachine,
      cbsPackagesRegPath + key,
      'CurrentState',
    )!;

    final int? lastError = WinRegistryService.readInt(
      RegistryHive.localMachine,
      cbsPackagesRegPath + key,
      'LastError',
    );

    // installation codes - https://forums.ivanti.com/s/article/Understand-Patch-installation-failure-codes?language=en_US
    return (currentState != 5 || currentState != 4294967264) &&
        lastError == null;
  }

  static String? getBundledPackagePath(final WinPackageType packageType) {
    try {
      final bundledDir = Directory(bundledPackagesPath);
      if (!bundledDir.existsSync()) {
        logger.w(
          'Bundled packages directory does not exist: $bundledPackagesPath',
        );
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

  /// Downloads [type] from GitHub or uses the bundled package if available.
  ///
  /// Returns [String] path of the downloaded package.
  Future<String> download({String? path}) async {
    final String downloadPath = path ?? cabPath;

    try {
      logger.i('Attempting to download package from GitHub...');

      Directory(downloadPath).createSync(recursive: true);

      final Result<Response<dynamic>> releaseResult = await _api.get<dynamic>(
        NetworkEndpoints.githubLatestRelease(
          GitHubRepositoryEndpoint.cabPackages,
        ),
      );
      final Response<dynamic> releaseResponse = releaseResult.when(
        success: (response) => response,
        failure: (exception) => throw exception,
      );

      final releaseData = releaseResponse.data as Map<String, dynamic>;
      final assets = List<Map<String, dynamic>>.from(
        releaseData['assets'] as List<dynamic>,
      );
      var name = '';

      final Map<String, dynamic>? asset = assets.firstWhereOrNull((
        final Map<String, dynamic> e,
      ) {
        final n = e['name'] as String?;
        return n != null &&
            n.startsWith('${type.packageName}31bf3856ad364e35') &&
            n.contains(WinRegistryService.cpuArch);
      });

      final downloadUrl = asset?['browser_download_url'] as String?;
      if (asset != null) {
        name = asset['name'] as String? ?? '';
      }

      if (downloadUrl == null) {
        throw WinSxSPackageNotFoundException(
          'No matching package found for ${type.packageName} with architecture ${WinRegistryService.cpuArch}',
        );
      }

      final String filePath = p.join(downloadPath, name);

      final Result<Response<dynamic>> downloadResult = await _api.downloadFile(
        Uri.parse(downloadUrl),
        filePath,
      );
      downloadResult.when(
        success: (_) {},
        failure: (exception) => throw exception,
      );
      if (!File(filePath).existsSync()) {
        throw WinSxSPackageDownloadException(
          'Failed to download package: $name',
        );
      }

      logger.i('Successfully downloaded package from GitHub: $filePath');
      return filePath;
    } catch (e) {
      logger.w('Failed to download from GitHub: $e');
      logger.i('Falling back to bundled packages...');

      final String? bundledPath = getBundledPackagePath(type);
      if (bundledPath != null && File(bundledPath).existsSync()) {
        logger.i('Using bundled package: $bundledPath');

        if (path != null) {
          final String targetPath = p.join(path, p.basename(bundledPath));
          Directory(path).createSync(recursive: true);
          await File(bundledPath).copy(targetPath);
          return targetPath;
        }

        return bundledPath;
      }

      throw WinSxSPackageDownloadException(
        'Failed to download package from GitHub and no bundled package available',
        e,
      );
    }
  }

  Future<void> install() async {
    logger.i('winsxs: Downloading package=${type.packageName}');
    final String packagePath = await download();
    logger.i(
      'winsxs: Installing package=${type.packageName}, path=$packagePath',
    );

    if (!File(packagePath).existsSync()) {
      throw WinSxSPackageFileNotFoundException(
        'Package file does not exist: $packagePath',
      );
    }

    final String certValue = (await runPSCommand(
      '(Get-AuthenticodeSignature -FilePath "$packagePath").SignerCertificate.Extensions.EnhancedKeyUsages.Value',
    )).stdout.toString().trim();

    if (certValue.isEmpty || certValue != '1.3.6.1.4.1.311.10.3.6') {
      throw InvalidWinSxSPackageSignatureException(
        'Invalid signature: $packagePath',
      );
    }

    WinRegistryService.createKey(
      Registry.localMachine,
      r'Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344',
    );

    // running it via TrustedInstaller causes 'Win32 internal error "Access is denied" 0x5 occurred while reading the console output buffer'
    await runPSCommand(
      'Add-WindowsPackage -Online -NoRestart -IgnoreCheck -PackagePath "$packagePath"',
    );
    await File(packagePath).delete();
  }

  Future<void> uninstall() async => runPSCommand(
    'Get-WindowsPackage -Online -PackageName "${type.packageName}*" | Remove-WindowsPackage -Online -NoRestart',
  );
}

final class SystemPackagesRemovalService extends WinPackageService {
  const SystemPackagesRemovalService({required super.api})
    : super(type: .systemComponentsRemoval);
}

final class OneDriveRemovalService extends WinPackageService {
  const OneDriveRemovalService({required super.api})
    : super(type: .oneDriveRemoval);
}

/// [install] and [uninstall] methods are overridden to call [SecurityService] methods instead of the base class methods, to ensure that Defender is properly disabled/enabled.
///
/// The [installPackage] and [uninstallPackage] methods are provided to allow calling the base class methods directly when needed.
final class DefenderRemovalService extends WinPackageService {
  const DefenderRemovalService({required this._security, required super.api})
    : super(type: .defenderRemoval);

  final SecurityService _security;

  @override
  Future<void> install() async => _security.disableDefenderCLI();
  @override
  Future<void> uninstall() async => _security.enableDefenderCLI();

  Future<void> installPackage() async {
    await super.install();
  }

  Future<void> uninstallPackage() async {
    await super.uninstall();
  }
}

final class AiRemovalService extends WinPackageService {
  const AiRemovalService({required this._store, required super.api})
    : super(type: .aiRemoval);

  static const _copilotStoreId = '9nht9rb2f4hd';

  final StoreService _store;

  @override
  Future<void> install() async {
    await WinRegistryService.hidePageVisibilitySettings('aicomponents');
    await WinRegistryService.hidePageVisibilitySettings(
      'privacy-systemaimodels',
    );
    await runPSCommand(
      'Disable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart',
    );
    await runPSCommand(
      'Get-AppxPackage -AllUsers Microsoft.Copilot* | Remove-AppxPackage',
    );

    await super.install();
  }

  @override
  Future<void> uninstall() async {
    await WinRegistryService.unhidePageVisibilitySettings('aicomponents');
    await WinRegistryService.unhidePageVisibilitySettings(
      'privacy-systemaimodels',
    );

    await super.uninstall();

    await runPSCommand(
      'Enable-WindowsOptionalFeature -Online -FeatureName Recall -NoRestart',
    );
    await _installStorePackages(store: _store, ids: {_copilotStoreId});
  }
}

final class XboxRemovalService extends WinPackageService {
  const XboxRemovalService({required this._store, required super.api})
    : super(type: .xboxRemoval);

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

  final StoreService _store;

  @override
  Future<void> install() async {
    await runPSCommand(
      r"Get-AppxPackage -Name 'Microsoft.XboxGameCallableUI' | Remove-AppxPackage -PreserveRoamableApplicationData",
    );
    await runPSCommand(
      r"'Microsoft.Xbox.TCUI','Microsoft.XboxApp','Microsoft.GamingApp','Microsoft.GamingServices','Microsoft.Edge.GameAssist','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider' | ForEach-Object { Get-AppxPackage -AllUsers -Name $_ | Remove-AppxPackage -AllUsers }",
    );
    await super.install();
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
    await _installStorePackages(store: _store, ids: xboxStoreIds);
  }
}

Future<void> _installStorePackages({
  required StoreService store,
  required Set<String> ids,
  StoreRing ring = .releasePreview,
  StoreArch arch = .auto,
}) async {
  final StorePackagesByProductId packagesByProductId = await store
      .getPackages(productIds: ids, ring: ring, arch: arch)
      .then(
        (result) => result.when(
          success: (value) => value,
          failure: (exception) => throw exception,
        ),
      );
  final Set<StorePackageFileDownload> downloads = await store
      .download(
        ring: ring,
        packagesByProductId: packagesByProductId,
        cancelToken: CancelToken(),
        onProgress: (_) {},
      )
      .then(
        (result) => result.when(
          success: (value) => value,
          failure: (exception) => throw exception,
        ),
      );
  final Map<String, ProcessResult> installResults = await store
      .install(downloads: downloads)
      .then(
        (result) => result.when(
          success: (value) => value,
          failure: (exception) => throw exception,
        ),
      );
  final List<ProcessResult> failed = installResults.values
      .where((result) => result.exitCode != 0)
      .toList();
  if (failed.isNotEmpty) {
    throw Exception(failed.map((result) => result.stderr).join('\n'));
  }
}
