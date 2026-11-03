import 'enums_sessions.dart';
import 'json_utils.dart';

/// `public.location_events` — one reported fix.
///
/// `source` has no CHECK constraint, so it stays a string; the app never claims
/// a precision the reporter did not provide.
final class LocationEvent {
  const LocationEvent({
    required this.id,
    required this.deviceId,
    required this.familyId,
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.recordedAt,
    required this.receivedAt,
    required this.source,
  });

  factory LocationEvent.fromRow(Map<String, Object?> row) => LocationEvent(
    id: asText(row['id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    lat: asDouble(row['lat']) ?? 0,
    lng: asDouble(row['lng']) ?? 0,
    accuracyM: asDouble(row['accuracy_m']) ?? 0,
    recordedAt: asDate(row['recorded_at']) ?? DateTime.utc(1970),
    receivedAt: asDate(row['received_at']) ?? DateTime.utc(1970),
    source: asText(row['source']) ?? 'unknown',
  );

  final String id;
  final String deviceId;
  final String familyId;
  final double lat;
  final double lng;
  final double accuracyM;
  final DateTime recordedAt;
  final DateTime receivedAt;
  final String source;

  /// A stale fix is shown as stale; nothing pretends it is current position.
  bool isStale({required Duration maxAge, required DateTime now}) =>
      now.difference(recordedAt) > maxAge;
}

/// `public.safe_zones` — a circular place the parent named.
final class SafeZone {
  const SafeZone({
    required this.id,
    required this.familyId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.active,
    required this.createdAt,
    this.createdBy,
  });

  factory SafeZone.fromRow(Map<String, Object?> row) => SafeZone(
    id: asText(row['id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    name: asText(row['name']) ?? '',
    lat: asDouble(row['lat']) ?? 0,
    lng: asDouble(row['lng']) ?? 0,
    radiusM: asDouble(row['radius_m']) ?? 0,
    active: asBool(row['active']) ?? false,
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    createdBy: asText(row['created_by']),
  );

  final String id;
  final String familyId;
  final String name;
  final double lat;
  final double lng;
  final double radiusM;
  final bool active;
  final DateTime createdAt;
  final String? createdBy;

  SafeZone copyWith({
    String? name,
    double? lat,
    double? lng,
    double? radiusM,
    bool? active,
  }) => SafeZone(
    id: id,
    familyId: familyId,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusM: radiusM ?? this.radiusM,
    active: active ?? this.active,
    createdAt: createdAt,
    createdBy: createdBy,
  );

  /// Column names, not a payload: `active` gates whether the zone is evaluated.
  Map<String, Object?> toRow() => {
    'id': id,
    'family_id': familyId,
    'name': name,
    'lat': lat,
    'lng': lng,
    'radius_m': radiusM,
    'active': active,
    if (createdBy != null) 'created_by': createdBy,
  };
}

/// `public.safe_zone_states` — the last computed inside/outside answer, keyed by
/// `(zone_id, device_id)`.
final class SafeZoneState {
  const SafeZoneState({
    required this.zoneId,
    required this.deviceId,
    required this.inside,
    required this.updatedAt,
  });

  factory SafeZoneState.fromRow(Map<String, Object?> row) => SafeZoneState(
    zoneId: asText(row['zone_id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    inside: asBool(row['inside']) ?? false,
    updatedAt: asDate(row['updated_at']) ?? DateTime.utc(1970),
  );

  final String zoneId;
  final String deviceId;
  final bool inside;
  final DateTime updatedAt;

  Map<String, Object?> toRow() => {
    'zone_id': zoneId,
    'device_id': deviceId,
    'inside': inside,
    'updated_at': toJsonDate(updatedAt),
  };
}

/// `public.safety_alerts` — what the parent is notified about.
final class SafetyAlert {
  const SafetyAlert({
    required this.id,
    required this.familyId,
    required this.deviceId,
    required this.message,
    required this.payload,
    required this.createdAt,
    this.type,
    this.severity,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  factory SafetyAlert.fromRow(Map<String, Object?> row) => SafetyAlert(
    id: asText(row['id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    type: asText(row['type']),
    severity: asText(row['severity']),
    message: asText(row['message']) ?? '',
    payload: asMap(row['payload']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    acknowledgedAt: asDate(row['acknowledged_at']),
    acknowledgedBy: asText(row['acknowledged_by']),
  );

  final String id;
  final String familyId;
  final String deviceId;
  final String? type;
  final String? severity;
  final String message;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  AlertType? get alertType => AlertType.fromWire(type);
  AlertSeverity? get alertSeverity => AlertSeverity.fromWire(severity);
  bool get isAcknowledged => acknowledgedAt != null;
}
