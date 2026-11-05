import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/account/controllers/account_controller.dart';
import 'package:haven_app/features/account/data/account_repository.dart';
import 'package:haven_app/features/account/views/pages/account_page.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

void main() {
  const profile = Profile(id: 'u1', role: 'parent', displayName: 'Rae');
  final AccountInfo offlineInfo = AccountInfo(
    userId: 'u1',
    email: 'local@device.test',
    profile: profile,
    isOffline: true,
  );

  tearDown(Get.reset);

  group('Profile edit and validation', () {
    test('display name rejects values outside 2-60 characters', () {
      expect(validateDisplayName(''), isNotNull);
      expect(validateDisplayName('A'), isNotNull);
      expect(validateDisplayName('B' * 61), isNotNull);
      expect(validateDisplayName('Ada'), isNull);
      expect(validateDisplayName('B' * 60), isNull);
    });

    test('createProfile validates display name before creating', () async {
      final repo = FakeAccountRepository(
        info: const AccountInfo(userId: 'u1', email: 'p@example.test'),
      );
      final controller = AccountController(repository: repo);
      await controller.load();

      expect(controller.canCreate, isTrue);
      controller.displayName.text = 'X';
      await controller.createProfile();

      expect(controller.message.value, 'Use at least 2 characters.');
      expect(repo.calls.contains('createProfile'), isFalse);

      controller.displayName.text = 'Valid Parent Name';
      await controller.createProfile();

      expect(repo.calls.contains('createProfile'), isTrue);
      expect(repo.lastDisplayName, 'Valid Parent Name');
    });

    test('rename trims whitespace and rejects short names', () async {
      final repo = FakeAccountRepository(info: offlineInfo);
      final controller = AccountController(repository: repo);
      await controller.load();

      controller.displayName.text = '   ';
      await controller.save();
      expect(controller.message.value, 'Enter a name.');

      controller.displayName.text = '  Parent Ada  ';
      await controller.save();
      expect(repo.lastDisplayName, 'Parent Ada');
    });
  });

  group('Offline and local session status display', () {
    testWidgets('displays local session chip and offline mode indicator', (
      tester,
    ) async {
      final repo = FakeAccountRepository(info: offlineInfo);
      Get.put<AccountController>(AccountController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(theme: HavenTheme.light, home: const AccountPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Local session'), findsOneWidget);
      expect(find.textContaining('Session mode: Local (Offline)'), findsOneWidget);
      expect(find.text('Rae'), findsOneWidget);
      expect(find.text('Parent'), findsOneWidget);
    });
  });
}
