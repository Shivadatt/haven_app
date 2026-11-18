import 'package:meta/meta.dart';

import '../policy_config.dart';

/// Immutable context supplied to the pure-Dart policy evaluator.
@immutable
final class PolicyEvaluationContext {
  /// Standard production constructor.
  /// Fully encapsulated with zero emergency package injection parameters.
  PolicyEvaluationContext({
    required this.config,
    required this.evaluationTime,
    this.dailyLimitMinutesOverride,
    this.hasDailyLimitOverride = false,
  }) {
    if (hasDailyLimitOverride &&
        dailyLimitMinutesOverride != null &&
        dailyLimitMinutesOverride! < 0) {
      throw ArgumentError.value(
        dailyLimitMinutesOverride,
        'dailyLimitMinutesOverride',
        'Daily limit override cannot be negative.',
      );
    }
  }

  /// Production factory creating a context with an explicit unlimited daily quota.
  factory PolicyEvaluationContext.withUnlimitedQuota({
    required PolicyConfig config,
    required DateTime evaluationTime,
  }) => PolicyEvaluationContext(
    config: config,
    evaluationTime: evaluationTime,
    dailyLimitMinutesOverride: null,
    hasDailyLimitOverride: true,
  );

  /// Production factory creating a context with an explicit quota override in minutes.
  /// Rejects negative values per Decision 2.13.
  factory PolicyEvaluationContext.withQuotaOverride({
    required PolicyConfig config,
    required DateTime evaluationTime,
    required int minutes,
  }) {
    if (minutes < 0) {
      throw ArgumentError.value(
        minutes,
        'dailyLimitMinutesOverride',
        'Daily limit override cannot be negative.',
      );
    }
    return PolicyEvaluationContext(
      config: config,
      evaluationTime: evaluationTime,
      dailyLimitMinutesOverride: minutes,
      hasDailyLimitOverride: true,
    );
  }

  /// The active policy configuration to evaluate against.
  final PolicyConfig config;

  /// Injected timestamp for deterministic evaluation (no DateTime.now()).
  final DateTime evaluationTime;

  /// Optional override for daily screen time limit in minutes.
  final int? dailyLimitMinutesOverride;

  /// Whether an explicit caller override is active.
  final bool hasDailyLimitOverride;

  /// Private immutable approved emergency packages (Decisions 2.2, 2.12).
  /// Strictly encapsulated; never exposed as a public constant or getter.
  static const Set<String> _defaultEmergencyPackages = {
    'com.android.phone',
    'com.google.android.dialer',
    'com.samsung.android.dialer',
    'com.android.emergency',
    'com.google.android.apps.safetyhub',
  };

  /// Returns true if [packageName] is one of the five approved emergency defaults.
  static bool isEmergencyPackage(String packageName) =>
      _defaultEmergencyPackages.contains(packageName);

  /// Effective daily screen time quota in minutes.
  /// - Returns null if quota is unlimited.
  /// - Returns 0 if zero minutes are permitted.
  /// - Returns positive integer for configured allowance.
  /// - Throws ArgumentError if an active override is negative (Decision 2.13).
  int? get effectiveDailyLimit {
    if (!hasDailyLimitOverride) {
      return config.dailyScreenTimeMinutes;
    }
    final override = dailyLimitMinutesOverride;
    if (override != null && override < 0) {
      throw ArgumentError.value(
        override,
        'dailyLimitMinutesOverride',
        'Daily limit override cannot be negative.',
      );
    }
    return override;
  }
}
