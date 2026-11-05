import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../family/data/family_models.dart';
import '../../family/data/family_repository.dart';
import '../../family/data/family_scope.dart';
import 'pairing_models.dart';

/// The pairing screen's surface.
///
/// One half of pairing is readable: `pairing_requests` is SELECT-able by the
/// child, the parent who raised it, or a parent of the family
/// (`docs/stage1/04-rls-matrix.md:51`, policy
/// `pairing_requests_select_participants`). Nothing else about pairing is
/// reachable from this app — the tokens, the attempt log and the child contact
/// ids are deny-all, the RPCs are not executable by the signed-in role
/// ([CapturedGaps.rpcLaneMissing]) and the `pairing` Edge Function, which is the
/// caller of record, stops at a captured `action` discriminator with no captured
/// body beside it. So the three write calls are typed refusals.
abstract interface class PairingRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  Future<Result<PairingBoard?>> load();

  /// Ask the service for an invite for a child's Haven ID.
  Future<Result<void>> createInvite();

  /// Submit the short code a child's device is showing.
  ///
  /// Takes no argument on purpose: the name the code would travel under is one
  /// of the request-body fields the capture never recorded, so a parameter here
  /// would look like a known contract and not be one.
  Future<Result<void>> redeemCode();

  /// Withdraw a request that is still waiting on the child.
  Future<Result<void>> cancel(String requestId);
}

final class HavenPairingRepository implements PairingRepository {
  HavenPairingRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required FamilyRepository Function() family,
  }) : _scope = scope,
       _rows = rows,
       _family = family;

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final FamilyRepository Function() _family;

  @override
  Future<Result<PairingBoard?>> load() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      if (FamilyScopeReader.isMissingFamily(why)) {
        return const Ok<PairingBoard?>(null);
      }
      return Err<PairingBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.pairingRequests,
      eq: {'family_id': mine.familyId},
      orderDesc: 'created_at',
      limit: PairingBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<PairingBoard?>(readFailure);

    // The table holds ids, not people. Names come from the family read, so a
    // parent sees "Ivy" and not a uuid.
    final Result<FamilyBundle?> bundle = await _family().load();
    final HavenFailure? namesFailure = bundle.failureOrNull;
    if (namesFailure != null) return Err<PairingBoard?>(namesFailure);
    final FamilyBundle? people = bundle.valueOrNull;
    final Map<String, String> names = _namesOf(people);

    return Ok<PairingBoard?>(
      PairingBoard(
        familyId: mine.familyId,
        familyName: people?.family.name,
        lines: rows.valueOrNull!
            .map((Map<String, Object?> row) {
              final PairingRequest request = PairingRequest.fromRow(row);
              return PairingLine(
                request: request,
                childName:
                    names[request.childUserId] ??
                    'A child who is not in your family list',
              );
            })
            .toList(growable: false),
      ),
    );
  }

  @override
  Future<Result<void>> createInvite() async => blocked(
    _edgeLaneMissing('`invite`', 'create_pairing_invite'),
    requirement: 'Haven cannot start an invite for a child in this build yet.',
  );

  @override
  Future<Result<void>> redeemCode() async => blocked(
    _edgeLaneMissing('`create` and `redeem`', 'create_pairing_request'),
    requirement: 'Haven cannot accept a pairing code in this build yet.',
  );

  @override
  Future<Result<void>> cancel(String requestId) async => blocked(
    '`authenticated` has no UPDATE grant on `pairing_requests` '
    '(docs/stage1/04-rls-matrix.md:132), no captured RPC cancels a request, and '
    'the `cancel` action of the `pairing` Edge Function has no captured request '
    'body beside `action`',
    requirement: 'Haven cannot withdraw a pairing request in this build yet.',
  );

  /// The reason every write in this feature reads the same way.
  ///
  /// The `pairing` Edge Function is the caller the evidence actually shows
  /// reaching these RPCs — it passes `p_parent_user_id = auth.user.id` from the
  /// verified JWT (capture-20261030.json:38-40) — but only its `action` values
  /// were captured, never the field names beside it, and no Edge Function is
  /// deployed to staging. A body invented here would be a contract invented
  /// here.
  static String _edgeLaneMissing(String actions, String rpc) =>
      'the $actions path runs through the `pairing` Edge Function, whose request '
      'body beyond the `action` discriminator was never captured '
      '(capture-20261030.json:31-40); calling $rpc directly is closed by '
      '${CapturedGaps.rpcLaneMissing}; and `device_pairing_tokens` and '
      '`pairing_attempts` are deny-all to every client role '
      '(docs/stage1/04-rls-matrix.md:44,50)';

  static Map<String, String> _namesOf(FamilyBundle? bundle) {
    if (bundle == null) return const {};
    return <String, String>{
      for (final FamilyPerson person in [...bundle.children, ...bundle.parents])
        person.userId: person.name,
    };
  }
}
