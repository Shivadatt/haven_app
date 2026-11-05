import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/family/controllers/child_create_controller.dart';

import 'fakes.dart';

void main() {
  group('ChildCreateController', () {
    late FakeFamilyRepository repo;

    setUp(() {
      repo = FakeFamilyRepository(bundle: bundle());
    });

    test('validates empty name', () async {
      final controller = ChildCreateController(repository: repo);
      controller.nameController.text = '   ';
      final ok = await controller.createChild();

      expect(ok, isFalse);
      expect(controller.nameError.value, isNotNull);
      expect(repo.calls, isEmpty);
    });

    test('creates child profile with avatar and age bracket', () async {
      String? routed;
      Object? routeArg;
      final controller = ChildCreateController(
        repository: repo,
        goTo: (route, arg) {
          routed = route;
          routeArg = arg;
        },
      );

      controller.nameController.text = 'Sammy';
      controller.selectedAgeBracket.value = '8–11';
      controller.selectedAvatar.value = '🐼';

      final ok = await controller.createChild();

      expect(ok, isTrue);
      expect(repo.calls, contains('addChild'));
      expect(repo.lastChildName, equals('Sammy'));
      expect(repo.lastAgeBracket, equals('8–11'));
      expect(repo.lastAvatar, equals('🐼'));
      expect(routed, equals(AppRoutes.childProfile));
      expect(routeArg, isNotNull);
    });
  });
}
