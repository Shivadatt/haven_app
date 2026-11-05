import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/settings/data/settings_models.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';

/// The settings screen's answers, driven by the test.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.theme = ThemeChoice.system,
    this.access = NotificationAccess.unavailable,
    NotificationPreferences? prefs,
    this.profile,
  }) : notifPrefs = prefs ?? NotificationPreferences.defaults;

  ThemeChoice theme;
  NotificationAccess access;
  NotificationPreferences notifPrefs;
  ParentProfileSummary? profile;

  HavenFailure? themeFailWith;
  HavenFailure? accessFailWith;
  HavenFailure? saveFailWith;

  Result<bool>? prompt;
  final List<String> calls = [];
  ThemeChoice? lastSaved;
  bool signedOut = false;
  bool demoReset = false;
  bool allReset = false;

  @override
  Future<Result<ThemeChoice>> themeChoice() async {
    calls.add('readTheme');
    final failure = themeFailWith;
    return failure == null ? Ok<ThemeChoice>(theme) : Err<ThemeChoice>(failure);
  }

  @override
  Future<Result<void>> saveThemeChoice(ThemeChoice choice) async {
    calls.add('saveTheme');
    lastSaved = choice;
    final failure = saveFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<NotificationAccess>> notificationAccess() async {
    calls.add('readAlerts');
    final failure = accessFailWith;
    return failure == null
        ? Ok<NotificationAccess>(access)
        : Err<NotificationAccess>(failure);
  }

  @override
  Future<Result<bool>> requestNotificationAccess() async {
    calls.add('askAlerts');
    return prompt ?? blocked('fake: no Firebase project in this build');
  }

  @override
  Future<Result<NotificationPreferences>> notificationPreferences() async {
    calls.add('notificationPreferences');
    return Ok(notifPrefs);
  }

  @override
  Future<Result<void>> saveNotificationPreferences(NotificationPreferences prefs) async {
    calls.add('saveNotificationPreferences');
    notifPrefs = prefs;
    return okVoid();
  }

  @override
  Future<Result<ParentProfileSummary?>> parentProfile() async {
    calls.add('parentProfile');
    return Ok(profile);
  }

  @override
  Future<Result<void>> updateParentName(String name) async {
    calls.add('updateParentName');
    if (profile != null) {
      profile = ParentProfileSummary(
        id: profile!.id,
        email: profile!.email,
        displayName: name,
        role: profile!.role,
      );
    }
    return okVoid();
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    signedOut = true;
    return okVoid();
  }

  @override
  Future<Result<void>> resetDemoData() async {
    calls.add('resetDemoData');
    demoReset = true;
    return okVoid();
  }

  @override
  Future<Result<void>> resetAllData() async {
    calls.add('resetAllData');
    allReset = true;
    return okVoid();
  }
}
