import 'package:riverpod/riverpod.dart';

import '../data/appx_repository.dart';
import '../domain/appx_service.dart';

/// Provides the default [AppxRepository].
final appxRepositoryProvider = Provider<AppxRepository>((ref) => NativeAppxRepository());

/// Provides the default [AppxService].
final appxServiceProvider = Provider<AppxService>(
  (ref) => AppxService(
    repository: ref.watch(appxRepositoryProvider),
    retryDelay: AppxService.defaultRetryDelay,
  ),
);
