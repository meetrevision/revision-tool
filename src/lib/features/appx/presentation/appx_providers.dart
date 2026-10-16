import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/error/result.dart';
import '../data/appx_repository.dart';
import '../domain/appx_service.dart';
import '../domain/entities/appx_package.dart';

/// Provides the default [AppxRepository].
final appxRepositoryProvider = Provider<AppxRepository>((ref) => NativeAppxRepository());

/// Provides the default [AppxService].
final appxServiceProvider = Provider<AppxService>(
  (ref) => AppxService(
    repository: ref.watch(appxRepositoryProvider),
    retryDelay: AppxService.defaultRetryDelay,
  ),
);

final FutureProviderFamily<AppxPackage?, String> appxInstalledPackageProvider = FutureProvider
    .autoDispose
    .family<AppxPackage?, String>((ref, familyName) async {
      final Result<AppxPackage?> result = await ref
          .watch(appxServiceProvider)
          .findInstalled(familyName: familyName);
      return result.when(success: (package) => package, failure: (error) => throw error);
    });
