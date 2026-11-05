import 'package:haven_core/haven_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_contracts.dart';
import 'backend_endpoints.dart';
import 'failure_mapper.dart';

/// `ProfileStore` over the captured `profiles` row
/// (`id`, `role`, `display_name`, `created_at`, `updated_at`).
///
/// A missing row is `Ok(null)`, not an error: the profile-provisioning gap in
/// `docs/stage2/S2-A1-auth-architecture.md` means a signed-in user can legally
/// have no profile yet, and the app must say so rather than invent one.
final class SupabaseProfileStore implements ProfileStore {
  SupabaseProfileStore(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<Map<String, Object?>?>> load(String userId) async {
    try {
      final rows = await _client
          .from(TableName.profiles)
          .select()
          .eq('id', userId)
          .limit(1);
      return Ok(rows.isEmpty ? null : Map<String, Object?>.from(rows.first));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> updateDisplayName(
    String userId,
    String displayName,
  ) async {
    final invalid = validateDisplayName(displayName);
    if (invalid != null) {
      return Err(ValidationFailure(invalid, field: 'display_name'));
    }
    try {
      await _client
          .from(TableName.profiles)
          .update({'display_name': displayName.trim()})
          .eq('id', userId);
      return okVoid();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> createProfile({
    required String userId,
    required String displayName,
    String? email,
    String role = 'parent',
  }) async {
    return const Err(
      BlockedFailure(
        'Cloud profile creation is not supported by the captured backend.',
        missing: 'cloud profile creation',
      ),
    );
  }
}
