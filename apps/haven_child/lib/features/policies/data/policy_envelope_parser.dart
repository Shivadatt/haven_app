import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'child_policy_record.dart';

/// Defensive parser and validator for persisted policy envelopes.
abstract final class PolicyEnvelopeParser {
  static const int currentEnvelopeVersion = 1;
  static const String originParentSynced = 'parent_synced';
  static const Set<String> _validScheduleTypes = {'bedtime', 'school', 'custom'};

  /// Parses and validates a raw policy envelope map from `haven_local.json`.
  static Result<ChildPolicyRecord> parseEnvelope(Map<Object?, Object?> raw) {
    if (!raw.containsKey('envelope_version')) {
      return const Err(StorageFailure('Missing envelope version', detail: 'missing_envelope_fields'));
    }
    final ver = raw['envelope_version'];
    if (ver is! int || ver <= 0) {
      return const Err(StorageFailure('Invalid envelope version', detail: 'invalid_envelope_version'));
    }
    if (ver > currentEnvelopeVersion) {
      return const Err(StorageFailure('Unsupported envelope version', detail: 'unsupported_envelope_version'));
    }
    if (raw['origin'] != originParentSynced) {
      return const Err(StorageFailure('Invalid policy origin', detail: 'invalid_policy_origin'));
    }
    final polVer = raw['policy_version'];
    if (polVer is! int || polVer <= 0) {
      return const Err(StorageFailure('Invalid policy version', detail: 'invalid_policy_version'));
    }
    final rawUp = raw['updated_at'];
    if (rawUp is! String) {
      return const Err(StorageFailure('Invalid updated_at', detail: 'invalid_policy_timestamp'));
    }
    final updatedAt = DateTime.tryParse(rawUp)?.toUtc();
    if (updatedAt == null) {
      return const Err(StorageFailure('Invalid ISO-8601 timestamp', detail: 'invalid_policy_timestamp'));
    }
    final rawConfig = raw['config'];
    if (rawConfig is! Map) {
      return const Err(StorageFailure('Malformed policy config', detail: 'malformed_policy_config'));
    }
    final configRes = parseConfig(rawConfig);
    if (configRes case Err(:final failure)) return Err(failure);

    return Ok(ChildPolicyRecord.parentSynced(
      config: configRes.valueOrNull!,
      policyVersion: polVer,
      updatedAt: updatedAt,
    ));
  }

  /// Parses and strictly validates a `PolicyConfig` map.
  /// Bypasses `PolicyConfig.fromJson` to guarantee empty schedules are preserved.
  static Result<PolicyConfig> parseConfig(Map<Object?, Object?> map) {
    final daily = map['daily_screen_time_limit_minutes'];
    if (daily is! int || daily < 0 || daily > 1440) {
      return const Err(StorageFailure('Invalid daily limit', detail: 'invalid_daily_limit'));
    }
    final rawScheds = map['schedules'];
    if (rawScheds is! List) {
      return const Err(StorageFailure('Schedules must be list', detail: 'invalid_schedules_list'));
    }
    final schedules = <PolicySchedule>[];
    for (final item in rawScheds) {
      final sRes = _parseSchedule(item);
      if (sRes case Err(:final failure)) return Err(failure);
      schedules.add(sRes.valueOrNull!);
    }
    final apps = map['app_policies'];
    if (apps is! Map) {
      return const Err(StorageFailure('app_policies must be object', detail: 'malformed_policy_config'));
    }
    final allowRes = _parseStrings(apps['allowed_apps'], 'allowed_apps', PolicyRules.validatePackageName, 'invalid_package_name');
    if (allowRes case Err(:final failure)) return Err(failure);
    final blockRes = _parseStrings(apps['blocked_apps'], 'blocked_apps', PolicyRules.validatePackageName, 'invalid_package_name');
    if (blockRes case Err(:final failure)) return Err(failure);
    final limitsRes = _parseAppLimits(apps['app_limits']);
    if (limitsRes case Err(:final failure)) return Err(failure);

    final web = map['website_policies'];
    if (web is! Map) {
      return const Err(StorageFailure('website_policies must be object', detail: 'malformed_policy_config'));
    }
    final allowDomRes = _parseStrings(web['allowed_domains'], 'allowed_domains', PolicyRules.validateDomain, 'invalid_policy_config');
    if (allowDomRes case Err(:final failure)) return Err(failure);
    final blockDomRes = _parseStrings(web['blocked_domains'], 'blocked_domains', PolicyRules.validateDomain, 'invalid_policy_config');
    if (blockDomRes case Err(:final failure)) return Err(failure);

    if (web['safe_search_enabled'] is! bool) {
      return const Err(StorageFailure('safe_search must be bool', detail: 'invalid_safe_search_enabled'));
    }
    return Ok(PolicyConfig(
      dailyScreenTimeMinutes: daily,
      schedules: schedules,
      allowedApps: allowRes.valueOrNull!,
      blockedApps: blockRes.valueOrNull!,
      appLimits: limitsRes.valueOrNull!,
      allowedDomains: allowDomRes.valueOrNull!,
      blockedDomains: blockDomRes.valueOrNull!,
      safeSearchEnabled: web['safe_search_enabled'] as bool,
    ));
  }

