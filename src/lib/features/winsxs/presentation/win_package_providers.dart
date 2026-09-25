import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../ms_store/domain/services/store_service.dart';
import '../../tweaks/security/security_service.dart';
import '../domain/win_package_service.dart';

export '../domain/win_package_service.dart';

final ProviderFamily<WinPackageService, WinPackageType> winPackageServiceProvider =
    Provider.family<WinPackageService, WinPackageType>((ref, type) {
      final WinPackageRepository repository = WinPackageService.createRepository(
        ref.watch(apiClientProvider),
      );
      return switch (type) {
        .systemComponentsRemoval => SystemPackagesRemovalService(repository: repository),
        .oneDriveRemoval => OneDriveRemovalService(repository: repository),
        .defenderRemoval => DefenderRemovalService(
          security: ref.watch(securityServiceProvider),
          repository: repository,
        ),
        .aiRemoval => AiRemovalService(
          store: ref.watch(storeServiceProvider),
          repository: repository,
        ),
        .xboxRemoval => XboxRemovalService(
          store: ref.watch(storeServiceProvider),
          repository: repository,
        ),
      };
    });
