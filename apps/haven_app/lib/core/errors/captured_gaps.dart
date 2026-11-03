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

  static Result<void> deviceLaneUnavailable({String? subject}) => blocked(
    deviceLaneMissing,
    requirement: subject == null
        ? 'Haven cannot list paired devices in this build yet.'
        : 'Haven cannot show $subject devices here yet.',
  );
}
