import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/approvals/controllers/app_approvals_controller.dart';
import 'package:haven_app/features/approvals/data/approval_models.dart';
import 'package:haven_app/features/approvals/data/local_approvals_repository.dart';

void main() {
  late LocalTables tables;
  late LocalApprovalsRepository repo;
  late AppApprovalsController controller;

  setUp(() async {
    Get.reset();
    tables = LocalTables(InMemoryLocalStore());
    await tables.open();
    Get.put<LocalTables>(tables);
    repo = LocalApprovalsRepository(tables: tables);
    controller = AppApprovalsController(repository: repo);
  });

  tearDown(Get.reset);

  test('loads initial app install requests including sample pending ones', () async {
    await controller.load();
    expect(controller.allRequests, isNotEmpty);
    expect(controller.pendingRequests, isNotEmpty);
    expect(controller.pendingRequests.first.status, ApprovalStatus.pending);
  });

  test('approves an app install request with a parent note', () async {
    await controller.load();
    final first = controller.pendingRequests.first;

    await controller.approve(first.id, note: 'Approved for homework');

    final updated = controller.allRequests.firstWhere((r) => r.id == first.id);
    expect(updated.status, ApprovalStatus.approved);
    expect(updated.parentNote, 'Approved for homework');
    expect(updated.respondedAt, isNotNull);

    // Verify audit log row inserted
    final audit = await tables.rows(TableName.auditLogs);
    expect(audit.isOk, isTrue);
    expect(
      audit.valueOrNull!.any((r) => r['action'] == 'app_install_approved'),
      isTrue,
    );
  });

  test('rejects an app install request with a reason note', () async {
    await controller.load();
    final first = controller.pendingRequests.first;

    await controller.reject(first.id, note: 'Too distracting');

    final updated = controller.allRequests.firstWhere((r) => r.id == first.id);
    expect(updated.status, ApprovalStatus.rejected);
    expect(updated.parentNote, 'Too distracting');

    final audit = await tables.rows(TableName.auditLogs);
    expect(
      audit.valueOrNull!.any((r) => r['action'] == 'app_install_rejected'),
      isTrue,
    );
  });

  test('generates sample app install request dynamically', () async {
    await controller.load();
    final initialCount = controller.allRequests.length;

    await controller.generateSample();
    expect(controller.allRequests.length, initialCount + 1);
    expect(controller.allRequests.first.status, ApprovalStatus.pending);
  });

  test('tabs filter displayed requests correctly', () async {
    await controller.load();

    controller.currentTab.value = 0;
    expect(controller.displayedRequests, controller.pendingRequests);

    controller.currentTab.value = 1;
    expect(controller.displayedRequests, controller.approvedRequests);

    controller.currentTab.value = 2;
    expect(controller.displayedRequests, controller.rejectedRequests);
  });
}
