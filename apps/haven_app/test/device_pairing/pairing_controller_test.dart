import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/device_pairing/controllers/pairing_code_controller.dart';
import 'package:haven_app/features/device_pairing/controllers/pairing_controller.dart';

import 'fakes.dart';
import 'pairing_harness.dart';

(PairingController, List<(String, String, Object?)>) build(
  FakePairingRepository repo,
) {
  final routes = <(String, String, Object?)>[];
  return (
    PairingController(
      repository: repo,
      push: (String route, Object? arg) => routes.add(('push', route, arg)),
      replace: (String route, Object? arg) =>
          routes.add(('replace', route, arg)),
    ),
    routes,
  );
}

void main() {
  group('PairingController', () {
    test('the board read is kept as it came back', () async {
      final (subject, _) = build(
        FakePairingRepository(board: board(lines: [line('r1', 'Ivy')])),
      );

      await subject.load();

      expect(subject.isLoading.value, isFalse);
      expect(subject.board.value!.valueOrNull!.lines.single.childName, 'Ivy');
    });

    test('a failed read is a failure, not an empty pairing screen', () async {
      final (subject, _) = build(
        FakePairingRepository()
          ..loadFailWith = const NetworkFailure('Offline.'),
      );

      await subject.load();

      expect(subject.board.value!.failureOrNull, isA<NetworkFailure>());
      expect(subject.isLoading.value, isFalse);
    });

    test('both ways in are refused, in the repository\'s words', () async {
      final (subject, _) = build(FakePairingRepository(board: board()));
      await subject.load();

      expect(subject.inviteGap.value!.missing, contains('starting an invite'));
      expect(subject.codeGap.value!.missing, contains('accepting a code'));
    });

    test(
      'a withdrawal is only asked about when a child has to answer',
      () async {
        final repo = FakePairingRepository(
          board: board(lines: [line('r1', 'Ivy', status: 'approved')]),
        );
        final (subject, _) = build(repo);
        await subject.load();

        expect(subject.cancelGap.value, isNull);
        expect(repo.calls, isNot(contains('cancel')));
      },
    );

    test('a waiting request is named by id when the gap is read', () async {
      final repo = FakePairingRepository(
        board: board(lines: [line('r1', 'Ivy'), line('r2', 'Kai')]),
      );
      final (subject, _) = build(repo);
      await subject.load();

      expect(repo.lastCancelId, 'r1');
      expect(
        subject.cancelGap.value!.missing,
        contains('withdrawing a request'),
      );
    });

    test('a backend fault is not shown as a missing specification', () async {
      final (subject, _) = build(
        FakePairingRepository(board: board(lines: [line('r1', 'Ivy')]))
          ..cancelFailWith = const BackendFailure('The service errored.'),
      );
      await subject.load();

      expect(subject.cancelGap.value, isNull);
    });

    test(
      'how pairing works carries the family that was actually read',
      () async {
        final (subject, routes) = build(
          FakePairingRepository(board: board(lines: [line('r1', 'Ivy')])),
        );
        await subject.load();

        subject.goToCode();

        expect(routes, [('push', AppRoutes.pairingCode, familyId)]);
      },
    );

    test('no family goes to setup by replacing, not by stacking', () async {
      final (subject, routes) = build(FakePairingRepository());
      await subject.load();

      subject.goToSetup();

      expect(routes, [('replace', AppRoutes.onboarding, null)]);
    });

    test('a refresh re-reads instead of announcing anything', () async {
      final repo = FakePairingRepository(board: board());
      final (subject, _) = build(repo);
      await subject.load();

      repo.board = board(lines: [line('r1', 'Ivy')]);
      await subject.refresh();

      expect(subject.board.value!.valueOrNull!.hasLines, isTrue);
      expect(repo.calls, ['load', 'createInvite', 'redeemCode', 'load']);
    });
  });

  group('PairingCodeController', () {
    (PairingCodeController, List<String>) buildCode(
      String family,
      FakePairingRepository repo,
    ) {
      final routes = <String>[];
      return (
        PairingCodeController(
          familyId: family,
          repository: repo,
          goTo: (String route, Object? _) => routes.add(route),
        ),
        routes,
      );
    }

    test(
      'the two roads are explained as refusals, both read from the repo',
      () async {
        final (subject, _) = buildCode(
          familyId,
          FakePairingRepository(board: board()),
        );
        await subject.load();

        expect(subject.codeGap.value!.missing, contains('accepting a code'));
        expect(
          subject.inviteGap.value!.missing,
          contains('starting an invite'),
        );
      },
    );

    test('a screen opened for another family says so', () async {
      final (subject, _) = buildCode(
        'f9',
        FakePairingRepository(board: board()),
      );
      await subject.load();

      expect(subject.isForAnotherFamily, isTrue);
      expect(subject.familyName, 'Rivera');
    });

    test('a family name is only used once it has been read', () async {
      final (subject, _) = buildCode(
        familyId,
        FakePairingRepository(board: board(name: null)),
      );
      await subject.load();

      expect(subject.isForAnotherFamily, isFalse);
      expect(subject.familyName, 'your family');
    });

    test('back to pairing is a route, not a dead button', () async {
      final (subject, routes) = buildCode(familyId, FakePairingRepository());
      await subject.load();

      subject.goToPairing();

      expect(routes, [AppRoutes.pairing]);
    });
  });
}
