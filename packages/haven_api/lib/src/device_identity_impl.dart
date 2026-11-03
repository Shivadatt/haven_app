import 'dart:convert';

import 'package:haven_core/haven_core.dart';

import 'auth_contracts.dart';

/// `DeviceIdentity` over an injected [SecretVault].
///
/// The child device credential (`x-device-id` + `x-device-secret`, per the
/// captured device lane) is written only when the platform vault is available.
/// If it is not, issuing fails outright: a plaintext fallback would violate the
/// rule that device secrets are never stored in the clear, and a silently
/// "successful" pair would leave a device that cannot authenticate later.
final class VaultDeviceIdentity implements DeviceIdentity {
  VaultDeviceIdentity(this._vault, {this.key = 'haven.device.credential'});

  final SecretVault _vault;
  final String key;

  @override
  Future<Result<DeviceCredential?>> credential() async {
    if (!_vault.available) {
      return Err(
        StorageFailure(
          'Secure storage is unavailable on this device.',
          detail: 'keystore down',
        ),
      );
    }
    try {
      final raw = await _vault.read(key);
      if (raw == null) return Ok(null);
      final decoded = _decode(raw);
      final deviceId = decoded is Map ? decoded['device_id'] : null;
      final secret = decoded is Map ? decoded['secret'] : null;
      if (deviceId is! String || secret is! String) {
        // A payload the app cannot use is not a pairing: leaving it stored would
        // report a device that can never authenticate.
        await _vault.delete(key);
        return Ok(null);
      }
      return Ok(
        DeviceCredential(
          deviceId: deviceId,
          secret: secret,
          storedSecurely: true,
        ),
      );
    } catch (error) {
      return Err(
        StorageFailure(
          'The stored device credential could not be read.',
          detail: '$error',
        ),
      );
    }
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Result<DeviceCredential>> issue(DeviceCredential credential) async {
    if (!_vault.available) {
      return Err(
        StorageFailure(
          "This device can't protect a pairing secret right now, so pairing can't be completed safely.",
          detail: 'secure vault unavailable; refusing plaintext',
        ),
      );
    }
    final payload = jsonEncode({
      'device_id': credential.deviceId,
      'secret': credential.secret,
    });
    final stored = await _vault.write(key, payload);
    if (!stored) {
      return Err(
        const StorageFailure(
          'The device credential could not be stored.',
          detail: 'vault write false',
        ),
      );
    }
    return Ok(credential);
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _vault.delete(key);
      return okVoid();
    } catch (error) {
      return Err(
        StorageFailure(
          'The stored device credential could not be removed.',
          detail: '$error',
        ),
      );
    }
  }
}
