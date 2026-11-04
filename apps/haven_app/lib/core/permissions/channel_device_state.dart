import 'package:flutter/services.dart';
import 'package:haven_core/haven_core.dart';

import 'device_state_decoding.dart';
import 'native_device_state.dart';

/// The names this side and the Kotlin side agree on.
///
/// [name] and [readAllMethod] are the Dart half of
/// `android_native/child_services/platform_bridge/BridgeContract.kt`; changing one
/// without the other is a compile-time error on neither side, which is exactly why
/// both live in one place here and one place there.
abstract final class DeviceStateChannel {
  static const String name = 'haven.dev/child_device_state';
  static const String readAllMethod = 'state.readAll';
}

/// The device lane as the Android build answers it.
///
/// One call, one read, no caching: a permission can change the moment the parent
/// leaves the app for Settings, and a card that repeats a stale answer is worse than
/// a card that says it looked an hour ago.
final class ChannelNativeDeviceState implements NativeDeviceState {
  const ChannelNativeDeviceState({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(DeviceStateChannel.name);

  final MethodChannel _channel;

  @override
  Future<Result<DeviceStateReport>> read() async {
    final Object? reply;
    try {
      reply = await _channel.invokeMethod<Object?>(
        DeviceStateChannel.readAllMethod,
      );
    } on MissingPluginException {
      return Err<DeviceStateReport>(
        const UnknownFailure(
          'This build has no device-state lane to ask.',
          detail:
              'no channel named ${DeviceStateChannel.name} — the native readers are '
              'attached by the Android build only',
        ),
      );
    } on PlatformException catch (error) {
      return Err<DeviceStateReport>(
        UnknownFailure(
          'The phone refused the device-state question.',
          detail: '${error.code}: ${error.message ?? 'no reason given'}',
        ),
      );
    }
    final Map<String, Object?> envelope = _envelope(reply);
    final int? apiLevel = envelope['apiLevel'] is int
        ? envelope['apiLevel'] as int
        : null;
    if (apiLevel == null) {
      return Err<DeviceStateReport>(
        const BackendFailure(
          'The device-state answer arrived in a shape this build does not understand.',
          detail: 'no apiLevel in the reply',
        ),
      );
    }
    return Ok<DeviceStateReport>(decode(apiLevel, envelope, DateTime.now()));
  }

  /// The five sections, each either an answer or the phone's reason for not giving one.
  static DeviceStateReport decode(
    int apiLevel,
    Map<String, Object?> envelope,
    DateTime readAt,
  ) {
    final (Map<String, Object?> sections, Map<String, Object?> errors) =
        sectionMaps(envelope);
    return DeviceStateReport(
      apiLevel: apiLevel,
      osRelease: envelope['osRelease'] is String
          ? envelope['osRelease']! as String
          : '',
      readAt: readAt,
      permissions: areaReading(
        'permissions',
        sections,
        errors,
        decodePermissionStates,
      ),
      monitoring: areaReading(
        'monitoring',
        sections,
        errors,
        decodeMonitoringStates,
      ),
      location: areaReading('location', sections, errors, decodeLocationStates),
      deviceAdmin: areaReading(
        'deviceAdmin',
        sections,
        errors,
        decodeDeviceAdminStates,
      ),
      communication: areaReading(
        'communication',
        sections,
        errors,
        decodeCommunicationStates,
      ),
    );
  }
}

Map<String, Object?> _envelope(Object? reply) => reply is Map
    ? reply.map((Object? k, Object? v) => MapEntry<String, Object?>('$k', v))
    : <String, Object?>{};
