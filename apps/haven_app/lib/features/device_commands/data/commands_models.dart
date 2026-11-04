import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `device_commands` row, said the way a parent can read it.
///
/// A row is a request addressed to a device and the answer it got back, if any.
/// Nothing here turns `delivered` into "the phone did it": only `acked_at` and
/// `status` carry that, and they say what the device reported, not what happened.
final class CommandLine {
  const CommandLine(this.command, {this.deviceName});

  final DeviceCommand command;

  /// The device row this instruction was addressed to, when one could be read.
  /// `device_commands` carries only a device id (F6).
  final String? deviceName;

  String get whose => deviceName ?? 'a device this build cannot name';

  /// `type` has a CHECK list and `CommandType` covers all of it, so an
  /// unrecognised value is a row that broke the constraint — echoed, not guessed.
  String get what =>
      command.commandType?.label ?? 'An instruction this build cannot name';

  String get statusLabel => command.commandStatus?.label ?? 'Unrecognised';

  /// The state of the row, and the most this build can conclude from it.
  ///
  /// `pending` and `delivered` describe a queue and a connection. `succeeded`
  /// and `failed` are what a device answered. `expired` is a deadline passing
  /// with no answer, which the captured `expire_stale_commands` RPC would have
  /// set — and this role cannot call it.
  String get state {
    final CommandStatus? status = command.commandStatus;
    final String word = switch (status) {
      CommandStatus.pending => 'Queued — no device has picked it up',
      CommandStatus.delivered => 'Sent — the device has not answered',
      CommandStatus.succeeded => 'The device answered that it is done',
      CommandStatus.failed => 'The device answered that it could not',
      CommandStatus.expired => 'Past its use-by time with no answer',
      null => 'Recorded in a state this build does not recognise',
    };
    if (status == null) return '$word (${command.status})';
    return word;
  }

  /// `created_at` is when the request was written. It is NOT NULL in the
  /// captured schema, so a row carries one; the stamp shown is the row's, not
  /// the moment this screen read it.
  String get when => 'written ${command.createdAt.toUtc().toIso8601String()}';

  /// `acked_at` is the only column that proves a device replied, so the answer
  /// time is shown separately from the state word instead of folded into it.
  String? get answered {
    final DateTime? acked = command.ackedAt;
    return acked == null ? null : 'answered ${acked.toUtc().toIso8601String()}';
  }

  /// `attempts` has a CHECK of `>= 0` and no documented meaning beyond a count,
  /// so it is echoed as a count.
  String? get tries =>
      command.attempts == 0 ? null : '${command.attempts} tries';

  /// `error_message` is capped at 500 characters and is the device's own words.
  String? get trouble => command.errorMessage;
}

/// What the instructions screen read, and the one thing it cannot do with them.
final class CommandBoard {
  const CommandBoard({
    required this.familyId,
    required this.lines,
    required this.writeGap,
    this.deviceGap,
    this.deviceId,
  });

  final String familyId;

  /// The device the read was narrowed to, or null for the whole family. The
  /// route argument fixes this (`docs/implementation/00-app-contract.md:160`).
  final String? deviceId;
  final List<CommandLine> lines;

  /// Sending, cancelling and answering all need a write this client does not
  /// hold. One failure, because it is one missing grant with three consequences.
  final BlockedFailure writeGap;

  /// The refusal that would otherwise name each row's device, or null when the
  /// device rows were readable.
  final BlockedFailure? deviceGap;

  bool get hasLines => lines.isNotEmpty;

  /// A page size, not a history. No captured retention rule covers
  /// `device_commands`, so this screen never claims to show every instruction.
  static const int window = 25;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? 'instruction' : 'instructions'} '
      'read — the newest $window rows the backend would give, for '
      '${deviceId == null ? 'this family' : 'one device'}.';

  /// Rows that came back answered, out of the rows actually read.
  int get answeredCount =>
      lines.where((CommandLine line) => line.command.isAcknowledged).length;

  String get answeredLine =>
      '$answeredCount of ${lines.length} carry an answer from a device.';
}
