import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';

/// The settings screen's answers, driven by the test.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.theme = ThemeChoice.system,
    this.access = NotificationAccess.unavailable,
  });

  ThemeChoice theme;
  NotificationAccess access;

  HavenFailure? themeFailWith;
  HavenFailure? accessFailWith;
  HavenFailure? saveFailWith;

  /// What the permission prompt resolves to. Null means the ability is not
  /// there at all, which a real repository reports as `blocked(...)`.
  Result<bool>? prompt;

  final List<String> calls = [];
  ThemeChoice? lastSaved;

  @override
  Future<Result<ThemeChoice>> themeChoice() async {
    calls.add('readTheme');
    final HavenFailure? failure = themeFailWith;
    return failure == null ? Ok<ThemeChoice>(theme) : Err<ThemeChoice>(failure);
  }

  @override
  Future<Result<void>> saveThemeChoice(ThemeChoice choice) async {
    calls.add('saveTheme');
    lastSaved = choice;
    final HavenFailure? failure = saveFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<NotificationAccess>> notificationAccess() async {
    calls.add('readAlerts');
    final HavenFailure? failure = accessFailWith;
    return failure == null
        ? Ok<NotificationAccess>(access)
        : Err<NotificationAccess>(failure);
  }

  @override
  Future<Result<bool>> requestNotificationAccess() async {
    calls.add('askAlerts');
    return prompt ?? blocked('fake: no Firebase project in this build');
  }
}
