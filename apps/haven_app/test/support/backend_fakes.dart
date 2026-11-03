import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

/// Fakes for the data-plane seams (`haven_api` contracts). Hand-written, because
/// the point is that a feature answers to the contract, not to an SDK.
///
/// The re-authored functions answer `{ok:true, ...fields}` and
/// `{ok:false, error:{code,message}}`, so the replies below look like that.
class FakeEdgeCaller implements EdgeCaller {
  FakeEdgeCaller({this.reply});

  /// What the next `invoke` resolves to. Null means "accepted, nothing to say".
  Result<EdgeReply>? reply;

  final List<String> slugs = [];
  final List<Map<String, Object?>> bodies = [];

  String? get lastSlug => slugs.isEmpty ? null : slugs.last;
  Map<String, Object?>? get lastBody => bodies.isEmpty ? null : bodies.last;

  @override
  Future<Result<EdgeReply>> invoke(
    String slug,
    Map<String, Object?> body, {
    Map<String, String> deviceHeaders = const {},
  }) async {
    slugs.add(slug);
    bodies.add(body);
    return reply ??
        const Ok<EdgeReply>(EdgeReply(status: 200, body: {'ok': true}));
  }
}

/// A successful `{ok:true, ...}` reply.
Ok<EdgeReply> accepted([Map<String, Object?> fields = const {}]) =>
    Ok<EdgeReply>(EdgeReply(status: 200, body: {'ok': true, ...fields}));

/// A refusal in the shape the re-authored envelope produces, with `error.code`
/// and `error.message` — the two paths the evidence actually verifies.
Ok<EdgeReply> refused(int status, String code, String message) => Ok<EdgeReply>(
  EdgeReply(
    status: status,
    errorCode: code,
    body: {
      'ok': false,
      'error': {'code': code, 'message': message},
    },
  ),
);

class FakeRpcCaller implements RpcCaller {
  FakeRpcCaller({this.payload, this.failWith});

  Object? payload;
  HavenFailure? failWith;

  final List<String> names = [];
  final List<Map<String, Object?>> params = [];

  String? get lastName => names.isEmpty ? null : names.last;
  Map<String, Object?>? get lastParams => params.isEmpty ? null : params.last;

  @override
  Future<Result<Object?>> call(String name, Map<String, Object?> p) async {
    names.add(name);
    params.add(p);
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<Object?>(failure);
    return Ok<Object?>(payload);
  }
}

/// A push transport whose permission answer is whatever the test says, because
/// the settings screen is under test, not Firebase Messaging.
class FakePushTransport implements PushTransport {
  FakePushTransport({this.isGranted = false, this.promptAnswer});

  bool isGranted;

  /// Counted, so a test can prove the screen did not ask the OS when this build
  /// has no push backend to ask for.
  int grantedReads = 0;

  /// Null means the OS did not answer this way — a real prompt can do that.
  bool? promptAnswer;
  int requestCount = 0;

  @override
  Future<bool> get granted async {
    grantedReads++;
    return isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    final bool answer = promptAnswer ?? false;
    isGranted = answer;
    return answer;
  }

  @override
  Future<Result<String?>> registrationTarget() async =>
      blocked('fake: no token registration');

  @override
  Future<Result<void>> clearRegistration() async =>
      blocked('fake: no token registration');

  @override
  Stream<String> get registrationChanges => const Stream<String>.empty();

  @override
  Stream<Map<String, Object?>> get taps =>
      const Stream<Map<String, Object?>>.empty();

  @override
  Stream<Map<String, Object?>> get foregroundMessages =>
      const Stream<Map<String, Object?>>.empty();
}

/// Rows from the 19 captured tables, filtered exactly the way the real reader
/// filters them: every `eq` pair has to match, `orderDesc` orders, `limit` caps.
class FakeRowReader implements RowReader {
  FakeRowReader([Map<String, List<Map<String, Object?>>>? tables])
    : tables = tables ?? <String, List<Map<String, Object?>>>{};

  /// `table -> rows`. A table with no key answers with no rows, which is what an
  /// empty result looks like, not what a failure looks like.
  final Map<String, List<Map<String, Object?>>> tables;
  HavenFailure? failWith;

  final List<String> readTables = [];
  final List<Map<String, Object?>> filters = [];
  final List<String?> orderings = [];
  final List<int?> limits = [];

  String? get lastTable => readTables.isEmpty ? null : readTables.last;

  @override
  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) async {
    TableName.assertKnown(table);
    readTables.add(table);
    filters.add(eq);
    orderings.add(orderDesc);
    limits.add(limit);
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<List<Map<String, Object?>>>(failure);

    final List<Map<String, Object?>> matched =
        (tables[table] ?? const <Map<String, Object?>>[])
            .where((row) => eq.entries.every((e) => row[e.key] == e.value))
            .toList();
    if (orderDesc != null) {
      matched.sort(
        (a, b) => _desc(a[orderDesc]).compareTo(_desc(b[orderDesc])),
      );
    }
    return Ok<List<Map<String, Object?>>>(
      limit != null && matched.length > limit
          ? matched.sublist(0, limit)
          : matched,
    );
  }

  @override
  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  }) async {
    final Result<List<Map<String, Object?>>> all = await rows(
      table,
      eq: eq,
      orderDesc: orderDesc,
      limit: 1,
    );
    final List<Map<String, Object?>>? value = all.valueOrNull;
    if (value == null) return Err<Map<String, Object?>?>(all.failureOrNull!);
    return Ok<Map<String, Object?>?>(value.isEmpty ? null : value.first);
  }

  @override
  Future<Result<int>> count(
    String table, {
    Map<String, Object?> eq = const {},
  }) async {
    final Result<List<Map<String, Object?>>> all = await rows(table, eq: eq);
    final List<Map<String, Object?>>? value = all.valueOrNull;
    if (value == null) return Err<int>(all.failureOrNull!);
    return Ok<int>(value.length);
  }

  /// Column order needs a comparison; timestamps are stored as ISO text in the
  /// fixtures, which sorts the same way as the instant itself.
  static Comparable<Object> _desc(Object? v) =>
      v is Comparable<Object> ? v : '';
}

/// Writes recorded, never applied — the fake has no rows to change.
class FakeRowWriter implements RowWriter {
  FakeRowWriter({this.failWith});

  HavenFailure? failWith;
  final List<String> writtenTables = [];
  final List<Map<String, Object?>> payloads = [];
  final List<Map<String, Object?>> matchers = [];

  Map<String, Object?>? get lastPayload =>
      payloads.isEmpty ? null : payloads.last;

  @override
  Future<Result<void>> insert(String table, Map<String, Object?> row) async {
    TableName.assertKnown(table);
    writtenTables.add(table);
    payloads.add(row);
    final HavenFailure? failure = failWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> update(
    String table,
    Map<String, Object?> row, {
    required Map<String, Object?> eq,
  }) async {
    TableName.assertKnown(table);
    writtenTables.add(table);
    payloads.add(row);
    matchers.add(eq);
    final HavenFailure? failure = failWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }
}
