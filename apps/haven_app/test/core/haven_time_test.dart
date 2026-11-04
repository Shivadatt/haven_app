import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/utils/haven_time.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 11, 3, 12);

  String ago(Duration before) => havenTimeAgo(now.subtract(before), now: now);

  group('havenTimeAgo', () {
    test('a missing instant is never rounded into "just now"', () {
      expect(havenTimeAgo(null), 'No time recorded');
    });

    test('steps through the units a parent reads', () {
      expect(ago(const Duration(seconds: 40)), 'This minute');
      expect(ago(const Duration(minutes: 5)), '5 minutes ago');
      expect(ago(const Duration(hours: 3)), '3 hours ago');
      expect(ago(const Duration(days: 2)), '2 days ago');
      expect(ago(const Duration(days: 9)), '1 week ago');
      expect(ago(const Duration(days: 20)), '2 weeks ago');
      expect(ago(const Duration(days: 65)), '2 months ago');
      expect(ago(const Duration(days: 400)), '1 year ago');
    });

    test('a future instant says scheduled, not a negative age', () {
      expect(
        havenTimeAgo(now.add(const Duration(hours: 1)), now: now),
        'Scheduled',
      );
    });

    test('a stored UTC instant is compared in UTC', () {
      final DateTime local = DateTime.utc(2026, 11, 3, 10).toLocal();
      expect(havenTimeAgo(local, now: now), '2 hours ago');
    });
  });

  group('havenDay', () {
    test('is day/month/year, which is how the app says a date out loud', () {
      expect(havenDay(DateTime.utc(2026, 3, 7)), '7/3/2026');
    });

    test('has no invented day for a missing date', () {
      expect(havenDay(null), isNull);
    });
  });
}
