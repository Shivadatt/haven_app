import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'child_policy_record.dart';

/// Read and sync access for the child device's active policy.
///
/// Under Decision 4.3 (Q3 & Q4), policies are strictly parent-authoritative
/// and read-only on the child device. The child cannot create, edit, or reset
/// policies locally.
abstract interface class ChildPolicyRepository {
  /// Loads the active policy record.
  ///
  /// Returns the stored parent-synced policy if present.
  /// Returns an in-memory neutral record if no policy has been synced yet.
  /// Returns a typed [StorageFailure] if the stored envelope or document is corrupt.
  Future<Result<ChildPolicyRecord>> getPolicy();

  /// Persists an authoritative parent-synced policy envelope.
  ///
  /// Replaces `childLocalState.policy` atomically, preserving all registered
  /// local tables and other local-state sections.
  Future<Result<void>> saveSyncedPolicy({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  });
}
