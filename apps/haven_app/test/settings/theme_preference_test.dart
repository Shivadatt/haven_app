import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';
import 'package:haven_app/features/settings/services/theme_preference.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  test('the stored choice is applied before the parent asks for it', () async {
    final applied = <ThemeMode>[];
    final subject = ThemePreference(
      repository: FakeSettingsRepository(theme: ThemeChoice.dark),
      applyTheme: applied.add,
    );

    await subject.restore();

    expect(applied, [ThemeMode.dark]);
    expect(subject.restored, ThemeChoice.dark);
  });

  test('a first run leaves the phone alone', () async {
    final applied = <ThemeMode>[];
    final subject = ThemePreference(
      repository: FakeSettingsRepository(),
      applyTheme: applied.add,
    );

    await subject.restore();

    expect(applied, [ThemeMode.system]);
    expect(subject.restored, ThemeChoice.system);
  });

  test(
    'a setting that cannot be read still produces a valid appearance',
    () async {
      final applied = <ThemeMode>[];
      final subject = ThemePreference(
        repository: FakeSettingsRepository()
          ..themeFailWith = const StorageFailure('This phone refused to read.'),
        applyTheme: applied.add,
      );

      await subject.restore();

      expect(applied, [ThemeMode.system]);
    },
  );
}