  static Result<PolicySchedule> _parseSchedule(Object? raw) {
    if (raw is! Map) return const Err(StorageFailure('Schedule not object', detail: 'malformed_schedule_entry'));
    final id = raw['id'];
    if (id is! String || id.trim().isEmpty) return const Err(StorageFailure('Invalid id', detail: 'invalid_schedule_id'));
    final name = raw['name'];
    if (name is! String || name.trim().isEmpty) return const Err(StorageFailure('Invalid name', detail: 'invalid_schedule_name'));
    final typeStr = raw['type'];
    if (typeStr is! String || !_validScheduleTypes.contains(typeStr)) {
      return const Err(StorageFailure('Invalid schedule type', detail: 'invalid_schedule_type'));
    }
    final s = raw['start_time'];
    final e = raw['end_time'];
    if (s is! String || e is! String || !PolicySchedule.isValidTime(s) || !PolicySchedule.isValidTime(e)) {
      return const Err(StorageFailure('Invalid time', detail: 'invalid_schedule_time'));
    }
    final rawDays = raw['days'];
    if (rawDays is! List || rawDays.isEmpty) return const Err(StorageFailure('Days empty', detail: 'invalid_schedule_days'));
    final days = <int>[];
    for (final d in rawDays) {
      if (d is! int || d < 1 || d > 7) return const Err(StorageFailure('Day out of range', detail: 'invalid_schedule_days'));
      days.add(d);
    }
    if (raw['is_active'] is! bool) return const Err(StorageFailure('is_active not bool', detail: 'malformed_schedule_entry'));
    final allowRes = _parseStrings(raw['allowed_apps'] ?? const <String>[], 'schedule_allowed_apps', PolicyRules.validatePackageName, 'invalid_package_name');
    if (allowRes case Err(:final failure)) return Err(failure);

    return Ok(PolicySchedule(
      id: id.trim(),
      name: name.trim(),
      type: PolicyScheduleType.fromWire(typeStr),
      startTime: s,
      endTime: e,
      days: days,
      isActive: raw['is_active'] as bool,
      allowedApps: allowRes.valueOrNull!,
      category: raw['category'] is String ? raw['category'] as String : null,
    ));
  }

  static Result<List<String>> _parseStrings(Object? raw, String f, String? Function(String?) v, String d) {
    if (raw is! List) return Err(StorageFailure('$f not list', detail: d));
    final list = <String>[];
    for (final item in raw) {
      if (item is! String || v(item) != null) return Err(StorageFailure('Invalid in $f', detail: d));
      list.add(item);
    }
    return Ok(list);
  }

  static Result<Map<String, int>> _parseAppLimits(Object? raw) {
    if (raw is! Map) return const Err(StorageFailure('app_limits not map', detail: 'invalid_package_name'));
    final map = <String, int>{};
    for (final entry in raw.entries) {
      final k = entry.key;
      final v = entry.value;
      if (k is! String || PolicyRules.validatePackageName(k) != null) {
        return const Err(StorageFailure('Invalid pkg in app_limits', detail: 'invalid_package_name'));
      }
      if (v is! int || PolicyRules.validateMinutesLimit(v) != null) {
        return const Err(StorageFailure('Invalid limit in app_limits', detail: 'invalid_app_limit_range'));
      }
      map[k] = v;
    }
    return Ok(map);
  }
}
