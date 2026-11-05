import 'dart:async';

import '../data_contracts.dart';
import 'local_queries.dart';

/// Change notifications for the offline tables.
///
/// The online feed delivers a row per Realtime event; there is no server here, so
/// a write publishes a hint that carries the table name plus the filter (or the
/// inserted row). The contract already says the payload is a hint and the caller
/// re-reads — offline that is the whole mechanism, and it is why no subscription
/// can miss a change the way a dropped socket could.
final class LocalChangeFeed implements ChangeFeed {
  final StreamController<Map<String, Object?>> _controller =
      StreamController<Map<String, Object?>>.broadcast();

  /// Table marker on published hints. Prefixed so no captured column shadows it,
  /// and `fromRow` readers ignore keys they do not know.
  static const String tableKey = '_local_table';

  /// Called by the offline writer after a mutation succeeded. Never throws: a
  /// closed feed means the app is tearing down, and the write already landed.
  void publish(String table, Map<String, Object?> hint) {
    if (_controller.isClosed) return;
    _controller.add(<String, Object?>{...hint, tableKey: table});
  }

  @override
  Stream<Map<String, Object?>> changes({
    required String table,
    Map<String, Object?> eq = const {},
  }) => _controller.stream.where(
    (hint) => hint[tableKey] == table && LocalQueries.matches(hint, eq),
  );

  @override
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
