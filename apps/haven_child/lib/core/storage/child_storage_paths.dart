import 'package:haven_core/haven_core.dart';
import 'package:path_provider/path_provider.dart';

/// Where the child app's local JSON document lives, resolved once per boot.
///
/// [resolve] never throws: a missing plugin (test host) or a folder the OS
/// refuses becomes a typed [StorageFailure], because every caller is a
/// repository boundary that may only answer with `Result`.
///
/// [overrideForTests] is the seam Agent 1's handoff asked for: a test points
/// the whole storage lane at a temp directory, exactly like the parent's
/// `InitialBindings.startBackend({offlineDirectory})` but without leaking the
/// parameter through every screen.
abstract final class ChildStoragePaths {
  static Future<String> Function()? _override;

  /// Test/host seam. Pass `null` to restore the real documents directory.
  static void overrideForTests(Future<String> Function()? resolver) {
    _override = resolver;
  }

  /// The documents directory of this app's own sandbox. Stage 1 is local-only,
  /// so this is the one and only storage root the child app knows.
  static Future<Result<String>> resolve() async {
    try {
      final Future<String> Function()? override = _override;
      if (override != null) return Ok(await override());
      final directory = await getApplicationDocumentsDirectory();
      return Ok(directory.path);
    } on Object catch (error) {
      // MissingPluginException on a test host and FileSystemException on a
      // locked device are both honest "storage is not available here" answers.
      return Err<String>(
        StorageFailure(
          'Local storage is not available on this device.',
          detail: 'storage_path_unresolved: $error',
        ),
      );
    }
  }
}
