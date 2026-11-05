import 'package:haven_api/haven_api.dart';

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
        ApprovalStatus.pending => 'Pending',
        ApprovalStatus.approved => 'Approved',
        ApprovalStatus.rejected => 'Rejected',
      };
}

final class AppInstallRequest {
  const AppInstallRequest({
    required this.id,
    required this.familyId,
    required this.childUserId,
    required this.childName,
    required this.appName,
    required this.packageName,
    required this.category,
    required this.requestedAt,
    this.status = ApprovalStatus.pending,
    this.parentNote,
    this.respondedAt,
  });

  final String id;
  final String familyId;
  final String childUserId;
  final String childName;
  final String appName;
  final String packageName;
  final String category;
  final DateTime requestedAt;
  final ApprovalStatus status;
  final String? parentNote;
  final DateTime? respondedAt;

  AppInstallRequest copyWith({
    ApprovalStatus? status,
    String? parentNote,
    DateTime? respondedAt,
  }) =>
      AppInstallRequest(
        id: id,
        familyId: familyId,
        childUserId: childUserId,
        childName: childName,
        appName: appName,
        packageName: packageName,
        category: category,
        requestedAt: requestedAt,
        status: status ?? this.status,
        parentNote: parentNote ?? this.parentNote,
        respondedAt: respondedAt ?? this.respondedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'family_id': familyId,
        'child_user_id': childUserId,
        'child_name': childName,
        'app_name': appName,
        'package_name': packageName,
        'category': category,
        'requested_at': requestedAt.toIso8601String(),
        'status': status.name,
        'parent_note': parentNote,
        'responded_at': respondedAt?.toIso8601String(),
      };

  factory AppInstallRequest.fromJson(Map<String, Object?> json) =>
      AppInstallRequest(
        id: json['id'] as String? ?? LocalIds.create(),
        familyId: json['family_id'] as String? ?? 'demo_family',
        childUserId: json['child_user_id'] as String? ?? 'child_1',
        childName: json['child_name'] as String? ?? 'Child',
        appName: json['app_name'] as String? ?? 'Application',
        packageName: json['package_name'] as String? ?? 'com.example.app',
        category: json['category'] as String? ?? 'Games',
        requestedAt: DateTime.tryParse(json['requested_at'] as String? ?? '') ??
            DateTime.now(),
        status: ApprovalStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ApprovalStatus.pending,
        ),
        parentNote: json['parent_note'] as String?,
        respondedAt:
            DateTime.tryParse(json['responded_at'] as String? ?? ''),
      );
}

final class ScreenTimeExtensionRequest {
  const ScreenTimeExtensionRequest({
    required this.id,
    required this.familyId,
    required this.childUserId,
    required this.childName,
    required this.currentLimitMinutes,
    required this.requestedMinutes,
    required this.requestedAt,
    this.reason,
    this.status = ApprovalStatus.pending,
    this.grantedMinutes,
    this.parentNote,
    this.respondedAt,
  });

  final String id;
  final String familyId;
  final String childUserId;
  final String childName;
  final int currentLimitMinutes;
  final int requestedMinutes;
  final String? reason;
  final DateTime requestedAt;
  final ApprovalStatus status;
  final int? grantedMinutes;
  final String? parentNote;
  final DateTime? respondedAt;

  ScreenTimeExtensionRequest copyWith({
    ApprovalStatus? status,
    int? grantedMinutes,
    String? parentNote,
    DateTime? respondedAt,
  }) =>
      ScreenTimeExtensionRequest(
        id: id,
        familyId: familyId,
        childUserId: childUserId,
        childName: childName,
        currentLimitMinutes: currentLimitMinutes,
        requestedMinutes: requestedMinutes,
        reason: reason,
        requestedAt: requestedAt,
        status: status ?? this.status,
        grantedMinutes: grantedMinutes ?? this.grantedMinutes,
        parentNote: parentNote ?? this.parentNote,
        respondedAt: respondedAt ?? this.respondedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'family_id': familyId,
        'child_user_id': childUserId,
        'child_name': childName,
        'current_limit_minutes': currentLimitMinutes,
        'requested_minutes': requestedMinutes,
        'reason': reason,
        'requested_at': requestedAt.toIso8601String(),
        'status': status.name,
        'granted_minutes': grantedMinutes,
        'parent_note': parentNote,
        'responded_at': respondedAt?.toIso8601String(),
      };

  factory ScreenTimeExtensionRequest.fromJson(Map<String, Object?> json) =>
      ScreenTimeExtensionRequest(
        id: json['id'] as String? ?? LocalIds.create(),
        familyId: json['family_id'] as String? ?? 'demo_family',
        childUserId: json['child_user_id'] as String? ?? 'child_1',
        childName: json['child_name'] as String? ?? 'Child',
        currentLimitMinutes: json['current_limit_minutes'] as int? ?? 120,
        requestedMinutes: json['requested_minutes'] as int? ?? 30,
        reason: json['reason'] as String?,
        requestedAt: DateTime.tryParse(json['requested_at'] as String? ?? '') ??
            DateTime.now(),
        status: ApprovalStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ApprovalStatus.pending,
        ),
        grantedMinutes: json['granted_minutes'] as int?,
        parentNote: json['parent_note'] as String?,
        respondedAt:
            DateTime.tryParse(json['responded_at'] as String? ?? ''),
      );
}
