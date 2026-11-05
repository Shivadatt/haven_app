import 'package:haven_models/haven_models.dart' show asBool, asInt, asList, asText;

/// The category of time-based restriction.
enum PolicyScheduleType {
  bedtime('bedtime', 'Bedtime'),
  school('school', 'School Hours'),
  custom('custom', 'Custom');

  const PolicyScheduleType(this.wire, this.label);
  final String wire;
  final String label;

  static PolicyScheduleType fromWire(String? value) =>
      values.firstWhere((t) => t.wire == value, orElse: () => custom);
}

/// A recurring downtime or focus schedule for a child device.
final class PolicySchedule {
  const PolicySchedule({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.isActive = true,
  });

  factory PolicySchedule.fromJson(Map<String, Object?> json) => PolicySchedule(
    id: asText(json['id']) ?? '',
    name: asText(json['name']) ?? '',
    type: PolicyScheduleType.fromWire(asText(json['type'])),
    startTime: asText(json['start_time']) ?? '21:00',
    endTime: asText(json['end_time']) ?? '07:00',
    days: asList(json['days']).isEmpty
        ? const [1, 2, 3, 4, 5, 6, 7]
        : asList(json['days']).map((d) => asInt(d) ?? 1).toList(),
    isActive: asBool(json['is_active']) ?? true,
  );

  final String id;
  final String name;
  final PolicyScheduleType type;
  final String startTime;
  final String endTime;
  final List<int> days;
  final bool isActive;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'type': type.wire,
    'start_time': startTime,
    'end_time': endTime,
    'days': days,
    'is_active': isActive,
  };

  PolicySchedule copyWith({
    String? id,
    String? name,
    PolicyScheduleType? type,
    String? startTime,
    String? endTime,
    List<int>? days,
    bool? isActive,
  }) => PolicySchedule(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    days: days ?? this.days,
    isActive: isActive ?? this.isActive,
  );

  static bool isValidTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  String get formattedDays {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    }
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = [...days]..sort();
    return sorted.where((d) => d >= 1 && d <= 7).map((d) => names[d]).join(', ');
  }

  static PolicySchedule defaultBedtime() => const PolicySchedule(
    id: 'sched-bedtime',
    name: 'Bedtime',
    type: PolicyScheduleType.bedtime,
    startTime: '21:00',
    endTime: '07:00',
    days: [1, 2, 3, 4, 5, 6, 7],
    isActive: true,
  );

  static PolicySchedule defaultSchool() => const PolicySchedule(
    id: 'sched-school',
    name: 'School Hours',
    type: PolicyScheduleType.school,
    startTime: '08:30',
    endTime: '15:00',
    days: [1, 2, 3, 4, 5],
    isActive: true,
  );
}
