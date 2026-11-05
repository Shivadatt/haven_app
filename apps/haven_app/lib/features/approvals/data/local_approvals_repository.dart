import 'dart:convert';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'approval_models.dart';
import 'approval_samples.dart';
import 'approvals_repository.dart';

final class LocalApprovalsRepository implements ApprovalsRepository {
  LocalApprovalsRepository({LocalTables? tables}) : _tables = tables;

  final LocalTables? _tables;
  LocalTables? get _activeTables =>
      _tables ?? (Get.isRegistered<LocalTables>() ? Get.find<LocalTables>() : null);

  final List<AppInstallRequest> _appRequests = [];
  final List<ScreenTimeExtensionRequest> _extensionRequests = [];
  bool _initialized = false;

  void _ensureInit(String? familyId) {
    if (_initialized) return;
    _appRequests.addAll(ApprovalSamples.defaultAppRequests(familyId: familyId));
    _extensionRequests.addAll(
      ApprovalSamples.defaultExtensionRequests(familyId: familyId),
    );
    _initialized = true;
  }

  @override
  Future<Result<List<AppInstallRequest>>> loadAppRequests({String? familyId}) async {
    _ensureInit(familyId);
    return Ok([..._appRequests]);
  }

  @override
  Future<Result<void>> respondAppRequest(
    String requestId, {
    required bool approve,
    String? note,
  }) async {
    _ensureInit(null);
    final idx = _appRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) {
      return const Err(ValidationFailure('Approval request not found'));
    }
    final req = _appRequests[idx];
    final updated = req.copyWith(
      status: approve ? ApprovalStatus.approved : ApprovalStatus.rejected,
      parentNote: note,
      respondedAt: DateTime.now(),
    );
    _appRequests[idx] = updated;

    await _recordAudit(
      action: approve ? 'app_install_approved' : 'app_install_rejected',
      familyId: req.familyId,
      childUserId: req.childUserId,
      payload: updated.toJson(),
    );

    return okVoid();
  }

  @override
  Future<Result<void>> generateSampleAppRequest({String? familyId}) async {
    _ensureInit(familyId);
    final req = ApprovalSamples.createRandomAppRequest(familyId: familyId);
    _appRequests.insert(0, req);
    await _recordAudit(
      action: 'app_install_requested',
      familyId: req.familyId,
      childUserId: req.childUserId,
      payload: req.toJson(),
    );
    return okVoid();
  }

  @override
  Future<Result<List<ScreenTimeExtensionRequest>>> loadExtensionRequests({
    String? familyId,
  }) async {
    _ensureInit(familyId);
    return Ok([..._extensionRequests]);
  }

  @override
  Future<Result<void>> respondExtensionRequest(
    String requestId, {
    required bool approve,
    int? grantedMinutes,
    String? note,
  }) async {
    _ensureInit(null);
    final idx = _extensionRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) {
      return const Err(ValidationFailure('Extension request not found'));
    }
    final req = _extensionRequests[idx];
    final updated = req.copyWith(
      status: approve ? ApprovalStatus.approved : ApprovalStatus.rejected,
      grantedMinutes: approve ? (grantedMinutes ?? req.requestedMinutes) : 0,
      parentNote: note,
      respondedAt: DateTime.now(),
    );
    _extensionRequests[idx] = updated;

    await _recordAudit(
      action: approve ? 'extension_granted' : 'extension_rejected',
      familyId: req.familyId,
      childUserId: req.childUserId,
      payload: updated.toJson(),
    );

    return okVoid();
  }

  @override
  Future<Result<void>> generateSampleExtensionRequest({String? familyId}) async {
    _ensureInit(familyId);
    final req = ApprovalSamples.createRandomExtensionRequest(familyId: familyId);
    _extensionRequests.insert(0, req);
    await _recordAudit(
      action: 'extension_requested',
      familyId: req.familyId,
      childUserId: req.childUserId,
      payload: req.toJson(),
    );
    return okVoid();
  }

  Future<void> _recordAudit({
    required String action,
    required String familyId,
    required String childUserId,
    required Map<String, Object?> payload,
  }) async {
    final tables = _activeTables;
    if (tables == null) return;
    await tables.insert(TableName.auditLogs, <String, Object?>{
      'id': LocalIds.create(),
      'family_id': familyId,
      'device_id': childUserId,
      'action': action,
      'detail': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
