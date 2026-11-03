import 'dart:async';
import 'dart:io';

import 'package:haven_core/haven_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates SDK and transport errors into `haven_core` failures.
///
/// This is the only place that knows what a Supabase error looks like, so a
/// screen never branches on an SDK type and a refusal is never reported as a
/// mystery. Messages are written for a parent; the technical string stays in
/// [HavenFailure.detail] and is never shown as the headline.
HavenFailure mapSupabaseError(Object error) {
  if (error is PostgrestException) return mapPostgrest(error);
  if (error is AuthException) return mapAuth(error);
  if (error is FunctionsFetchException) {
    return NetworkFailure(
      'Could not reach the service.',
      detail: error.toString(),
    );
  }
  if (error is FunctionException) return _functions(error);
  if (error is TimeoutException) {
    return const NetworkFailure(
      "The service took too long to answer. Check the connection and try again.",
      detail: 'timeout',
    );
  }
  if (error is SocketException || error is HttpException) {
    return NetworkFailure(
      'No connection to the service.',
      detail: error.toString(),
    );
  }
  return UnknownFailure(
    'Something unexpected happened while contacting the service.',
    detail: '$error',
  );
}

/// `42501` is the RLS/privilege answer: the row exists to someone, but not to
/// this caller. Reporting that as "not found" would hide an authorization fact;
/// reporting it as a crash would hide it too.
HavenFailure mapPostgrest(PostgrestException error) {
  final code = error.code;
  final detail = '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
      .trim();
  return switch (code) {
    '42501' => PermissionFailure(
      "You're not allowed to see or change that.",
      detail: detail,
    ),
    '23505' => BackendFailure(
      'That entry already exists.',
      detail: detail,
      code: code,
    ),
    '23503' => BackendFailure(
      "The related entry doesn't exist any more.",
      detail: detail,
      code: code,
    ),
    'PGRST116' => BackendFailure(
      'Nothing was found.',
      detail: detail,
      code: code,
      retryable: true,
    ),
    'PGRST301' || 'PGRST302' => AuthFailure(
      'Your session is no longer valid. Please sign in again.',
      detail: detail,
      signedOut: true,
    ),
    _ => BackendFailure(
      'The service refused that request.',
      detail: 'code: $code $detail',
      code: code,
    ),
  };
}

/// Auth codes are compared as lowercase substrings of the code *or* the message:
/// the captured gotrue code set changes between SDK versions, `code` is nullable
/// (a pre-response failure has none), and a missed match degrades to
/// `AuthFailure` rather than throwing while handling a throw.
HavenFailure mapAuth(AuthException error) {
  final haystack = '${error.code ?? ''} ${error.message}'.toLowerCase();
  final detail = '${error.message} (code: ${error.code})';
  bool has(String needle) => haystack.contains(needle);

  if (error is AuthRetryableFetchException) {
    return NetworkFailure(
      'Could not reach the sign-in service.',
      detail: detail,
    );
  }
  if (has('expired') || has('session_not_found') || has('invalid_jwt')) {
    return AuthFailure(
      'Your session has ended. Please sign in again.',
      detail: detail,
      signedOut: true,
    );
  }
  if (has('invalid_credentials') ||
      has('failed_to_authenticate') ||
      has('user_not_found')) {
    return AuthFailure(
      "That email and password combination isn't recognised.",
      detail: detail,
    );
  }
  if (has('already_registered') || has('user_already_exists')) {
    return AuthFailure(
      'An account already uses that email address.',
      detail: detail,
    );
  }
  if (error is AuthWeakPasswordException ||
      has('weak_password') ||
      has('password_should_be')) {
    return AuthFailure(
      'That password is too simple. Use at least 8 characters.',
      detail: detail,
    );
  }
  if (has('rate_limit') || has('over_quota')) {
    return AuthFailure(
      'Too many attempts. Please wait a minute and try again.',
      detail: detail,
    );
  }
  return AuthFailure('Sign-in did not complete.', detail: detail);
}

HavenFailure _functions(FunctionException error) {
  final status = error.status;
  if (status == 401 || status == 403) {
    return PermissionFailure(
      "You're not allowed to run that.",
      detail: error.toString(),
    );
  }
  if (status >= 500) {
    return NetworkFailure(
      'The service is having trouble. Try again shortly.',
      detail: error.toString(),
    );
  }
  return BackendFailure(
    'The service refused that request.',
    detail: error.toString(),
    code: '${error.status}',
  );
}
