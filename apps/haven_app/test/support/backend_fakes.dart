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
