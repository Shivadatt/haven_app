import 'package:haven_models/haven_models.dart'
    show asInt, asList, asMap;

import 'policy_rules.dart';
import 'policy_schedules.dart';

/// Complete parental policy configuration for a family or device.
final class PolicyConfig {
  const PolicyConfig({
    required this.dailyScreenTimeMinutes,
    required this.schedules,
    required this.allowedApps,
    required this.blockedApps,
    required this.appLimits,
    required this.allowedDomains,
    required this.blockedDomains,
  });

  factory PolicyConfig.defaults() => PolicyConfig(
    dailyScreenTimeMinutes: 120,
    schedules: [
      PolicySchedule.defaultBedtime(),
      PolicySchedule.defaultSchool(),
    ],
    allowedApps: const ['com.android.calculator2', 'com.google.android.apps.docs'],
    blockedApps: const ['com.zhiliaoapp.musically', 'com.instagram.android'],
    appLimits: const {'com.google.android.youtube': 30},
    allowedDomains: const ['wikipedia.org', 'khanacademy.org'],
    blockedDomains: const ['tiktok.com', 'gambling.com'],
  );

  factory PolicyConfig.fromJson(Map<String, Object?> json) {
    final scheds = asList(json['schedules'])
        .map((s) => PolicySchedule.fromJson(asMap(s)))
        .toList();

    final apps = asMap(json['app_policies']);
    final limitsRaw = asMap(apps['app_limits']);
    final limits = <String, int>{};
    for (final entry in limitsRaw.entries) {
      final m = asInt(entry.value);
      if (m != null) limits[entry.key] = m;
    }

    final web = asMap(json['website_policies']);

    return PolicyConfig(
      dailyScreenTimeMinutes:
          asInt(json['daily_screen_time_limit_minutes']) ?? 120,
      schedules: scheds.isEmpty ? PolicyConfig.defaults().schedules : scheds,
      allowedApps: asList(apps['allowed_apps']).cast<String>().toList(),
      blockedApps: asList(apps['blocked_apps']).cast<String>().toList(),
      appLimits: limits,
      allowedDomains: asList(web['allowed_domains']).cast<String>().toList(),
      blockedDomains: asList(web['blocked_domains']).cast<String>().toList(),
    );
  }

  final int dailyScreenTimeMinutes;
  final List<PolicySchedule> schedules;
  final List<String> allowedApps;
  final List<String> blockedApps;
  final Map<String, int> appLimits;
  final List<String> allowedDomains;
  final List<String> blockedDomains;

  Map<String, Object?> toJson() => <String, Object?>{
    'daily_screen_time_limit_minutes': dailyScreenTimeMinutes,
    'schedules': schedules.map((s) => s.toJson()).toList(),
    'app_policies': <String, Object?>{
      'allowed_apps': allowedApps,
      'blocked_apps': blockedApps,
      'app_limits': appLimits,
    },
    'website_policies': <String, Object?>{
      'allowed_domains': allowedDomains,
      'blocked_domains': blockedDomains,
    },
  };

  PolicyConfig copyWith({
    int? dailyScreenTimeMinutes,
    List<PolicySchedule>? schedules,
    List<String>? allowedApps,
    List<String>? blockedApps,
    Map<String, int>? appLimits,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
  }) => PolicyConfig(
    dailyScreenTimeMinutes:
        dailyScreenTimeMinutes ?? this.dailyScreenTimeMinutes,
    schedules: schedules ?? this.schedules,
    allowedApps: allowedApps ?? this.allowedApps,
    blockedApps: blockedApps ?? this.blockedApps,
    appLimits: appLimits ?? this.appLimits,
    allowedDomains: allowedDomains ?? this.allowedDomains,
    blockedDomains: blockedDomains ?? this.blockedDomains,
  );

  String? validate() {
    final timeErr = PolicyRules.validateMinutesLimit(dailyScreenTimeMinutes);
    if (timeErr != null) return timeErr;
    for (final domain in [...allowedDomains, ...blockedDomains]) {
      final domErr = PolicyRules.validateDomain(domain);
      if (domErr != null) return '$domErr: $domain';
    }
    return null;
  }
}
