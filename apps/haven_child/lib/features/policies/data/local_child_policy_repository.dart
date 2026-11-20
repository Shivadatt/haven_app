import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_offline/haven_offline.dart';

import '../../../core/storage/child_database.dart';
import '../../../core/storage/child_local_state.dart';
import 'child_policy_record.dart';
import 'child_policy_repository.dart';
import 'policy_envelope_parser.dart';

/// Local store implementation for child policy using Option B raw inspection.
final class LocalChildPolicyRepository implements ChildPolicyRepository {
  LocalChildPolicyRepository({
    required LocalStore store,
    required ChildLocalStateStore state,
  }) : _store = store,
       _state = state;

  factory LocalChildPolicyRepository.fromDatabase(ChildDatabase database) =>
      LocalChildPolicyRepository(
        store: database.store,
        state: database.localState,
      );

  final LocalStore _store;
  final ChildLocalStateStore _state;

  static const String policySection = 'policy';

  @override
  Future<Result<ChildPolicyRecord>> getPolicy() async {
    final loaded = await _store.load();
    if (loaded case Err(:final failure)) return Err(failure);
    final database = loaded.valueOrNull!;

    if (!database.containsKey(ChildLocalStateStore.documentKey)) {
      return Ok(ChildPolicyRecord.inMemoryNeutral());
    }

    final rawState = database[ChildLocalStateStore.documentKey];
    if (rawState == null) {
      return const Err(
        StorageFailure('Corrupt child local state: null value', detail: 'malformed_child_local_state_null'),
      );
    }
    if (rawState is! Map) {
      return const Err(
        StorageFailure('Corrupt child local state: expected object', detail: 'malformed_child_local_state_not_map'),
      );
    }

    final state = rawState;
    if (!state.containsKey(policySection)) {
      return Ok(ChildPolicyRecord.inMemoryNeutral());
    }

    final rawPolicy = state[policySection];
    if (rawPolicy == null) {
      return const Err(
        StorageFailure('Malformed policy section: null policy entry', detail: 'malformed_policy_section_null'),
      );
    }
    if (rawPolicy is! Map) {
      return const Err(
        StorageFailure('Malformed policy section: expected object', detail: 'malformed_policy_section_not_map'),
      );
    }

    return PolicyEnvelopeParser.parseEnvelope(rawPolicy as Map<Object?, Object?>);
  }

  @override
  Future<Result<void>> saveSyncedPolicy({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  }) async {
    if (policyVersion <= 0) {
      return const Err(StorageFailure('Policy version must be positive', detail: 'invalid_policy_version'));
    }

    final valErr = _validateConfig(config);
    if (valErr != null) return Err(valErr);

    final normalizedUtc = updatedAt.toUtc();
    final envelope = <String, Object?>{
      'envelope_version': PolicyEnvelopeParser.currentEnvelopeVersion,
      'origin': PolicyEnvelopeParser.originParentSynced,
      'policy_version': policyVersion,
      'updated_at': normalizedUtc.toIso8601String(),
      'config': config.toJson(),
    };

    return _state.writeSection(policySection, envelope);
  }

  static StorageFailure? _validateConfig(PolicyConfig config) {
    final modelErr = config.validate();
    if (modelErr != null) {
      return StorageFailure(modelErr, detail: 'invalid_policy_config');
    }

    for (final pkg in [...config.allowedApps, ...config.blockedApps]) {
      if (PolicyRules.validatePackageName(pkg) != null) {
        return StorageFailure('Invalid package name "$pkg"', detail: 'invalid_package_name');
      }
    }

    for (final entry in config.appLimits.entries) {
      if (PolicyRules.validatePackageName(entry.key) != null) {
        return StorageFailure('Invalid package key "${entry.key}"', detail: 'invalid_package_name');
      }
      if (PolicyRules.validateMinutesLimit(entry.value) != null) {
        return StorageFailure('Invalid minute limit for "${entry.key}"', detail: 'invalid_app_limit_range');
      }
    }

    for (final s in config.schedules) {
      if (s.id.trim().isEmpty) {
        return const StorageFailure('Schedule id cannot be empty', detail: 'invalid_schedule_id');
      }
      if (s.name.trim().isEmpty) {
        return const StorageFailure('Schedule name cannot be empty', detail: 'invalid_schedule_name');
      }
      if (!PolicySchedule.isValidTime(s.startTime) || !PolicySchedule.isValidTime(s.endTime)) {
        return const StorageFailure('Invalid schedule start/end time', detail: 'invalid_schedule_time');
      }
      if (s.days.isEmpty || s.days.any((d) => d < 1 || d > 7)) {
        return const StorageFailure('Schedule days must be in 1..7', detail: 'invalid_schedule_days');
      }
      for (final pkg in s.allowedApps) {
        if (PolicyRules.validatePackageName(pkg) != null) {
          return StorageFailure('Invalid whitelist package in schedule', detail: 'invalid_package_name');
        }
      }
    }

    return null;
  }
}
