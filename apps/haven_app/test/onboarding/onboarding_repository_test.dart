import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/onboarding/data/onboarding_repository.dart';

import '../support/backend_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeEdgeCaller edge;
  late FakeProfileStore profiles;
  late EdgeOnboardingRepository subject;

  setUp(() {
    edge = FakeEdgeCaller();
    profiles = FakeProfileStore({'u1': null});
    subject = EdgeOnboardingRepository(
      edge: () => edge,
      profiles: () => profiles,
    );
  });

  group('claimParentRole', () {
    test('sends the one body the captured action accepts', () async {
      final result = await subject.claimParentRole();

      expect(result.failureOrNull, isNull);
      expect(edge.slugs, [EdgeFunctionName.authBootstrap]);
      expect(edge.lastBody, {'action': 'set_role', 'role': 'parent'});
    });

    test('treats an already-set role as further along, not broken', () async {
      edge.reply = refused(
        409,
        'role_already_set',
        'A role is already set for this account.',
      );

      expect((await subject.claimParentRole()).failureOrNull, isNull);
    });

    test('carries the service message for any other refusal', () async {
      edge.reply = refused(403, 'not_signed_in', 'Sign in first.');

      final failure = (await subject.claimParentRole()).failureOrNull;

      expect(failure, isA<BackendFailure>());
      expect(failure!.message, 'Sign in first.');
      expect((failure as BackendFailure).code, 'not_signed_in');
    });

    test('passes a transport failure through unchanged', () async {
      edge.reply = Err(const NetworkFailure('The internet is unreachable.'));

      expect(
        (await subject.claimParentRole()).failureOrNull,
        isA<NetworkFailure>(),
      );
    });
  });

  group('createFamily', () {
    test('trims the name before sending it', () async {
      final result = await subject.createFamily(name: '  Rivera household  ');

      expect(result.failureOrNull, isNull);
      expect(edge.lastBody, {
        'action': 'create_family',
        'name': 'Rivera household',
      });
    });

    test('rejects an empty name without calling the service', () async {
      final failure = (await subject.createFamily(name: '   ')).failureOrNull;

      expect(failure, isA<ValidationFailure>());
      expect(edge.slugs, isEmpty);
    });

    test('rejects a name over the schema bound without calling', () async {
      final failure = (await subject.createFamily(
        name: 'n' * 81,
      )).failureOrNull;

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).field, 'family_name');
      expect(edge.slugs, isEmpty);
    });

    test(
      'reports the one-family-per-owner refusal in the service’s words',
      () async {
        edge.reply = refused(
          409,
          'family_exists',
          'This account already owns a family.',
        );

        final failure = (await subject.createFamily(
          name: 'Rivera',
        )).failureOrNull;

        expect(failure, isA<BackendFailure>());
        expect(failure!.message, 'This account already owns a family.');
      },
    );
  });

  group('hasProfile', () {
    test('is true when a row exists', () async {
      profiles = FakeProfileStore({
        'u1': {'role': 'parent'},
      });
      subject = EdgeOnboardingRepository(
        edge: () => edge,
        profiles: () => profiles,
      );

      expect((await subject.hasProfile('u1')).valueOrNull, isTrue);
    });

    test('is false when the account has no row yet', () async {
      expect((await subject.hasProfile('u1')).valueOrNull, isFalse);
    });

    test('fails when the read itself fails', () async {
      expect(
        (await subject.hasProfile('ghost')).failureOrNull,
        isA<NetworkFailure>(),
      );
    });
  });

  test(
    'a replaced seam is followed, so the post-install caller is used',
    () async {
      var caller = edge;
      subject = EdgeOnboardingRepository(
        edge: () => caller,
        profiles: () => profiles,
      );

      final installed = FakeEdgeCaller(reply: accepted({'role': 'parent'}));
      caller = installed;

      expect((await subject.claimParentRole()).failureOrNull, isNull);
      expect(installed.slugs, [EdgeFunctionName.authBootstrap]);
      expect(edge.slugs, isEmpty);
    },
  );
}
