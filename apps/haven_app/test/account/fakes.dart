import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/account/data/account_repository.dart';

/// The account screen's answers, driven by the test.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.info});

  AccountInfo? info;
  HavenFailure? loadFailWith;
  HavenFailure? renameFailWith;
  HavenFailure? signOutFailWith;

  /// What the three abilities without an approved contract answer. A real
  /// repository returns a [BlockedFailure]; a test can put anything here.
  HavenFailure? blockedWith;

  final List<String> calls = [];
  String? lastDisplayName;

  @override
  Future<Result<AccountInfo>> load() async {
    calls.add('load');
    final HavenFailure? failure = loadFailWith;
    if (failure != null) return Err<AccountInfo>(failure);
    final AccountInfo? value = info;
    return value == null
        ? const Err<AccountInfo>(
            AuthFailure('You are not signed in.', signedOut: true),
          )
        : Ok<AccountInfo>(value);
  }

  @override
  Future<Result<void>> rename({required String displayName}) async {
    calls.add('rename');
    lastDisplayName = displayName;
    final HavenFailure? failure = renameFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    final HavenFailure? failure = signOutFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> passwordChange() async => _blocked('password change');

  @override
  Future<Result<void>> emailChange() async => _blocked('email change');

  @override
  Future<Result<void>> accountDeletion() async => _blocked('account deletion');

  Future<Result<void>> _blocked(String what) async => blockedWith == null
      ? blocked<void>('fake: no contract for $what')
      : Err<void>(blockedWith!);
}
