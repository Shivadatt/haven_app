import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/policies/controllers/policies_controller.dart';
import 'package:haven_app/features/policies/data/policies_models.dart';
import 'package:haven_app/features/policies/data/policies_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('PoliciesController', () {
    test('loads on open and holds what the read gave', () async {
      final FakePoliciesRepository repo = FakePoliciesRepository(
        board: policyBoard(lines: [policyLine()]),
      );
      final PoliciesController controller = PoliciesController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.loadCount, 1);
      expect(repo.lastDeviceId, isNull);
      expect(controller.isLoading.value, isFalse);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(1));
    });

    test(
      'a refused read is kept as a refusal, not shown as no versions',
      () async {
        final PoliciesController controller = PoliciesController(
          repository: FakePoliciesRepository(),
        );
        controller.onInit();
        await pumpEventQueue();

        expect(controller.board.value!.failureOrNull, isA<BlockedFailure>());
        expect(controller.isLoading.value, isFalse);
      },
    );

    test('a device id from the route narrows every read it makes', () async {
      final FakePoliciesRepository repo = FakePoliciesRepository(
        board: policyBoard(deviceId: 'd1'),
      );
      final PoliciesController controller = PoliciesController(
        repository: repo,
        deviceId: 'd1',
      );
      controller.onInit();
      await pumpEventQueue();
      await controller.refresh();

      expect(repo.lastDeviceId, 'd1');
      expect(repo.loadCount, 2);
    });

    test('both refusals reach the page through the board', () async {
      final PoliciesController controller = PoliciesController(
        repository: FakePoliciesRepository(
          board: policyBoard(lines: [policyLine()]),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      final PolicyBoard board = controller.board.value!.valueOrNull!;
      expect(board.writeGap.missing, HavenPoliciesRepository.writeMissing);
      expect(
        board.ruleShapeGap.missing,
        HavenPoliciesRepository.ruleShapeMissing,
      );
    });

    test('a network failure is not filed as a specification gap', () async {
      final PoliciesController controller = PoliciesController(
        repository: FakePoliciesRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test('a read that has not answered leaves the page in its busy state', () {
      final PoliciesController controller = PoliciesController(
        repository: FakePoliciesRepository(),
      );
      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('no family replaces the stack with setup', () async {
      final List<(String, String, Object?)> moved = [];
      final PoliciesController controller = PoliciesController(
        repository: FakePoliciesRepository(noFamily: true),
        replace: (String route, Object? arg) =>
            moved.add(('replace', route, arg)),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.valueOrNull, isNull);
      controller.goToSetup();
      expect(moved, [('replace', AppRoutes.onboarding, null)]);
    });

    test('the read answers even when no version was ever written', () async {
      final PoliciesController controller = PoliciesController(
        repository: FakePoliciesRepository(board: policyBoard()),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.isOk, isTrue);
      expect(controller.board.value!.valueOrNull!.hasLines, isFalse);
    });
  });
}
