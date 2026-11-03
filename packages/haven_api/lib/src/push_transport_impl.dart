import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:haven_core/haven_core.dart';

import 'auth_contracts.dart';

/// `PushTransport` over Firebase Cloud Messaging.
///
/// This owns the *device-side* registration lifecycle only. Registering a
/// token server-side is blocked: the token table exists only in the unapproved
/// `A3c-notification-backend.sql`, and there is no `register-token` function.
/// Firebase is also not registered in this build (no `google-services.json`,
/// A12-R unsigned), so every path degrades to a failure the UI can show instead
/// of pretending a subscription exists.
final class FirebasePushTransport implements PushTransport {
  FirebasePushTransport();

  static const _noFirebaseApp =
      'No Firebase app is registered in this build (A12-R unsigned; google-services.json absent).';

  /// `onRegistered` is a broadcast stream with no replay, so the value is lost
  /// if nothing is listening when the native side fires. Subscribe first, then
  /// bound the wait — a silent plugin is reported, not assumed to have worked.
  static const _registrationWait = Duration(seconds: 20);

  bool get _ready => Firebase.apps.isNotEmpty;

  @override
  Future<Result<String?>> registrationTarget() async {
    if (!_ready)
      return blocked(
        _noFirebaseApp,
        requirement: 'Push is not available in this build.',
      );
    try {
      final messaging = FirebaseMessaging.instance;
      final target = messaging.onRegistered.first.timeout(_registrationWait);
      await messaging.register();
      return Ok(await target);
    } on TimeoutException {
      return const Err(
        UnknownFailure(
          'Push registration did not report back, so this device is not reachable yet.',
          detail: 'onRegistered never fired within 20s of register()',
        ),
      );
    } catch (error) {
      return Err(
        UnknownFailure(
          'The device could not register for push.',
          detail: '$error',
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearRegistration() async {
    if (!_ready)
      return blocked(
        _noFirebaseApp,
        requirement: 'Push is not available in this build.',
      );
    try {
      await FirebaseMessaging.instance.unregister();
      return okVoid();
    } catch (error) {
      return Err(
        UnknownFailure(
          'The push registration could not be removed.',
          detail: '$error',
        ),
      );
    }
  }

  /// The Firebase Installation ID reported on each (re)registration.
  @override
  Stream<String> get registrationChanges => _ready
      ? FirebaseMessaging.instance.onRegistered
      : const Stream<String>.empty();

  /// Reports what the operating system answered. Never returns "granted" because
  /// the user tapped something.
  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> get granted async {
    if (!_ready) return false;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<Map<String, Object?>> get taps => _ready
      ? FirebaseMessaging.onMessageOpenedApp.map((message) => _payload(message))
      : const Stream<Map<String, Object?>>.empty();

  @override
  Stream<Map<String, Object?>> get foregroundMessages => _ready
      ? FirebaseMessaging.onMessage.map((message) => _payload(message))
      : const Stream<Map<String, Object?>>.empty();

  /// Notification payload keys are whatever the sender used. Nothing here
  /// invents a key or a routing rule.
  static Map<String, Object?> _payload(RemoteMessage message) => {
    'messageId': message.messageId,
    'title': message.notification?.title,
    'body': message.notification?.body,
    'data': message.data,
  };
}
