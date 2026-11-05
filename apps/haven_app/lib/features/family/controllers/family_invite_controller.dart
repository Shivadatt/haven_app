import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../data/family_scope.dart';
import '../data/invitation_models.dart';

/// Manages co-parent and guardian invitations.
final class FamilyInviteController extends GetxController {
  FamilyInviteController({
    FamilyScopeReader Function()? scopeReader,
    RowReader Function()? rows,
    RowWriter Function()? writer,
  }) : _scope = scopeReader ?? (() => FamilyScopeReader(
         auth: () => HavenBackend.auth,
         rows: () => HavenBackend.rows,
       )),
       _rows = rows ?? (() => HavenBackend.rows),
       _writer = writer ?? (() => HavenBackend.writer);

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;

  final TextEditingController email = TextEditingController();
  final RxString selectedRole = 'co_parent'.obs;
  final RxnString emailError = RxnString();
  final RxnString formMessage = RxnString();
  final RxBool busy = false.obs;
  final RxBool isLoading = true.obs;

  final RxList<FamilyInvitation> pendingInvites = <FamilyInvitation>[].obs;
  final Rxn<FamilyInvitation> selectedInvite = Rxn<FamilyInvitation>();

  @override
  void onInit() {
    super.onInit();
    loadInvites();
  }

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }

  Future<void> loadInvites() async {
    isLoading.value = true;
    final Result<FamilyScope> scopeRes = await _scope().resolve();
    final FamilyScope? scope = scopeRes.valueOrNull;
    if (scope == null) {
      isLoading.value = false;
      return;
    }

    final Result<List<Map<String, Object?>>> membersRes = await _rows().rows(
      TableName.familyMembers,
      eq: {'family_id': scope.familyId, 'status': 'invited'},
    );
    final List<Map<String, Object?>> rows = membersRes.valueOrNull ?? [];
    final List<FamilyInvitation> list = [];

    for (final row in rows) {
      final String uid = row['user_id']?.toString() ?? '';
      Map<String, Object?>? prof;
      if (uid.isNotEmpty) {
        final pRes = await _rows().first(TableName.profiles, eq: {'id': uid});
        prof = pRes.valueOrNull;
      }
      list.add(FamilyInvitation.fromRow(memberRow: row, profileRow: prof));
    }

    pendingInvites.assignAll(list);
    isLoading.value = false;
  }

  Future<bool> sendInvite() async {
    final String? err = validateEmail(email.text);
    emailError.value = err;
    if (err != null) return false;

    busy.value = true;
    formMessage.value = null;
    final Result<FamilyScope> scopeRes = await _scope().resolve();
    final FamilyScope? scope = scopeRes.valueOrNull;
    if (scope == null) {
      busy.value = false;
      formMessage.value = 'Could not resolve family scope.';
      return false;
    }

    final String mail = email.text.trim().toLowerCase();
    final String now = DateTime.now().toUtc().toIso8601String();
    final String invitedUserId = LocalIds.create();

    await _writer().insert(TableName.profiles, <String, Object?>{
      'id': invitedUserId,
      'email': mail,
      'role': 'parent',
      'display_name': 'Invited ${selectedRole.value} ($mail)',
      'created_at': now,
      'updated_at': now,
    });

    final Result<void> result = await _writer().insert(
      TableName.familyMembers,
      <String, Object?>{
        'id': LocalIds.create(),
        'family_id': scope.familyId,
        'user_id': invitedUserId,
        'role': selectedRole.value,
        'status': 'invited',
        'created_at': now,
      },
    );

    busy.value = false;
    if (result.isOk) {
      email.clear();
      formMessage.value = 'Invitation saved for $mail.';
      await loadInvites();
      return true;
    }
    formMessage.value = 'Failed to create invitation record.';
    return false;
  }

  Future<bool> cancelInvite(String inviteId) async {
    busy.value = true;
    final Result<void> del = await _writer().delete(
      TableName.familyMembers,
      eq: {'id': inviteId},
    );
    busy.value = false;
    if (del.isOk) {
      selectedInvite.value = null;
      await loadInvites();
      return true;
    }
    return false;
  }

  void selectInvite(FamilyInvitation invite) => selectedInvite.value = invite;
}
