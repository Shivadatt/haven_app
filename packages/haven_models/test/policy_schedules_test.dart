import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('PolicyScheduleType', () {
    test('fromWire maps correctly or falls back to custom', () {
      expect(PolicyScheduleType.fromWire('bedtime'), PolicyScheduleType.bedtime);
      expect(PolicyScheduleType.fromWire('school'), PolicyScheduleType.school);
      expect(PolicyScheduleType.fromWire('custom'), PolicyScheduleType.custom);
      expect(PolicyScheduleType.fromWire('unknown'), PolicyScheduleType.custom);
      expect(PolicyScheduleType.fromWire(null), PolicyScheduleType.custom);
    });

    test('label and wire values match specification', () {
      expect(PolicyScheduleType.bedtime.label, 'Bedtime');
      expect(PolicyScheduleType.school.label, 'School Hours');
      expect(PolicyScheduleType.custom.label, 'Custom');
    });
  });

  group('PolicySchedule', () {
    test('isOvernight detects midnight crossings accurately', () {
      final bedtime = PolicySchedule.defaultBedtime();
      expect(bedtime.isOvernight, isTrue);

      final school = PolicySchedule.defaultSchool();
      expect(school.isOvernight, isFalse);
    });

    test('formattedTimes appends next-day label when overnight', () {
      final bedtime = PolicySchedule.defaultBedtime();
      expect(bedtime.formattedTimes, '21:00 - 07:00 (Next day)');

      final school = PolicySchedule.defaultSchool();
      expect(school.formattedTimes, '08:30 - 15:00');
    });

    test('formattedDays formats special sets and custom days', () {
      final everyday = PolicySchedule.defaultBedtime();
      expect(everyday.formattedDays, 'Every day');

      final weekdays = PolicySchedule.defaultSchool();
      expect(weekdays.formattedDays, 'Weekdays');

      const weekends = PolicySchedule(
        id: 'w',
        name: 'Weekend',
        type: PolicyScheduleType.custom,
        startTime: '10:00',
        endTime: '12:00',
        days: [6, 7],
      );
      expect(weekends.formattedDays, 'Weekends');

      const customDays = PolicySchedule(
        id: 'c',
        name: 'Mon Wed',
        type: PolicyScheduleType.custom,
        startTime: '10:00',
        endTime: '12:00',
        days: [3, 1],
      );
      expect(customDays.formattedDays, 'Mon, Wed');
    });

    test('isValidTime validates HH:mm correctly', () {
      expect(PolicySchedule.isValidTime('00:00'), isTrue);
      expect(PolicySchedule.isValidTime('23:59'), isTrue);
      expect(PolicySchedule.isValidTime('24:00'), isFalse);
      expect(PolicySchedule.isValidTime('12:60'), isFalse);
      expect(PolicySchedule.isValidTime('bad'), isFalse);
      expect(PolicySchedule.isValidTime('12:3'), isTrue);
    });

    test('toJson and fromJson round-trip accurately', () {
      final original = PolicySchedule.defaultBedtime().copyWith(
        category: 'sleep',
        allowedApps: ['com.android.calculator2'],
      );
      final json = original.toJson();
      final parsed = PolicySchedule.fromJson(json);

      expect(parsed.id, original.id);
      expect(parsed.name, original.name);
      expect(parsed.type, original.type);
      expect(parsed.startTime, original.startTime);
      expect(parsed.endTime, original.endTime);
      expect(parsed.days, original.days);
      expect(parsed.isActive, original.isActive);
      expect(parsed.allowedApps, original.allowedApps);
      expect(parsed.category, original.category);
    });
  });
}
