import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:path/path.dart' as p;
import 'package:win32_registry/win32_registry.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/win_registry_service.dart';
import '../../../core/utils/base_service.dart';
import '../../../utils.dart';
import '../../ms_store/domain/entities/store_download_info.dart';
import '../../ms_store/domain/entities/store_enums.dart';
import '../../ms_store/domain/services/store_service.dart';
import '../../tweaks/security/security_service.dart';
import '../data/datasources/api_cab_datasource.dart';
import '../data/repositories/win_package_repository.dart';
import '../data/repositories/win_package_repository_impl.dart';
import './entities/win_package.dart';
import './winsxs_exceptions.dart';

export '../data/repositories/win_package_repository.dart';
export './entities/win_package.dart';

abstract base class const WinPackageService({
  required final WinPackageType _type,
  required final WinPackageRepository _repository,
}) with BaseService {
  static final String cabPath = p.join(Directory.systemTemp.path, 'Revision-Tool', 'CAB');

  /// Enhanced key usage expected on CAB signer certificates.
  static const _systemComponentVerificationOid = '1.3.6.1.4.1.311.10.3.6';

  static WinPackageRepository createRepository(ApiClient api) {
    return WinPackageRepositoryImpl(api: ApiCabDataSource(api: api));
  }

  static bool checkPackageInstalled(WinPackageType p) {
    return WinPackageRepositoryImpl.isCbsPackageInstalled(p.packageName);
  }

  @override
  ErrorMapper get errorMapper => (error, stackTrace) {
    if (error is AppException) return error;
    if (error is WinSxSException) {
      return UnexpectedNetworkException(message: error.message, cause: error);
    }
    return UnexpectedNetworkException(cause: error);
  };

  @override
  String get logTag => 'WinPackageService';

  /// Downloads [type] from GitHub or uses the bundled package if available.
  ///
  /// Returns [DownloadedPackage] with the path and version of the package.
  Future<Result<DownloadedPackage>> download({String? path}) {
    final String downloadPath = path ?? cabPath;

    return run(() async {
      try {
        logger.i('Attempting to download package from GitHub...');

        _repository.ensureDirectory(downloadPath);

        final WinPackageRelease release = (await _repository.fetchRelease()).toDomain();

        final WinPackageVersion? releaseVersion = parsePackageVersion('~~${release.tagName}');
        if (releaseVersion == null) {
          throw InvalidWinSxSPackageVersionException('Invalid release version: ${release.tagName}');
        }

        final CabAsset? asset = release.assets.firstWhereOrNull(
          (a) =>
              a.name.startsWith('${_type.packageName}$winPackagePublicKeyToken') &&
              a.name.contains(WinRegistryService.cpuArch),
        );
        if (asset == null) {
          throw WinSxSPackageNotFoundException(
            'No matching package found for ${_type.packageName} with architecture ${WinRegistryService.cpuArch}',
          );
        }

        final String filePath = p.join(downloadPath, asset.name);

        await _repository.downloadAsset(asset: asset, filePath: filePath);

        logger.i('Successfully downloaded package from GitHub: $filePath');
        return DownloadedPackage(path: filePath, version: releaseVersion);
      } catch (e, stackTrace) {
        logger.w('Failed to download from GitHub', error: e, stackTrace: stackTrace);
        logger.i('Falling back to bundled packages...');

        if (_repository.findBundledPackage(_type) case final bundledPath?
            when _repository.fileExists(bundledPath)) {
          logger.i('Using bundled package: $bundledPath');

          final String targetPath = switch (path) {
            null => bundledPath,
            final dir => p.join(dir, p.basename(bundledPath)),
          };
          if (path case final dir?) {
            _repository.ensureDirectory(dir);
            _repository.copyFile(sourcePath: bundledPath, targetPath: targetPath);
          }
          final WinPackageVersion? bundledVersion = parsePackageVersion(
            p.basenameWithoutExtension(targetPath),
          );
          if (bundledVersion == null) {
            throw InvalidWinSxSPackageVersionException(
              'Invalid bundled package version: $targetPath',
            );
          }
          return .new(path: targetPath, version: bundledVersion);
        }

        throw WinSxSPackageDownloadException(
          'Failed to download package from GitHub and no bundled package available',
          e,
        );
      }
    });
  }

  Future<Result<void>> install({bool force = false}) {
    logger.i('winsxs: Downloading package=${_type.packageName}');
    return run(() async {
      final DownloadedPackage package = (await download()).when(
        success: (d) => d,
        failure: (e) => throw e,
      );
      await _installCab(package.path, packageVersion: package.version, force: force);
    });
  }

  Future<void> _installCab(
    String packagePath, {
    required WinPackageVersion packageVersion,
    required bool force,
  }) async {
    logger.i('winsxs: Installing package=${_type.packageName}, path=$packagePath');

    if (!_repository.fileExists(packagePath)) {
      throw WinSxSPackageFileNotFoundException('Package file does not exist: $packagePath');
    }

    final IList<String> installedPackageNames = await _repository.fetchInstalledPackageNames(_type);
    final IList<WinPackageVersion?> installedVersions = installedPackageNames
        .map(parsePackageVersion)
        .toIList();
    if (installedVersions.any((version) => version == null)) {
      throw InvalidWinSxSPackageVersionException(
        'Invalid installed package version for ${_type.packageName}',
      );
    }
    if (installedVersions.isNotEmpty) {
      final WinPackageVersion latestInstalledVersion = installedVersions
          .whereType<WinPackageVersion>()
          .reduce((left, right) => comparePackageVersions(left, right) >= 0 ? left : right);

      if (!force && comparePackageVersions(packageVersion, latestInstalledVersion) <= 0) {
        logger.i('winsxs: Skipping package=${_type.packageName}; installed version is current');
        _repository.deleteTempPackage(packagePath);
        return;
      }
    }

    final String certValue = await _repository.fetchSignatureUsage(packagePath);
    if (certValue.isEmpty || certValue != _systemComponentVerificationOid) {
      throw InvalidWinSxSPackageSignatureException('Invalid signature: $packagePath');
    }

    await _repository.addPackage(packagePath);
    await _repository.removePackagesExcept(_type, p.basenameWithoutExtension(packagePath));
    _repository.deleteTempPackage(packagePath);
  }

  Future<Result<void>> uninstall() {
    return run(() async {
      try {
        await _repository.removePackages(_type);
      } catch (error) {
        try {
          final DownloadedPackage package = (await download()).when(
            success: (d) => d,
            failure: (e) => throw e,
          );
          await _repository.addPackage(package.path);
          await _repository.removePackages(_type);
          _repository.deleteTempPackage(package.path);
        } catch (retryError) {
          throw WinSxSPackageUninstallException(
            'Failed to uninstall ${_type.packageName} after recovery attempt. Contact support at https://revi.cc/.',
            'Original error: $error; Retry error: $retryError',
          );
        }
      }
    });
  }
}

