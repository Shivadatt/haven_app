import 'dart:async';

import 'package:haven_models/haven_models.dart' show asMap;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_endpoints.dart';
import 'data_contracts.dart';

/// `ChangeFeed` over Supabase Realtime postgres_changes.
///
/// Realtime is a fast path, not a delivery guarantee
/// (`docs/stage1/02-architecture.md:23`): an event only says "something
/// changed, re-read this". A missed event is therefore recoverable, and nothing
/// in the app treats a stream frame as the row itself.
///
/// Only the four tables the baseline publishes are accepted.
final class SupabaseChangeFeed implements ChangeFeed {
  SupabaseChangeFeed(this._client);

  final SupabaseClient _client;

  static const subscribedTables = [
    TableName.deviceCommands,
    TableName.remoteSessions,
    TableName.safetyAlerts,
    TableName.webrtcSignals,
  ];

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Map<String, Object?>>> _controllers = {};
  bool _disposed = false;

  @override
  Stream<Map<String, Object?>> changes({
    required String table,
    Map<String, Object?> eq = const {},
  }) {
    if (!subscribedTables.contains(table)) {
      throw ArgumentError.value(
        table,
        'table',
        'Realtime is published for only four tables',
      );
    }
    if (_disposed) return const Stream<Map<String, Object?>>.empty();
    final key = _key(table, eq);
    final controller = _controllers[key] ?? _open(table, eq, key);
    return controller.stream;
  }

  StreamController<Map<String, Object?>> _open(
    String table,
    Map<String, Object?> eq,
    String key,
  ) {
    final controller = StreamController<Map<String, Object?>>.broadcast();
    _controllers[key] = controller;
    final filter = eq.entries.isEmpty
        ? null
        : PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: eq.keys.first,
            value: eq.values.first,
          );
    final channel = _client.channel('haven:$table:$key')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: filter,
        callback: (payload) => controller.add(asMap(payload)),
      )
      ..subscribe();
    _channels[key] = channel;
    return controller;
  }

  /// One equality filter per subscription: a compound filter would silently
  /// widen or narrow what RLS already scopes.
  void _close(String key) {
    final controller = _controllers.remove(key);
    final channel = _channels.remove(key);
    if (channel != null) unawaited(_client.removeChannel(channel));
    unawaited(controller?.close());
  }

  static String _key(String table, Map<String, Object?> eq) =>
      '$table|${eq.entries.map((e) => '${e.key}=${e.value}').join(',')}';

  /// Called from `onClose` of any controller that owns a subscription.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final key in _channels.keys.toList()) {
      _close(key);
    }
    _controllers.clear();
  }
}
