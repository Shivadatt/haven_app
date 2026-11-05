import 'package:haven_models/haven_models.dart' show asText;

/// Local notification preferences toggles.
final class NotificationPreferences {
  const NotificationPreferences({
    this.screenTimeAlerts = true,
    this.bedtimeAlerts = true,
    this.safeZoneAlerts = true,
    this.appInstallAlerts = true,
  });

  final bool screenTimeAlerts;
  final bool bedtimeAlerts;
  final bool safeZoneAlerts;
  final bool appInstallAlerts;

  NotificationPreferences copyWith({
    bool? screenTimeAlerts,
    bool? bedtimeAlerts,
    bool? safeZoneAlerts,
    bool? appInstallAlerts,
  }) => NotificationPreferences(
    screenTimeAlerts: screenTimeAlerts ?? this.screenTimeAlerts,
    bedtimeAlerts: bedtimeAlerts ?? this.bedtimeAlerts,
    safeZoneAlerts: safeZoneAlerts ?? this.safeZoneAlerts,
    appInstallAlerts: appInstallAlerts ?? this.appInstallAlerts,
  );

  static const NotificationPreferences defaults = NotificationPreferences();
}

/// Lightweight model representing the signed-in parent profile.
final class ParentProfileSummary {
  const ParentProfileSummary({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory ParentProfileSummary.fromRow(Map<String, Object?> row) =>
      ParentProfileSummary(
        id: asText(row['id']) ?? '',
        email: asText(row['email']) ?? '',
        displayName: asText(row['display_name']) ?? '',
        role: asText(row['role']) ?? 'parent',
      );

  final String id;
  final String email;
  final String displayName;
  final String role;
}
