import 'dart:async';
import 'dart:isolate';

typedef ComputeCallback<M, R> = FutureOr<R> Function(M message);

/// Runs [callback] in a background isolate and returns its result.
/// Flutter's built-in `compute` function cannot be used in CLI version.
Future<R> compute<M, R>(ComputeCallback<M, R> callback, M message) {
  return Isolate.run(() => callback(message));
}
