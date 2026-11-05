import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/approvals/controllers/extension_requests_controller.dart';
import 'package:haven_app/features/approvals/data/approval_models.dart';
import 'package:haven_app/features/approvals/data/local_approvals_repository.dart';

void main() {
  late LocalTables tables;
  late LocalApprovalsRepository repo;
  late ExtensionRequestsController controller;

  setUp(() async {
    Get.reset();
    tables = LocalTables(InMemoryLocalStore());
    await tables.open();
    Get.put<LocalTables>(tables);
    repo = LocalApprovalsRepository(tables: tables);
    controller = ExtensionRequestsController(repository: repo);
  });

  tearDown(Get.reset);

  test('loads extension requests correctly', () async {
    await controller.load();
    expect(controller.allRequests, isNotEmpty);
    expect(controller.pendingRequests, isNotEmpty);
    expect(controller.historyRequests, isNotEmpty);
  });

  test('approves extension request with granted minutes and parent note', () async {
    await controller.load();
    final first = controller.pendingRequests.first;

    await controller.approve(
      first.id,
      grantedMinutes: 45,
      note: 'Finish your project',
    );

    final updated = controller.allRequests.firstWhere((r) => r.id == first.id);
    expect(updated.status, ApprovalStatus.approved);
    expect(updated.grantedMinutes, 45);
    expect(updated.parentNote, 'Finish your project');
    expect(updated.respondedAt, isNotNull);

    // Verify audit logs
    final audit = await tables.rows(TableName.auditLogs);
    expect(
      audit.valueOrNull!.any((r) => r['action'] == 'extension_granted'),
      isTrue,
    );
  });

  test('rejects extension request with note', () async {
    await controller.load();
    final first = controller.pendingRequests.first;

    await controller.reject(first.id, note: 'Bedtime already passed');

    final updated = controller.allRequests.firstWhere((r) => r.id == first.id);
    expect(updated.status, ApprovalStatus.rejected);
    expect(updated.parentNote, 'Bedtime already passed');

    final audit = await tables.rows(TableName.auditLogs);
    expect(
      audit.valueOrNull!.any((r) => r['action'] == 'extension_rejected'),
      isTrue,
    );
  });

  test('generates sample extension request dynamically', () async {
    await controller.load();
    final before = controller.allRequests.length;

    await controller.generateSample();
    expect(controller.allRequests.length, before + 1);
    expect(controller.allRequests.first.status, ApprovalStatus.pending);
  });
}