final class const SystemPackagesRemovalService({required super.repository})
    extends WinPackageService {
  this : super(type: .systemComponentsRemoval);
}

final class const OneDriveRemovalService({required super.repository}) extends WinPackageService {
  this : super(type: .oneDriveRemoval);
}

/// [install] and [uninstall] methods are overridden to call [SecurityService] methods instead of the base class methods, to ensure that Defender is properly disabled/enabled.
///
/// The [installPackage] and [uninstallPackage] methods are provided to allow calling the base class methods directly when needed.
final class const DefenderRemovalService({
  required final SecurityService _security,
  required super.repository,
}) extends WinPackageService {
  this : super(type: .defenderRemoval);

  @override
  @override
  Future<Result<void>> install({bool force = false}) =>
      run(() => _security.disableDefenderCLI(force: force));

  @override
  Future<Result<void>> uninstall() => run(_security.enableDefenderCLI);

  Future<Result<void>> installPackage({bool force = false}) => super.install(force: force);

  Future<Result<void>> uninstallPackage() => super.uninstall();
}

final class const AiRemovalService({required final StoreService _store, required super.repository})
    extends WinPackageService {
  this : super(type: .aiRemoval);

  static const _copilotStoreId = '9nht9rb2f4hd';
  static const _fabricAIPath =
      r'C:\Windows\SystemApps\Microsoft.AIFabric.CBS.1.6_8wekyb3d8bbwe\AppxManifest.xml';

  @override
  Future<Result<void>> install({bool force = false}) async {
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

    return super.install(force: force);
  }

  @override
  Future<Result<void>> uninstall() {
    return run(() async {
      await WinRegistryService.unhidePageVisibilitySettings('aicomponents');
      await WinRegistryService.unhidePageVisibilitySettings('privacy-systemaimodels');

      (await super.uninstall()).when(success: (_) {}, failure: (e) => throw e);

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
    });
  }
}

final class const XboxRemovalService({
  required final StoreService _store,
  required super.repository,
}) extends WinPackageService {
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
  Future<Result<void>> install({bool force = false}) async {
    await runPSCommand(
      r"Get-AppxPackage -Name 'Microsoft.XboxGameCallableUI' | Remove-AppxPackage -PreserveRoamableApplicationData",
    );
    await runPSCommand(
      r"'Microsoft.Xbox.TCUI','Microsoft.XboxApp','Microsoft.GamingApp','Microsoft.GamingServices','Microsoft.Edge.GameAssist','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider' | ForEach-Object { Get-AppxPackage -AllUsers -Name $_ | Remove-AppxPackage -AllUsers }",
    );
    return super.install(force: force);
  }

  @override
  Future<Result<void>> uninstall() {
    return run(() async {
      (await super.uninstall()).when(success: (_) {}, failure: (e) => throw e);
      if (File(_callableUiManifestPath).existsSync()) {
        logger.i('winsxs: Re-registering XboxGameCallableUI package...');
        await runPSCommand(
          'Add-AppxPackage -Register -DisableDevelopmentMode -Path "$_callableUiManifestPath"',
        );
      }
      logger.i('winsxs: Reinstalling Xbox packages from Microsoft Store...');
      for (final MapEntry(:key, :value) in _storePackages.entries) {
        if (value.isEmpty) {
          logger.w('winsxs: No Store ID for $key, skipping reinstallation.');
        }
      }
      final ISet<String> xboxStoreIds = _storePackages.values.where((id) => id.isNotEmpty).toISet();
      await _installStorePackages(store: _store, ids: xboxStoreIds);
    });
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
