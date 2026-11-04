import 'dart:async';

import 'package:haven_api/haven_api.dart';

/// The Realtime hint lane, so a test can say "the backend told this screen to
/// read again" without a socket.
///
/// A feed is a hint and never a row (`docs/stage1/02-architecture.md:23`), so
/// this emits plain maps and the assertions are about what the controller does in
/// response — re-read — not about what it shows.
class FakeChangeFeed implements ChangeFeed {
  final List<String> watchedTables = [];
  final List<Map<String, Object?>> filters = [];
  int disposeCount = 0;

  final Map<String, StreamController<Map<String, Object?>>> _channels = {};

  @override
  Stream<Map<String, Object?>> changes({
    required String table,
    Map<String, Object?> eq = const {},
  }) {
    TableName.assertKnown(table);
    watchedTables.add(table);
    filters.add(eq);
    return _channel(table).stream;
  }

  /// Says "something changed in this table", the way a captured event does.
  void emit(String table, [Map<String, Object?>? row]) {
    final StreamController<Map<String, Object?>>? channel = _channelOrNull(
      table,
    );
    if (channel == null || channel.isClosed) return;
    channel.add(row ?? <String, Object?>{'table': table});
  }

  @override
  void dispose() {
    disposeCount++;
    for (final StreamController<Map<String, Object?>> channel
        in _channels.values) {
      channel.close();
    }
    _channels.clear();
  }

  StreamController<Map<String, Object?>> _channel(String table) =>
      _channelOrNull(table) ??
      (_channels[table] = StreamController<Map<String, Object?>>.broadcast());

  StreamController<Map<String, Object?>>? _channelOrNull(String table) =>
      _channels[table];
}
