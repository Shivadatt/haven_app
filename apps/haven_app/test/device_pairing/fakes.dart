import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/device_pairing/data/pairing_models.dart';
import 'package:haven_app/features/device_pairing/data/pairing_repository.dart';
import 'package:haven_models/haven_models.dart';

import 'pairing_harness.dart';

/// A request the board is built from, in the shape the screen consumes.
PairingLine line(
  String id,
  String childName, {
  String status = 'pending_child',
  bool responded = false,
}) => PairingLine(
  request: PairingRequest(
    id: id,
    tokenId: 't-$id',
    familyId: familyId,
    parentUserId: 'u1',
    childUserId: 'c1',
    status: status,
    createdAt: DateTime.utc(2026, 11, 1, 9),
    expiresAt: DateTime.utc(2026, 11, 1, 9, 20),
    respondedAt: responded ? DateTime.utc(2026, 11, 1, 9, 5) : null,
  ),
  childName: childName,
);

PairingBoard board({
  List<PairingLine> lines = const [],
  String? name = 'Rivera',
}) => PairingBoard(familyId: familyId, familyName: name, lines: lines);

/// The pairing screen's answers, driven by the test.
class FakePairingRepository implements PairingRepository {
  FakePairingRepository({this.board});

  /// Null payload = this account has no family yet.
  PairingBoard? board;

  HavenFailure? loadFailWith;

  /// Set these to make a refusal look like something other than a missing
  /// contract, which is how a test proves the screen only treats
  /// [BlockedFailure] as a gap.
  HavenFailure? inviteFailWith;
  HavenFailure? codeFailWith;
  HavenFailure? cancelFailWith;

  final List<String> calls = [];
  String? lastCancelId;

  @override
  Future<Result<PairingBoard?>> load() async {
    calls.add('load');
    final HavenFailure? failure = loadFailWith;
    if (failure != null) return Err<PairingBoard?>(failure);
    return Ok<PairingBoard?>(board);
  }

  @override
  Future<Result<void>> createInvite() async {
    calls.add('createInvite');
    return _refused(inviteFailWith, 'starting an invite');
  }

  @override
  Future<Result<void>> redeemCode() async {
    calls.add('redeemCode');
    return _refused(codeFailWith, 'accepting a code');
  }

  @override
  Future<Result<void>> cancel(String requestId) async {
    calls.add('cancel');
    lastCancelId = requestId;
    return _refused(cancelFailWith, 'withdrawing a request');
  }

  Future<Result<void>> _refused(HavenFailure? override, String what) async =>
      override == null
      ? blocked('fake: no contract for $what')
      : Err<void>(override);
}
