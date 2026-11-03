import 'package:haven_core/haven_core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Ok exposes the value and no failure', () {
      const Result<int> r = Ok(7);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 7);
      expect(r.failureOrNull, isNull);
    });

    test('Err exposes the failure and no value', () {
      const Result<int> r = Err(AuthFailure('Signed out', signedOut: true));
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, isA<AuthFailure>());
      expect(r.failureOrNull!.isUnauthorized, isTrue);
    });

    test('map routes to the matching branch', () {
      expect(const Ok<int>(2).map((v) => v * 10, (_) => -1), 20);
      expect(
        const Err<int>(
          ValidationFailure('bad'),
        ).map((_) => 0, (f) => f.message),
        'bad',
      );
    });
  });

  group('blocked', () {
    test('carries the missing specification and never a value', () {
      final r = blocked<String>('A13 unsigned');
      expect(r, isA<Err<String>>());
      expect(isBlocked(r), isTrue);
      final f = r.failureOrNull!;
      expect(f, isA<BlockedFailure>());
      expect((f as BlockedFailure).missing, 'A13 unsigned');
      expect(f.detail, contains('BLOCKED'));
    });

    test('isBlocked is false for a real failure', () {
      expect(isBlocked(const Err<void>(NetworkFailure('offline'))), isFalse);
    });
  });

  group('validation', () {
    test('email accepts shape and rejects the obvious misses', () {
      expect(validateEmail('a@b.co'), isNull);
      expect(validateEmail(null), isNotNull);
      expect(validateEmail('a@b'), isNotNull);
      expect(validateEmail('no-atsign.example'), isNotNull);
    });

    test('display name has a bound', () {
      expect(validateDisplayName('Priya'), isNull);
      expect(validateDisplayName('  '), isNotNull);
      expect(validateDisplayName('x'), isNotNull);
      expect(validateDisplayName('y' * 61), isNotNull);
      expect(validateDisplayName('y' * 60), isNull);
    });

    test('safe-zone radius is positive and metre-scaled', () {
      expect(validateRadiusM('150'), isNull);
      expect(validateRadiusM('0'), isNotNull);
      expect(validateRadiusM('-5'), isNotNull);
      expect(validateRadiusM('abc'), isNotNull);
      expect(validateRadiusM('200000'), isNotNull);
    });

    test('coordinates stay in range', () {
      expect(validateLatitude('47.2'), isNull);
      expect(validateLatitude('91'), isNotNull);
      expect(validateLongitude('-181'), isNotNull);
    });

    test('uuid check is exact', () {
      expect(isUuid('8f14e45f-ceea-467a-a9d4-1c2f5a6b7c8d'), isTrue);
      expect(isUuid('8f14e45f-ceea-467a-a9d4-1c2f5a6b7c8'), isFalse);
      expect(isUuid(null), isFalse);
    });
  });

  group('format', () {
    test('spans drop the smaller unit once hours appear', () {
      expect(formatSpan(const Duration(seconds: 45)), '45s');
      expect(formatSpan(const Duration(minutes: 12)), '12m');
      expect(formatSpan(const Duration(hours: 2, minutes: 14)), '2h 14m');
      expect(formatSpan(const Duration(hours: 3)), '3h');
      expect(formatSpanFromMs(null), 'no data');
    });

    test('relative wording uses an injected clock', () {
      final clock = FixedClock(DateTime.utc(2026, 11, 3, 12));
      expect(
        formatRelative(DateTime.utc(2026, 11, 3, 11, 48), clock: clock),
        '12 min ago',
      );
      expect(
        formatRelative(DateTime.utc(2026, 11, 3, 9), clock: clock),
        '3 h ago',
      );
      expect(formatRelative(null, clock: clock), 'unknown');
      expect(
        formatRelative(DateTime.utc(2026, 11, 4), clock: clock),
        'scheduled',
      );
    });

    test('distance never claims sub-metre precision', () {
      expect(formatDistanceM(340), '340 m');
      expect(formatDistanceM(2500), '2.5 km');
    });

    test('haversine matches a known short baseline', () {
      final d = haversineMeters(
        lat1: 47.0,
        lon1: 19.0,
        lat2: 47.009,
        lon2: 19.0,
      );
      expect(d, closeTo(1000.75, 5));
    });
  });

  group('RetryPolicy', () {
    test('delays grow and stay capped', () {
      const p = RetryPolicy(
        attempts: 5,
        base: Duration(milliseconds: 100),
        ceiling: Duration(seconds: 1),
        seed: 1,
      );
      for (var attempt = 1; attempt <= 5; attempt++) {
        expect(p.delayFor(attempt).inMilliseconds, lessThanOrEqualTo(1250));
      }
      expect(
        p.delayFor(4).inMilliseconds,
        greaterThan(p.delayFor(1).inMilliseconds ~/ 2),
      );
    });

    test('succeeds after transient failures and stops at the limit', () async {
      var calls = 0;
      final p = RetryPolicy(attempts: 3, base: Duration.zero, seed: 2);
      final value = await p.run<int>(() async {
        calls++;
        if (calls < 3) throw const NetworkFailure('busy');
        return calls;
      }, retryOn: (e) => e is NetworkFailure);
      expect(value, 3);

      var exhausted = 0;
      await expectLater(
        p.run<int>(() async {
          exhausted++;
          throw const NetworkFailure('busy');
        }, retryOn: (e) => e is NetworkFailure),
        throwsA(isA<NetworkFailure>()),
      );
      expect(exhausted, 3);
    });

    test('does not retry a rejection', () async {
      var calls = 0;
      final p = RetryPolicy(attempts: 4, base: Duration.zero);
      await expectLater(
        p.run<int>(() async {
          calls++;
          throw const PermissionFailure('not yours');
        }, retryOn: (e) => e is NetworkFailure),
        throwsA(isA<PermissionFailure>()),
      );
      expect(calls, 1);
    });
  });

  group('Clock', () {
    test('FixedClock advances and answers isPast', () {
      final clock = FixedClock(DateTime.utc(2026));
      expect(clock.isPast(DateTime.utc(2025)), isTrue);
      expect(clock.isPast(null), isTrue);
      clock.advance(const Duration(days: 2));
      expect(clock.isPast(DateTime.utc(2026, 1, 3)), isTrue);
      expect(clock.now().toUtc(), DateTime.utc(2026, 1, 3));
      expect(clock.isPast(DateTime.utc(2026, 1, 3, 1)), isFalse);
    });
  });
}
