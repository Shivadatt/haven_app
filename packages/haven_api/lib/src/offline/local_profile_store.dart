import 'package:haven_core/haven_core.dart';

import '../auth_contracts.dart';
import 'local_tables.dart';

/// Loads and updates the person's own local `profiles` row.
final class LocalProfileStore implements ProfileStore {
  LocalProfileStore(this._tables);

  final LocalTables _tables;

  @override
  Future<Result<Map<String, Object?>?>> load(String userId) =>
      _tables.first('profiles', eq: {'id': userId});

  @override
  Future<Result<void>> updateDisplayName(
    String userId,
    String displayName,
  ) => _tables.update(
    'profiles',
    <String, Object?>{
      'display_name': displayName,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    eq: <String, Object?>{'id': userId},
  );

  @override
  Future<Result<void>> createProfile({
    required String userId,
    required String displayName,
    String? email,
    String role = 'parent',
  }) async {
    final String trimmed = displayName.trim();
    final String? invalid = validateDisplayName(trimmed);
    if (invalid != null) {
      return Err<void>(ValidationFailure(invalid, field: 'display_name'));
    }
    final String now = DateTime.now().toUtc().toIso8601String();
    return _tables.insert('profiles', <String, Object?>{
      'id': userId,
      if (email != null) 'email': email,
      'role': role,
      'display_name': trimmed,
      'created_at': now,
      'updated_at': now,
    });
  }
}

