import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `location_events` row, said the way a parent can act on it.
///
/// The row is a fix the device chose to report: an instant, a place, and how
/// wide the device says that place is. Nothing here turns those numbers into an
/// address, a place name or a live position, because no captured column carries
/// either of the first two and nothing captured makes the third true.
final class FixLine {
  const FixLine(this.fix, {this.deviceName});

  final LocationEvent fix;

  /// The device row this fix came from, when one could be read. `location_events`
  /// carries only a device id (F6).
  final String? deviceName;

  String get whose => deviceName ?? 'a device this build cannot name';

  /// The instant the device says it took the reading — not the instant Haven
  /// received it, which is a different column and a different claim.
  String get recorded =>
      'reported at ${fix.recordedAt.toUtc().toIso8601String()}';

  /// `received_at` is the second timestamp in the row, and the gap between the two
  /// is the only latency this build can state without inventing one.
  String get delay {
    final Duration lag = fix.receivedAt.difference(fix.recordedAt);
    if (lag.isNegative) {
      // A fix that arrives before it was taken is a data defect, not a story the
      // screen gets to smooth over.
      return 'the backend stamped this as received before it was reported';
    }
    if (lag.inSeconds < 60) return 'reached Haven within a minute';
    if (lag.inHours < 1) return 'reached Haven ${lag.inMinutes} minutes later';
    return 'reached Haven ${lag.inHours} h later';
  }

  /// The row's own accuracy, in metres. A zero is reported as absent rather than
  /// as "exact", which is the claim the column does not make.
  String get accuracy {
    if (fix.accuracyM <= 0) return 'the device reported no accuracy figure';
    final double metres = fix.accuracyM;
    return 'to within about '
        '${metres >= 1000 ? '${(metres / 1000).toStringAsFixed(1)} km' : '${metres.toStringAsFixed(0)} m'}';
  }

  /// The coordinates exactly as the row carries them. Hidden behind a deliberate
  /// reveal on the screen: readable, but not printed for anyone standing nearby.
  String get coordinates => '${fix.lat}, ${fix.lng}';

  /// `source` has no CHECK constraint, so it is echoed rather than interpreted
  /// (`docs/stage1/03-data-model.md`).
  String get source => 'as reported by ${fix.source}';
}

/// What the location screen read, and the two things it could not work out from
/// what it read.
final class FixBoard {
  const FixBoard({
    required this.familyId,
    required this.lines,
    required this.deviceGap,
    required this.presenceGap,
    this.deviceId,
  });

  final String familyId;

  /// The device the read was narrowed to, or null for the whole family. The route
  /// argument fixes this (`docs/implementation/00-app-contract.md:162`).
  final String? deviceId;
  final List<FixLine> lines;

  /// The refusal that would otherwise name each fix's device, or null when the
  /// device rows were readable.
  final BlockedFailure? deviceGap;

  /// Inside or outside a named place. Always present in this build:
  /// `safe_zone_states` is deny-all, so no client read answers it.
  final BlockedFailure presenceGap;

  bool get hasLines => lines.isNotEmpty;

  /// A page size, not a history. The retention window for precise location is an
  /// open question in `docs/stage1/03-data-model.md:69`, so this screen never says
  /// "every place" or a period it did not bound.
  static const int window = 20;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? 'reported place' : 'reported '
                'places'} read — the newest $window rows the backend would give, for '
      '${deviceId == null ? 'this family' : 'one device'}.';
}
