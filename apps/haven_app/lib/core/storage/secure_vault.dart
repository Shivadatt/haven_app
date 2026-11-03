import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haven_api/haven_api.dart';

/// [SecretVault] over the platform keystore (Android) / Keychain (iOS).
///
/// Availability is *observed*, not assumed: the first platform failure flips
/// [available] to false, and [write] then reports failure instead of falling
/// back to plaintext. The plugin defaults are kept — on Android that is
/// Keystore-wrapped AES-GCM, not a preferences file.
final class SecureVault implements SecretVault {
  SecureVault({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  bool _available = true;

  @override
  bool get available => _available;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // An unreadable vault is an unavailable vault: the caller must not be
      // tempted to treat a failure as "nothing stored".
      _available = false;
      return null;
    }
  }

  @override
  Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _available = false;
    }
  }
}
