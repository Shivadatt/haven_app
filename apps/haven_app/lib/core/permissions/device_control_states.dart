/// The location answers, exactly as the phone gave them.
///
/// The admin and media answers sit beside them in `admin_and_media_states.dart`; the
/// split is the 200-line rule, not a difference in kind.
library;

/// The newest fix the phone's location service is still holding.
///
/// There are no coordinates in this type. The native lane answers "could a location
/// be reported, and how fresh is what the phone already has", and a position is not
/// part of that answer — so it never crosses the channel to a settings screen.
final class LastFix {
  const LastFix({
    required this.provider,
    required this.accuracyMetres,
    required this.age,
    required this.hasAltitude,
    required this.fromMockProvider,
  });

  final String provider;

  /// The OS's own accuracy figure in metres. Never rounded, guessed or widened.
  final double accuracyMetres;

  /// How old the fix is, or `null` when the phone could not say.
  final Duration? age;

  final bool hasAltitude;

  /// `null` when this Android version does not flag mock locations.
  final bool? fromMockProvider;
}

/// Whether this phone's location lane could report anything.
final class LocationStates {
  const LocationStates({
    required this.serviceAvailable,
    required this.gpsOn,
    required this.networkOn,
    required this.passiveOn,
    required this.mayAsk,
    required this.lastFix,
    required this.withheldBecause,
  });

  final bool serviceAvailable;

  /// `null` when the OS would not say whether that provider is switched on.
  final bool? gpsOn;
  final bool? networkOn;
  final bool? passiveOn;

  final bool? mayAsk;
  final LastFix? lastFix;

  /// Why no fix came back, when the phone gave a reason — `permission` today.
  final String? withheldBecause;

  List<String> get providersOn =>
      <String, bool?>{'gps': gpsOn, 'network': networkOn, 'passive': passiveOn}
          .entries
          .where((MapEntry<String, bool?> e) => e.value == true)
          .map((e) => e.key)
          .toList();

  /// The newest fix this phone is holding, in the phone's own accuracy.
  ///
  /// A fix from an hour ago is said out loud rather than shown as though it were
  /// current, and no row is invented to fill the space when the phone has none.
  String get fixLine {
    if (!serviceAvailable) return 'This phone has no location service to ask.';
    final LastFix? fix = lastFix;
    if (fix == null) {
      return withheldBecause == 'permission'
          ? 'The phone holds no fix, and this build is not allowed to ask for one.'
          : 'The phone is holding no fix right now.';
    }
    final String age = fix.age == null ? 'an unknown age' : _humanAge(fix.age!);
    final String mock = fix.fromMockProvider == true
        ? ', flagged as a mock location'
        : '';
    return 'Newest fix the phone is holding: $age old, from ${fix.provider}, '
        'accurate to ${fix.accuracyMetres.toStringAsFixed(0)} m$mock.';
  }

  static String _humanAge(Duration age) {
    if (age.inMinutes < 1) return 'less than a minute';
    final int value;
    final String unit;
    if (age.inHours < 1) {
      value = age.inMinutes;
      unit = 'minute';
    } else if (age.inDays < 1) {
      value = age.inHours;
      unit = 'hour';
    } else {
      value = age.inDays;
      unit = 'day';
    }
    return '$value $unit${value == 1 ? '' : 's'}';
  }
}
