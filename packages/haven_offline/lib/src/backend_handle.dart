import 'package:haven_core/haven_core.dart';

import 'backend_status.dart';
import 'data_contracts.dart';

/// What startup actually resolved, so a screen can explain itself.
final class HavenBackendHandle {
  const HavenBackendHandle(this.status);

  final BackendStatus status;
}

/// Fallback edge caller for builds without a live backend connection.
final class EdgeCallerUnavailable implements EdgeCaller {
  @override
  Future<Result<EdgeReply>> invoke(
    String slug,
    Map<String, Object?> body, {
    Map<String, String> deviceHeaders = const {},
  }) async => Err(
    const NetworkFailure(
      'This build is not connected to a backend.',
      detail: 'edge caller unavailable',
    ),
  );
}

