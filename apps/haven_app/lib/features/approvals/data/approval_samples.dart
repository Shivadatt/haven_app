import 'package:haven_api/haven_api.dart';
import 'approval_models.dart';

final class ApprovalSamples {
  static List<AppInstallRequest> defaultAppRequests({String? familyId}) => [
        AppInstallRequest(
          id: 'req_app_1',
          familyId: familyId ?? 'fam_default',
          childUserId: 'child_1',
          childName: 'Emma',
          appName: 'Roblox',
          packageName: 'com.roblox.client',
          category: 'Games',
          requestedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        AppInstallRequest(
          id: 'req_app_2',
          familyId: familyId ?? 'fam_default',
          childUserId: 'child_2',
          childName: 'Lucas',
          appName: 'Duolingo',
          packageName: 'com.duolingo',
          category: 'Education',
          requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: ApprovalStatus.approved,
          parentNote: 'Great for learning French!',
          respondedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AppInstallRequest(
          id: 'req_app_3',
          familyId: familyId ?? 'fam_default',
          childUserId: 'child_1',
          childName: 'Emma',
          appName: 'TikTok',
          packageName: 'com.zhiliaoapp.musically',
          category: 'Social',
          requestedAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ApprovalStatus.rejected,
          parentNote: 'Age limit not met yet.',
          respondedAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
      ];

  static List<ScreenTimeExtensionRequest> defaultExtensionRequests({
    String? familyId,
  }) =>
      [
        ScreenTimeExtensionRequest(
          id: 'req_ext_1',
          familyId: familyId ?? 'fam_default',
          childUserId: 'child_1',
          childName: 'Emma',
          currentLimitMinutes: 120,
          requestedMinutes: 30,
          reason: 'Finishing art project research',
          requestedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        ScreenTimeExtensionRequest(
          id: 'req_ext_2',
          familyId: familyId ?? 'fam_default',
          childUserId: 'child_2',
          childName: 'Lucas',
          currentLimitMinutes: 90,
          requestedMinutes: 15,
          reason: 'Quick call with grandma',
          requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: ApprovalStatus.approved,
          grantedMinutes: 15,
          parentNote: 'Sure, tell her hello!',
          respondedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
        ),
      ];

  static AppInstallRequest createRandomAppRequest({String? familyId}) {
    final apps = [
      ('Minecraft', 'com.mojang.minecraftpe', 'Games'),
      ('Spotify Kids', 'com.spotify.kids', 'Music'),
      ('Khan Academy', 'org.khanacademy.android', 'Education'),
      ('Subway Surfers', 'com.kiloo.subwaysurf', 'Games'),
    ];
    final pick = apps[DateTime.now().millisecond % apps.length];
    return AppInstallRequest(
      id: LocalIds.create(),
      familyId: familyId ?? 'fam_default',
      childUserId: 'child_1',
      childName: 'Emma',
      appName: pick.$1,
      packageName: pick.$2,
      category: pick.$3,
      requestedAt: DateTime.now(),
    );
  }

  static ScreenTimeExtensionRequest createRandomExtensionRequest({
    String? familyId,
  }) {
    final durations = [15, 30, 45, 60];
    final minutes = durations[DateTime.now().millisecond % durations.length];
    return ScreenTimeExtensionRequest(
      id: LocalIds.create(),
      familyId: familyId ?? 'fam_default',
      childUserId: 'child_1',
      childName: 'Emma',
      currentLimitMinutes: 120,
      requestedMinutes: minutes,
      reason: 'Need extra time for school homework',
      requestedAt: DateTime.now(),
    );
  }
}
