import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show FamilyMember;

/// The signed-in parent and the family they belong to.
///
/// Almost every screen in Haven needs both before it can read or write
/// anything, and neither may be assumed: the family id comes from the caller's
/// own `family_members` row, never from a value a widget was handed. Owning the
/// resolution in one place is also what keeps the rest of the app from
/// inventing a family id when the account has none.
final class FamilyScope {
  const FamilyScope({required this.session, required this.familyId});

  final AuthSession session;
  final String familyId;
}

/// Resolves a scope, or refuses with the reason there isn't one.
///
/// A missing membership row is deliberately *not* a backend fault: it is the
/// first-run state that setup exists to fix, so it comes back as a refusal the
/// screen can route on.
final class FamilyScopeReader {
  FamilyScopeReader({
    required UserAuth Function() auth,
    required RowReader Function() rows,
  }) : _auth = auth,
       _rows = rows;

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final UserAuth Function() _auth;
  final RowReader Function() _rows;

  /// The session, or the failure that says why there isn't one.
  Future<Result<AuthSession>> session() async {
    final Result<AuthSession?> raw = await _auth().currentSession();
    final HavenFailure? failure = raw.failureOrNull;
    if (failure != null) return Err<AuthSession>(failure);
    final AuthSession? session = raw.valueOrNull;
    return session == null
        ? const Err<AuthSession>(
            AuthFailure('You are not signed in.', signedOut: true),
          )
        : Ok<AuthSession>(session);
  }

  Future<Result<FamilyScope>> resolve() async {
    final Result<AuthSession> signedIn = await session();
    final AuthSession? active = signedIn.valueOrNull;
    if (active == null) return Err<FamilyScope>(signedIn.failureOrNull!);

    final Result<Map<String, Object?>?> mine = await _rows().first(
      TableName.familyMembers,
      eq: {'user_id': active.userId},
    );
    final HavenFailure? readFailure = mine.failureOrNull;
    if (readFailure != null) return Err<FamilyScope>(readFailure);
    final Map<String, Object?>? row = mine.valueOrNull;
    if (row == null) {
      return const Err<FamilyScope>(
        ValidationFailure(
          'Set up Haven first — this account is not in a family yet.',
          field: 'family',
        ),
      );
    }
    return Ok<FamilyScope>(
      FamilyScope(
        session: active,
        familyId: FamilyMember.fromRow(row).familyId,
      ),
    );
  }

  /// True when this refusal means "not set up yet" rather than "the backend
  /// failed". Callers use it to show a setup path instead of an error.
  static bool isMissingFamily(HavenFailure failure) =>
      failure is ValidationFailure && failure.field == 'family';
}
