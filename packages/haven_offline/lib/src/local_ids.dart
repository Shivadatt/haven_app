import 'dart:math';

/// Local row identifiers for the offline persistence core.
///
/// The offline store has no database server to generate primary keys, so ids are
/// minted here. They are random rather than sequential: a child's device id or a
/// safe-zone id must not leak "how many rows exist" and two installations that
/// later sync must not collide.
///
/// `Random.secure()` is used deliberately — a predictable id in a parenting app
/// is a guessable identifier for a family. It has no new dependency and no
/// platform plugin; if the platform offers no cryptographic source the generator
/// fails loudly at the call site instead of silently degrading to a seeded RNG.
abstract final class LocalIds {
  /// Shared generator; `Random.secure()` re-seeds per instance, so one handle is
  /// enough and cheaper.
  static final Random _random = Random.secure();

  /// Default 12 bytes (24 hex chars): well past the birthday bound for the row
  /// counts this app reaches, and short enough to read in a log line.
  static const int defaultBytes = 12;

  /// New hex id. Prefix it at the call site when a table wants a readable key
  /// (`'sz_' + LocalIds.create()`).
  static String create({int bytes = defaultBytes}) {
    if (bytes < 4) {
      throw ArgumentError.value(bytes, 'bytes', 'id entropy is too small');
    }
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// [create] repeated until no candidate is in [taken] and no candidate
  /// duplicates another, so a batch insert can mint its whole key set in one go.
  static List<String> createMany(int count, {Set<String> taken = const {}}) {
    final result = <String>[];
    final chosen = <String>{...taken};
    while (result.length < count) {
      final candidate = create();
      if (chosen.add(candidate)) result.add(candidate);
    }
    return result;
  }
}
