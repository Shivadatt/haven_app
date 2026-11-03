import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';

import '../support/backend_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakePreferencesStore prefs;
  late FakePushTransport push;
  late bool messaging;
  late HavenSettingsRepository subject;

  setUp(() {
    prefs = FakePreferencesStore();
    push = FakePushTransport();
    messaging = false;
    subject = HavenSettingsRepository(
      prefs: () => prefs,
      push: () => push,
      messagingConfigured: () => messaging,
    );
  });

  group('theme', () {
    test('a phone with no stored choice matches itself', () async {
      final result = await subject.themeChoice();

      expect(result.valueOrNull, ThemeChoice.system);
      expect(prefs.readKeys, [PreferenceKey.themeMode]);
    });

    test('a stored choice is read back', () async {
      prefs.stored[PreferenceKey.themeMode] = 'dark';

      expect((await subject.themeChoice()).valueOrNull, ThemeChoice.dark);
    });

    test(
      'an unrecognised value falls back, rather than inventing a rule',
      () async {
        prefs.stored[PreferenceKey.themeMode] = 'sepia';

        expect((await subject.themeChoice()).valueOrNull, ThemeChoice.system);
      },
    );

    test('saving writes the wire value and reads it back', () async {
      expect(
        (await subject.saveThemeChoice(ThemeChoice.light)).failureOrNull,
        isNull,
      );
      expect(prefs.stored[PreferenceKey.themeMode], 'light');
      expect((await subject.themeChoice()).valueOrNull, ThemeChoice.light);
    });

    test(
      'a phone that refuses the write says the setting may not last',
      () async {
        prefs = FakePreferencesStore(acceptsWrites: false);
        final failure = (await subject.saveThemeChoice(
          ThemeChoice.dark,
        )).failureOrNull;

        expect(failure, isA<StorageFailure>());
        expect(failure!.message, contains('after a restart'));
      },
    );

    test('each choice maps to exactly one Flutter mode', () {
      expect(ThemeChoice.values.map((c) => c.mode).toList(), [
        ThemeMode.system,
        ThemeMode.light,
        ThemeMode.dark,
      ]);
    });
  });

  group('notifications', () {
    test('a build with no push backend is not reported as refused', () async {
      messaging = false;
      final result = await subject.notificationAccess();

      expect(result.valueOrNull, NotificationAccess.unavailable);
      expect(push.grantedReads, 0);
    });

    test('a configured build reports what the phone says', () async {
      messaging = true;
      push.isGranted = true;
      expect(
        (await subject.notificationAccess()).valueOrNull,
        NotificationAccess.granted,
      );

      push.isGranted = false;
      expect(
        (await subject.notificationAccess()).valueOrNull,
        NotificationAccess.denied,
      );
    });

    test(
      'asking for permission is blocked when there is nothing to register',
      () async {
        final failure =
            (await subject.requestNotificationAccess()).failureOrNull;

        expect(failure, isA<BlockedFailure>());
        expect(push.requestCount, 0);
      },
    );

    test('the OS answer is passed through, either way', () async {
      messaging = true;
      push.promptAnswer = true;
      expect((await subject.requestNotificationAccess()).valueOrNull, isTrue);

      push.promptAnswer = false;
      expect((await subject.requestNotificationAccess()).valueOrNull, isFalse);
      expect(push.requestCount, 2);
    });
  });

  test(
    'a replaced seam is followed, so the post-install transport is used',
    () async {
      messaging = true;
      var transport = push;
      subject = HavenSettingsRepository(
        prefs: () => prefs,
        push: () => transport,
        messagingConfigured: () => messaging,
      );

      final installed = FakePushTransport(isGranted: true);
      transport = installed;

      expect(
        (await subject.notificationAccess()).valueOrNull,
        NotificationAccess.granted,
      );
      expect(installed.grantedReads, 1);
      expect(push.grantedReads, 0);
    },
  );
}
