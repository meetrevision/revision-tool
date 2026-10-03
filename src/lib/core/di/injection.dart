/// Dependency wiring, grouped by layer.
///
/// Each feature owns its own providers; this file is the one place that pulls
/// them together, so the entrypoints import from here instead of reaching into
/// feature folders. Add a feature's line when it is ported to this pattern.
library;

export '../../features/appx/presentation/appx_providers.dart';
