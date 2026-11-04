import 'package:haven_core/haven_core.dart';

/// The refusals more than one screen has to give, stated once.
///
/// A gap belongs in a repository when one feature owns it. These are owned by no
/// feature yet: the device lane is unreadable for every screen that wants it, so
/// the sentence lives here and each screen renders the same words instead of
/// paraphrasing the evidence and drifting from it.
abstract final class CapturedGaps {
  /// F6: `public.devices` has a SELECT policy but no SELECT grant for the
  /// `authenticated` role, so no client — this app included — can read it
  /// (`docs/stage1/00-status-register.md:86`).
  static const String deviceLaneMissing =
      '`devices` has a SELECT policy but no SELECT grant for `authenticated`, '
      'so no client can read it (F6, docs/stage1/00-status-register.md:86); '
      'the captured device Edge Functions have no readable request contract';

  static Result<T> deviceLaneUnavailable<T>({String? subject}) => blocked<T>(
    deviceLaneMissing,
    requirement: subject == null
        ? 'Haven cannot list paired devices in this build yet.'
        : 'Haven cannot show $subject devices here yet.',
  );

  /// The RPC lane. Both captures of the deployed schema give the same answer:
  /// every one of the 14 public functions carries
  /// `acl = "postgres=X/postgres,service_role=X/postgres"` and
  /// `auth_exec = false`, so the role this app signs in as cannot execute any of
  /// them (`docs/stage1/evidence/g1-q7-20261029.json`,
  /// `g1-b3b-20261029.json:68-81`). A service-role caller — an Edge Function —
  /// can, and staging has 0 Edge Functions deployed.
  static const String rpcLaneMissing =
      'every one of the 14 captured public RPCs grants EXECUTE only to '
      '`postgres` and `service_role` — `authenticated` holds none '
      '(g1-q7-20261029.json acl, g1-b3b-20261029.json:68-81 auth_exec=false) — '
      'and the Edge Functions that do hold a service role are not deployed';

  static Result<T> rpcUnavailable<T>(String what) => blocked<T>(
    rpcLaneMissing,
    requirement: 'Haven cannot $what in this build yet.',
  );

  /// Inside or outside a named place. The state that answers it is
  /// `public.safe_zone_states`, which the G1 run found deny-all: RLS on, zero
  /// policies, and `authenticated` holds no privilege on it at all
  /// (`docs/stage1/04-rls-matrix.md:54`, `:150`). A screen can read the *fixes*
  /// and the *zones*, but nothing captured says which zone a fix fell in, and
  /// computing it client-side would be a verdict the backend never made.
  static const String presenceLaneMissing =
      '`safe_zone_states` has no policy and no grant for `authenticated` '
      '(04-rls-matrix.md:54, :150) and no Edge Function that writes it is '
      'deployed, so in-or-out is not a captured fact';

  /// A refusal the screens carry as a fact about the board rather than as the
  /// answer to a call: no button on a location screen can ever succeed at this.
  static BlockedFailure get presenceGap => BlockedFailure(
    'Haven cannot say whether a device is inside a safe place in this build yet.',
    missing: presenceLaneMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $presenceLaneMissing',
  );
}
