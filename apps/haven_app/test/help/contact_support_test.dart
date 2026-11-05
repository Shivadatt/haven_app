import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/help/controllers/support_controller.dart';
import 'package:haven_app/features/help/data/local_support_repository.dart';

void main() {
  late LocalTables tables;
  late LocalSupportRepository repo;
  late SupportController controller;

  setUp(() async {
    Get.reset();
    tables = LocalTables(InMemoryLocalStore());
    await tables.open();
    Get.put<LocalTables>(tables);
    repo = LocalSupportRepository(tables: tables);
    controller = SupportController(repository: repo);
  });

  tearDown(Get.reset);

  test('validates subject and description requirements', () async {
    controller.subjectController.text = '';
    controller.descriptionController.text = '';
    expect(controller.validate(), isFalse);
    expect(controller.subjectError.value, isNotNull);
    expect(controller.descriptionError.value, isNotNull);

    // Short subject
    controller.subjectController.text = 'Hi';
    controller.descriptionController.text = 'Valid description with length';
    expect(controller.validate(), isFalse);

    // Valid inputs
    controller.subjectController.text = 'Valid Subject Here';
    controller.descriptionController.text = 'This is a detailed issue description';
    expect(controller.validate(), isTrue);
    expect(controller.subjectError.value, isNull);
    expect(controller.descriptionError.value, isNull);
  });

  test('submits ticket and saves into local tables audit log', () async {
    controller.subjectController.text = 'Pairing failed';
    controller.selectedCategory.value = 'Device Pairing & Sync';
    controller.descriptionController.text = 'Child phone shows timeout on pin';

    final success = await controller.submit();
    expect(success, isTrue);
    expect(controller.tickets, isNotEmpty);
    expect(controller.tickets.first.subject, 'Pairing failed');

    // Verify audit record in LocalTables
    final audit = await tables.rows(TableName.auditLogs);
    expect(
      audit.valueOrNull!.any((r) => r['action'] == 'support_ticket_created'),
      isTrue,
    );
  });

  test('saves and reloads support draft', () async {
    controller.subjectController.text = 'Draft Subject';
    controller.descriptionController.text = 'Work in progress notes...';

    await controller.saveDraft();

    // Reset controller and reload from repo
    final fresh = SupportController(repository: repo);
    await fresh.load();
    expect(fresh.subjectController.text, 'Draft Subject');
    expect(fresh.descriptionController.text, 'Work in progress notes...');
  });
}
