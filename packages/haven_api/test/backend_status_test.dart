import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('BackendStatus', () {
    test('an unconfigured build can neither sign in nor load data', () {
      final status = BackendStatus.of(BackendEndpoints.unconfigured);
      expect(status.readiness, BackendReadiness.notConfigured);
      expect(status.canSignIn, isFalse);
      expect(status.canLoadData, isFalse);
      expect(status.message, contains('Not connected'));
    });

    test('firebase alone is not a session to sign into', () {
      const endpoints = BackendEndpoints(
        supabaseUrl: '',
        supabaseAnonKey: '',
        firebaseProjectId: 'haven-staging-46822',
        firebaseAppId: '1:2:3:4',
        firebaseApiKey: 'k',
      );
      final status = BackendStatus.of(endpoints);
      expect(status.readiness, BackendReadiness.firebaseOnly);
      expect(status.canSignIn, isFalse);
      expect(status.projectRef, 'haven-staging-46822');
    });

    test('supabase url yields the non-secret ref for display', () {
      const endpoints = BackendEndpoints(
        supabaseUrl: 'https://dzonzgngwxclhfnvxtvu.supabase.co',
        supabaseAnonKey: 'anon',
        firebaseProjectId: '',
        firebaseAppId: '',
        firebaseApiKey: '',
      );
      final status = BackendStatus.of(endpoints);
      expect(status.projectRef, 'dzonzgngwxclhfnvxtvu');
      expect(status.canLoadData, isTrue);
    });
  });

  group('captured contract guards', () {
    test('only the 19 captured tables are accepted', () {
      expect(TableName.all.length, 19);
      TableName.assertKnown(TableName.deviceCommands);
      expect(
        () => TableName.assertKnown('parental_controls'),
        throwsArgumentError,
      );
    });

    test('only the 14 captured RPCs are accepted', () {
      expect(RpcName.all.length, 14);
      RpcName.assertKnown(RpcName.pollDeviceCommands);
      expect(() => RpcName.assertKnown('sync_everything'), throwsArgumentError);
    });

    test('the three never-existing function slugs stay unreachable', () {
      expect(EdgeFunctionName.all.length, 9);
      for (final ghost in [
        'notification-cron',
        'register-token',
        'verify-firebase-token',
      ]) {
        expect(
          () => EdgeFunctionName.assertKnown(ghost),
          throwsArgumentError,
          reason: ghost,
        );
      }
    });
  });

  group('failure mapping', () {
    test('42501 is reported as a permission refusal, not as missing data', () {
      const error = PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );
      final failure = mapPostgrest(error);
      expect(failure, isA<PermissionFailure>());
      expect(failure.detail, contains('row-level security'));
    });

    test('an expired JWT signs the user out downstream', () {
      const error = PostgrestException(
        message: 'jwt expired',
        code: 'PGRST301',
      );
      final failure = mapPostgrest(error);
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).signedOut, isTrue);
    });

    test(
      'a network-layer auth error becomes retryable, and a null code cannot throw',
      () {
        final failure = mapAuth(
          AuthRetryableFetchException(message: 'Connection refused'),
        );
        expect(failure, isA<NetworkFailure>());
        expect(failure.retryable, isTrue);
        expect(
          mapAuth(
            const AuthException('Login Failed', code: 'invalid_credentials'),
          ).message,
          contains("isn't recognised"),
        );
        expect(
          mapAuth(const AuthException('boom')).message,
          contains('did not complete'),
        );
      },
    );

    test('a timeout is a network failure', () {
      expect(
        mapSupabaseError(
          TimeoutException('read timed out', Duration(seconds: 2)),
        ),
        isA<NetworkFailure>(),
      );
    });
  });

  group('Edge envelope', () {
    test('a 200 with no data key is not treated as success', () {
      final result = dataFrom(
        const Ok(EdgeReply(status: 200, body: {'error': null})),
      );
      expect(result, isA<Err<Map<String, Object?>>>());
      expect(result.failureOrNull!.message, contains('without any data'));
    });

    test('a refused reply carries the service message', () {
      final result = dataFrom(
        const Ok(EdgeReply(status: 403, body: {'error': 'not your family'})),
      );
      expect(result.failureOrNull, isA<BackendFailure>());
      expect(result.failureOrNull!.message, 'not your family');
    });

    test('the {ok:true, ...fields} answer yields its fields', () {
      final result = dataFrom(
        const Ok(
          EdgeReply(
            status: 200,
            body: {'ok': true, 'role': 'parent', 'contact_id_prefix': 'PC'},
          ),
        ),
      );
      expect(result.valueOrNull, {
        'role': 'parent',
        'contact_id_prefix': 'PC',
      });
    });

    test('an error object is read as its message, with its code attached', () {
      final result = dataFrom(
        const Ok(
          EdgeReply(
            status: 409,
            errorCode: 'role_already_set',
            body: {
              'ok': false,
              'error': {
                'code': 'role_already_set',
                'message': 'A role is already set for this account.',
              },
            },
          ),
        ),
      );
      expect(
        result.failureOrNull!.message,
        'A role is already set for this account.',
      );
      expect((result.failureOrNull! as BackendFailure).code, 'role_already_set');
    });

    test('a data payload passes through', () {
      final result = dataFrom(
        const Ok(
          EdgeReply(
            status: 200,
            body: {
              'data': {'ok': 1},
            },
          ),
        ),
      );
      expect(result.valueOrNull, {'ok': 1});
    });
  });
}
