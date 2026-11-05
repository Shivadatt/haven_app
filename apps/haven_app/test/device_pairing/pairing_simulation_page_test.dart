import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_app/features/device_pairing/controllers/pairing_simulation_controller.dart';
import 'package:haven_app/features/device_pairing/data/pairing_simulation_service.dart';
import 'package:haven_app/features/device_pairing/views/pages/pairing_simulation_page.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_models/haven_models.dart';

import '../family/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('PairingSimulationPage displays LOCAL PAIRING SIMULATION and full pairing flow', (
    tester,
  ) async {
    final writer = FakeRowWriter();
    final auth = FakeUserAuth(
      const AuthSession(
        userId: 'u_parent',
        email: 'parent@haven.test',
        accessToken: 'token',
      ),
    );

    final rows = FakeRowReader({
      TableName.familyMembers: [
        {
          'id': 'm1',
          'family_id': 'f1',
          'user_id': 'u_parent',
          'role': 'parent',
          'status': 'active',
          'created_at': '2026-01-01T00:00:00Z',
        },
      ],
    });

    final scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    final service = PairingSimulationService(scope: () => scope, writer: () => writer);

    final fakeFamily = FakeFamilyRepository(
      bundle: FamilyBundle(
        family: const Family(
          id: 'f1',
          name: 'Rivera',
          ownerId: 'u_parent',
          settings: {},
        ),
        parents: const [],
        children: [child('u_ivy', 'Ivy')],
      ),
    );

    final controller = PairingSimulationController(
      service: service,
      family: fakeFamily,
    );

    Get.put<PairingSimulationController>(controller);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: PairingSimulationPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clear label as LOCAL PAIRING SIMULATION
    expect(find.text('LOCAL PAIRING SIMULATION'), findsOneWidget);

    // Initial state: Step 1 shows Generate button
    expect(find.text('Generate 6-Digit Code'), findsOneWidget);

    // Click Generate 6-Digit Code
    await tester.tap(find.text('Generate 6-Digit Code'));
    await tester.pumpAndSettle();

    expect(controller.session.value, isNotNull);
    final code = controller.session.value!.code;
    expect(code.length, 6);

    // Step 2: enter code into text field
    final codeField = find.byType(TextField).first;
    await tester.enterText(codeField, code);
    await tester.pumpAndSettle();

    // Click Pair Device
    final pairButton = find.widgetWithText(HavenButton, 'Pair Device');
    await tester.ensureVisible(pairButton);
    await tester.tap(pairButton);
    await tester.pumpAndSettle();

    // Verify success state with device details
    expect(find.text('Pairing Successful!'), findsOneWidget);
    expect(find.text("Ivy's Phone (Simulated)"), findsOneWidget);
    expect(find.text('Ivy'), findsOneWidget);
    expect(find.text('ANDROID'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    // Click Pair Another Device (resets to initial state)
    await tester.tap(find.text('Pair Another Device'));
    await tester.pumpAndSettle();

    expect(find.text('Generate 6-Digit Code'), findsOneWidget);
    expect(find.text('Pairing Successful!'), findsNothing);
  });
}
