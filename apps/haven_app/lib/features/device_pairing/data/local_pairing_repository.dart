import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../family/data/family_repository.dart';
import '../../family/data/family_scope.dart';
import 'pairing_models.dart';
import 'pairing_repository.dart';

/// Offline pairing: the request row is the whole exchange, on this phone.
///
/// Cloud pairing is closed because the token lane and the Edge contract were
/// never captured. Offline there is no child device to convince — an invite
/// writes a `pending_child` request, accepting it writes the same approval a
/// child's tap would produce, and cancelling rewrites the status. Every result
/// is a row on this device, which is exactly what the board then shows; no
/// screen claims a second phone was involved.
final class LocalPairingRepository implements PairingRepository {
  LocalPairingRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
    required FamilyRepository Function() family,
  }) : _scope = scope,
       _rows = rows,
       _writer = writer,
       _base = HavenPairingRepository(
         scope: scope,
         rows: rows,
         family: family,
       );

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;

  /// Reads are already honest offline — the refusal lives only in the writes.
  final HavenPairingRepository _base;

  factory LocalPairingRepository.live({
    required FamilyRepository Function() family,
  }) {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return LocalPairingRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
      family: family,
    );
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  @override
  Future<Result<PairingBoard?>> load() => _base.load();

  @override
  Future<Result<void>> createInvite() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);
    return _writer().insert(TableName.pairingRequests, <String, Object?>{
      'id': LocalIds.create(),
      'token_id': LocalIds.create(),
      'family_id': mine.familyId,
      'parent_user_id': mine.session.userId,
      'child_user_id': '',
      'status': 'pending_child',
      'created_at': _now(),
      'expires_at': _expiry(),
    });
  }

  @override
  Future<Result<void>> redeemCode() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);
    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.pairingRequests,
      eq: {'family_id': mine.familyId},
      orderDesc: 'created_at',
    );
    final HavenFailure? failure = rows.failureOrNull;
    if (failure != null) return Err<void>(failure);
    final PairingRequest? waiting = _firstPending(rows.valueOrNull!);
    if (waiting == null) {
      return const Err<void>(
        ValidationFailure(
          'Nothing on this phone is waiting for a pairing code.',
          field: 'pairing',
        ),
      );
    }
    return _writer().update(
      TableName.pairingRequests,
      <String, Object?>{
        'status': 'approved',
        'responded_at': _now(),
      },
      eq: {'id': waiting.id, 'family_id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> cancel(String requestId) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);
    return _writer().update(
      TableName.pairingRequests,
      <String, Object?>{'status': 'cancelled', 'responded_at': _now()},
      eq: {'id': requestId, 'family_id': mine.familyId},
    );
  }

  static PairingRequest? _firstPending(List<Map<String, Object?>> rows) {
    for (final Map<String, Object?> row in rows) {
      final PairingRequest request = PairingRequest.fromRow(row);
      if (request.isPending) return request;
    }
    return null;
  }

  static String _expiry() =>
      DateTime.now().toUtc().add(const Duration(days: 7)).toIso8601String();
}
