import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'family_models.dart';
import 'family_repository.dart';
import 'family_scope.dart';
import 'local_family_mutations.dart';

/// Offline family management over LocalTables.
final class LocalFamilyRepository implements FamilyRepository {
  LocalFamilyRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
  }) : _base = HavenFamilyRepository(
         scope: scope,
         rows: rows,
         writer: writer,
       ),
       _mutations = LocalFamilyMutations(
         scope: scope,
         writer: writer,
       );

  final HavenFamilyRepository _base;
  final LocalFamilyMutations _mutations;

  factory LocalFamilyRepository.live() {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return LocalFamilyRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
    );
  }

  @override
  Future<Result<FamilyBundle?>> load() => _base.load();

  @override
  Future<Result<void>> rename({required String name}) =>
      _base.rename(name: name);

  @override
  Future<Result<void>> createFamily({required String name}) =>
      _mutations.createFamily(name: name);

  @override
  Future<Result<FamilyPerson>> addChild({
    required String name,
    String? ageBracket,
    String? avatar,
  }) => _mutations.addChild(
    name: name,
    ageBracket: ageBracket,
    avatar: avatar,
  );

  @override
  Future<Result<void>> updateChild({
    required String childUserId,
    required String name,
    String? ageBracket,
    String? avatar,
  }) => _mutations.updateChild(
    childUserId: childUserId,
    name: name,
    ageBracket: ageBracket,
    avatar: avatar,
  );

  @override
  Future<Result<void>> unlinkChild(
    String childUserId, {
    bool execute = false,
  }) => _mutations.unlinkChild(childUserId, execute: execute);

  @override
  Future<Result<void>> inviteParent() => _base.inviteParent();

  @override
  Future<Result<void>> removeParent() => _base.removeParent();
}
