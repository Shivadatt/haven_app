import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('PolicyEvaluationContext', () {
    final fixedTime = DateTime.utc(2026, 11, 18, 12, 0);
    final defaultConfig = PolicyConfig.defaults();

    test(
      'State A: no override falls back to config.dailyScreenTimeMinutes',
      () {
        final context = PolicyEvaluationContext(
          config: defaultConfig,
          evaluationTime: fixedTime,
        );

        expect(context.hasDailyLimitOverride, isFalse);
        expect(context.dailyLimitMinutesOverride, isNull);
        expect(context.effectiveDailyLimit, 120);
      },
    );

    test('State B: explicit null override evaluates to unlimited quota', () {
      final context = PolicyEvaluationContext.withUnlimitedQuota(
        config: defaultConfig,
        evaluationTime: fixedTime,
      );

      expect(context.hasDailyLimitOverride, isTrue);
      expect(context.dailyLimitMinutesOverride, isNull);
      expect(context.effectiveDailyLimit, isNull);
    });

    test('State C: explicit zero override evaluates to 0 minutes', () {
      final context = PolicyEvaluationContext.withQuotaOverride(
        config: defaultConfig,
        evaluationTime: fixedTime,
        minutes: 0,
      );

      expect(context.hasDailyLimitOverride, isTrue);
      expect(context.dailyLimitMinutesOverride, 0);
      expect(context.effectiveDailyLimit, 0);
    });

    test('State D: positive override replaces config quota', () {
      final context = PolicyEvaluationContext.withQuotaOverride(
        config: defaultConfig,
        evaluationTime: fixedTime,
        minutes: 60,
      );

      expect(context.hasDailyLimitOverride, isTrue);
      expect(context.dailyLimitMinutesOverride, 60);
      expect(context.effectiveDailyLimit, 60);
    });

    test('State E: negative override in constructor throws ArgumentError', () {
      expect(
        () => PolicyEvaluationContext(
          config: defaultConfig,
          evaluationTime: fixedTime,
          hasDailyLimitOverride: true,
          dailyLimitMinutesOverride: -1,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'dailyLimitMinutesOverride')
              .having(
                (e) => e.message,
                'message',
                contains('cannot be negative'),
              ),
        ),
      );
    });

    test('State E: negative override in factory throws ArgumentError', () {
      expect(
        () => PolicyEvaluationContext.withQuotaOverride(
          config: defaultConfig,
          evaluationTime: fixedTime,
          minutes: -10,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'dailyLimitMinutesOverride')
              .having(
                (e) => e.message,
                'message',
                contains('cannot be negative'),
              ),
        ),
      );
    });

    test('Omitted override differs from explicit null override', () {
      final omitted = PolicyEvaluationContext(
        config: defaultConfig,
        evaluationTime: fixedTime,
      );
      final explicitNull = PolicyEvaluationContext.withUnlimitedQuota(
        config: defaultConfig,
        evaluationTime: fixedTime,
      );

      expect(omitted.dailyLimitMinutesOverride, isNull);
      expect(explicitNull.dailyLimitMinutesOverride, isNull);
      expect(omitted.hasDailyLimitOverride, isFalse);
      expect(explicitNull.hasDailyLimitOverride, isTrue);
      expect(omitted.effectiveDailyLimit, 120);
      expect(explicitNull.effectiveDailyLimit, isNull);
    });

    test(
      'Decision 2.13: positive quota above 1440 is accepted without ceiling',
      () {
        final context = PolicyEvaluationContext.withQuotaOverride(
          config: defaultConfig,
          evaluationTime: fixedTime,
          minutes: 1500,
        );

        expect(context.effectiveDailyLimit, 1500);
      },
    );

    test(
      'Decision 2.12: all five approved emergency package IDs return true',
      () {
        const approvedPackages = [
          'com.android.phone',
          'com.google.android.dialer',
          'com.samsung.android.dialer',
          'com.android.emergency',
          'com.google.android.apps.safetyhub',
        ];

        for (final pkg in approvedPackages) {
          expect(
            PolicyEvaluationContext.isEmergencyPackage(pkg),
            isTrue,
            reason: '$pkg must be classified as emergency package',
          );
        }
      },
    );

    test('Decision 2.12: unknown and excluded packages return false', () {
      const nonEmergencyPackages = [
        'com.android.server.telecom',
        'com.zhiliaoapp.musically',
        'com.instagram.android',
        'com.google.android.youtube',
        'com.example.customdialer',
        '',
      ];

      for (final pkg in nonEmergencyPackages) {
        expect(
          PolicyEvaluationContext.isEmergencyPackage(pkg),
          isFalse,
          reason: '$pkg must not be emergency exempt',
        );
      }
    });

    test(
      'Existing PolicyConfig serialization is unchanged by evaluation context',
      () {
        final json = defaultConfig.toJson();
        final roundtrip = PolicyConfig.fromJson(json);

        expect(roundtrip.dailyScreenTimeMinutes, 120);
        expect(
          roundtrip.dailyScreenTimeMinutes,
          defaultConfig.dailyScreenTimeMinutes,
        );
      },
    );
  });
}
