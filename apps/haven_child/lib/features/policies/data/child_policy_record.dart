import 'package:haven_models/haven_models.dart';

/// The origin and trust level of an active child device policy.
enum PolicyProvenance {
  /// Un-paired child device running an in-memory neutral fallback.
  /// Never persisted to disk.
  inMemoryNeutral,

  /// Authoritative parent policy synced from backend.
  /// Persisted in haven_local.json under childLocalState.policy.
  parentSynced,
}

/// The active policy record on a child device, pairing policy rules with provenance.
final class ChildPolicyRecord {
  ChildPolicyRecord({
    required this.config,
    required this.provenance,
    this.policyVersion,
    this.updatedAt,
  }) {
    if (provenance == PolicyProvenance.parentSynced) {
      if (policyVersion == null || policyVersion! <= 0) {
        throw ArgumentError.value(
          policyVersion,
          'policyVersion',
          'Parent-synced policy must have a positive version number.',
        );
      }
      if (updatedAt == null) {
        throw ArgumentError.notNull('updatedAt');
      }
    } else {
      if (policyVersion != null) {
        throw ArgumentError.value(
          policyVersion,
          'policyVersion',
          'In-memory neutral policy cannot have a policy version.',
        );
      }
      if (updatedAt != null) {
        throw ArgumentError.value(
          updatedAt,
          'updatedAt',
          'In-memory neutral policy cannot have an updated timestamp.',
        );
      }
    }
  }

  factory ChildPolicyRecord.inMemoryNeutral() => ChildPolicyRecord(
    config: inMemoryNeutralPolicy,
    provenance: PolicyProvenance.inMemoryNeutral,
    policyVersion: null,
    updatedAt: null,
  );

  factory ChildPolicyRecord.parentSynced({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  }) => ChildPolicyRecord(
    config: config,
    provenance: PolicyProvenance.parentSynced,
    policyVersion: policyVersion,
    updatedAt: updatedAt,
  );

  final PolicyConfig config;
  final PolicyProvenance provenance;
  final int? policyVersion;
  final DateTime? updatedAt;

  bool get isParentSynced => provenance == PolicyProvenance.parentSynced;
  bool get isUnlimitedQuota => provenance == PolicyProvenance.inMemoryNeutral;

  /// Creates a deterministic evaluation context for PolicyEvaluator.
  /// Encapsulates Decision 4.3 unlimited quota semantics for neutral policies.
  PolicyEvaluationContext toEvaluationContext({
    required DateTime evaluationTime,
  }) {
    if (isUnlimitedQuota) {
      return PolicyEvaluationContext.withUnlimitedQuota(
        config: config,
        evaluationTime: evaluationTime,
      );
    }
    return PolicyEvaluationContext(
      config: config,
      evaluationTime: evaluationTime,
    );
  }

  /// Canonical neutral configuration imposing zero restrictions.
  static const PolicyConfig inMemoryNeutralPolicy = PolicyConfig(
    dailyScreenTimeMinutes: 1440,
    schedules: <PolicySchedule>[],
    allowedApps: <String>[],
    blockedApps: <String>[],
    appLimits: <String, int>{},
    allowedDomains: <String>[],
    blockedDomains: <String>[],
    safeSearchEnabled: false,
  );
}
