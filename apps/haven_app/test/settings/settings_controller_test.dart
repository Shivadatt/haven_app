import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/settings/controllers/settings_controller.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';

import 'fakes.dart';

void main() {
  (SettingsController, List<ThemeMode>) build(
    FakeSettingsRepository repo, {
    NotificationAccess access = NotificationAccess.denied,
  }) {
    final applied = <ThemeMode>[];
    final subject = SettingsController(
      repository: repo,
      applyTheme: applied.add,
    );
    repo.access = access;
    return (subject, applied);
  }

  test('loading reads both settings without applying anything', () async {
    final repo = FakeSettingsRepository(theme: ThemeChoice.dark);
    final (subject, applied) = build(repo);

    await subject.load();

    expect(subject.theme.value, ThemeChoice.dark);
    expect(subject.notifications.value, NotificationAccess.denied);
    expect(subject.isLoading.value, isFalse);
    expect(applied, isEmpty);
  });

  test('choosing an appearance applies it and then stores it', () async {
    final repo = FakeSettingsRepository();
    final (subject, applied) = build(repo);
    await subject.load();

    await subject.chooseTheme(ThemeChoice.dark);

    expect(applied, [ThemeMode.dark]);
    expect(repo.lastSaved, ThemeChoice.dark);
    expect(subject.message.value, isNull);
  });

  test('re-choosing what is already set writes nothing', () async {
    final repo = FakeSettingsRepository(theme: ThemeChoice.light);
    final (subject, applied) = build(repo);
    await subject.load();

    await subject.chooseTheme(ThemeChoice.light);

    expect(applied, isEmpty);
    expect(repo.calls.contains('saveTheme'), isFalse);
  });

  test('a phone that will not keep the choice still gets the change, and is '
      'told it may not last', () async {
    final repo = FakeSettingsRepository()
      ..saveFailWith = const StorageFailure(
        'This phone could not keep the setting, so it may change back after a '
        'restart.',
      );
    final (subject, applied) = build(repo);
    await subject.load();

    await subject.chooseTheme(ThemeChoice.dark);

    expect(subject.theme.value, ThemeChoice.dark);
    expect(applied, [ThemeMode.dark]);
    expect(subject.message.value, contains('after a restart'));
  });

  test('allowing notifications is remembered for the screen', () async {
    final repo = FakeSettingsRepository()..prompt = const Ok<bool>(true);
    final (subject, _) = build(repo);
    await subject.load();

    await subject.askForNotifications();

    expect(subject.notifications.value, NotificationAccess.granted);
    expect(subject.canAskForNotifications, isFalse);
    expect(subject.message.value, isNull);
  });

  test('a phone that says no is reported as no', () async {
    final repo = FakeSettingsRepository()..prompt = const Ok<bool>(false);
    final (subject, _) = build(repo);
    await subject.load();

    await subject.askForNotifications();

    expect(subject.notifications.value, NotificationAccess.denied);
    expect(subject.message.value, contains('did not allow notifications'));
  });

  test('a blocked prompt keeps the technical reason for the page', () async {
    final repo = FakeSettingsRepository();
    final (subject, _) = build(repo);
    await subject.load();

    await subject.askForNotifications();

    expect(subject.notificationPrompt.value, isA<BlockedFailure>());
    expect(subject.message.value, isNotNull);
    expect(repo.calls, contains('askAlerts'));
  });

  test('a screen that cannot ask does not offer to', () async {
    final (subject, _) = build(
      FakeSettingsRepository(),
      access: NotificationAccess.unavailable,
    );
    await subject.load();

    expect(subject.canAskForNotifications, isFalse);
    await subject.askForNotifications();
    expect(subject.notificationPrompt.value, isNull);

    final granted = build(
      FakeSettingsRepository(),
      access: NotificationAccess.granted,
    ).$1;
    expect(granted.canAskForNotifications, isFalse);
  });

  test('a setting the backend cannot read is said out loud', () async {
    final repo = FakeSettingsRepository()
      ..themeFailWith = const StorageFailure('This phone refused to read.');
    final (subject, _) = build(repo);

    await subject.load();

    expect(subject.message.value, 'This phone refused to read.');
    expect(subject.isLoading.value, isFalse);
  });
}
