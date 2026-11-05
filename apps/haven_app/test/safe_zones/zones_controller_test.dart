import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/safe_zones/controllers/zones_controller.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('SafeZonesController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeSafeZonesRepository repo = FakeSafeZonesRepository(
        board: board(zones: [zone('z1')]),
      );
      final SafeZonesController controller = SafeZonesController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.loadCount, 1);
      expect(controller.isLoading.value, isFalse);
      expect(controller.board.value!.valueOrNull!.zones, hasLength(1));
    });

    test(
      'a refused read is kept as a refusal, not shown as an empty list',
      () async {
        final SafeZonesController controller = SafeZonesController(
          repository: FakeSafeZonesRepository(),
        );
        controller.onInit();
        await pumpEventQueue();

        final HavenFailure? failure = controller.board.value!.failureOrNull;
        expect(failure, isA<BlockedFailure>());
        expect(failure!.message, isNotEmpty);
        expect(
          (failure as BlockedFailure).missing,
          contains('no place read seeded'),
        );
      },
    );

    test('refresh reads again', () async {
      final FakeSafeZonesRepository repo = FakeSafeZonesRepository(
        board: board(),
      );
      final SafeZonesController controller = SafeZonesController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      await controller.reload();

      expect(repo.loadCount, 2);
    });

    test(
      'a first-run account answers null, which the page routes to setup',
      () async {
        final SafeZonesController controller = SafeZonesController(
          repository: FakeSafeZonesRepository(noFamily: true),
        );
        controller.onInit();
        await pumpEventQueue();

        expect(controller.board.value!.valueOrNull, isNull);
      },
    );

    test('editing a named place pushes the editor with that id', () async {
      final List<(String, String, Object?)> routes = [];
      final SafeZonesController controller = SafeZonesController(
        repository: FakeSafeZonesRepository(board: board()),
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
      );

      controller.goToEditor('z7');

      expect(routes.single, ('push', AppRoutes.safeZoneEditor, 'z7'));
    });

    test(
      'setup replaces the stack, so back does not return to an empty board',
      () async {
        final List<(String, String, Object?)> routes = [];
        final SafeZonesController controller = SafeZonesController(
          repository: FakeSafeZonesRepository(noFamily: true),
          replace: (String route, Object? arg) =>
              routes.add(('replace', route, arg)),
        );

        controller.goToSetup();

        expect(routes.single, ('replace', AppRoutes.onboarding, null));
      },
    );
  });
}
