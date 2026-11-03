import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show BlockedFailure;
import 'package:haven_models/haven_models.dart' show ProfileRole;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/account_controller.dart';
import '../../data/account_repository.dart';

/// Who is signed in, the name Haven shows for them, and the way out.
final class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Your account',
      body: HavenPageBody(
        child: Obx(
          () => StateView<AccountInfo>(
            isLoading: controller.isLoading.value,
            result: controller.account.value,
            onRetry: controller.load,
            onData: (BuildContext context, AccountInfo info) => _Content(info),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<AccountController> {
  const _Content(this.info);

  final AccountInfo info;

  @override
  Widget build(BuildContext context) {
    // A Column, not a ListView: this page has five sections, and a lazily built
    // scroll view is a section that quietly does not exist until it is on
    // screen — which is also why a test can never find the bottom of the page.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Identity(info),
          const SizedBox(height: HavenSpacing.md),
          if (info.hasProfile) _NameCard() else _NeedsSetup(),
          const SizedBox(height: HavenSpacing.md),
          const _LimitsCard(),
          const SizedBox(height: HavenSpacing.lg),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.message.value != null) ...[
                  Text(controller.message.value!, style: HavenText.body),
                  const SizedBox(height: HavenSpacing.sm),
                ],
                HavenButton(
                  label: 'Sign out',
                  primary: false,
                  expand: true,
                  busy: controller.busy.value,
                  onPressed: () => _confirmSignOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool yes = await ConfirmSheet.confirm(
      context,
      title: 'Sign out of Haven?',
      body:
          'Your family and devices stay set up. You will need this email '
          'address and password to come back in.',
      confirmLabel: 'Sign out',
    );
    if (yes) controller.signOut();
  }
}

/// The session facts, read-only: an account screen that lets a parent edit
/// something the backend cannot accept would be a fake control.
class _Identity extends StatelessWidget {
  const _Identity(this.info);

  final AccountInfo info;

  @override
  Widget build(BuildContext context) {
    final ProfileRole? role = info.role;
    return SectionCard(
      title: 'Signed in as',
      subtitle: info.email ?? 'This session has no email on file.',
      trailing: StatusChip(
        label: role?.label ?? 'Role not set',
        tone: switch (role) {
          ProfileRole.parent => StatusTone.good,
          ProfileRole.child => StatusTone.warning,
          ProfileRole.unset || null => StatusTone.neutral,
        },
      ),
      child: Text(
        'Only a parent account can set up a family. Haven does not change this '
        'role from the app — it is set once, by the service, when you confirm '
        'you are the child’s parent or guardian.',
        style: HavenText.body,
      ),
    );
  }
}

class _NameCard extends GetView<AccountController> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Name shown to your family',
      subtitle: 'This is what your children’s devices see.',
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HavenField(
              label: 'Your name',
              controller: controller.displayName,
              maxLength: 60,
              enabled: !controller.busy.value,
            ),
            const SizedBox(height: HavenSpacing.md),
            HavenButton(
              label: 'Save name',
              busy: controller.busy.value,
              onPressed: controller.canSave ? controller.save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The provisioning gap, stated as the gap rather than as an error the parent
/// caused: the row that would hold a name has no approved way to be created.
class _NeedsSetup extends GetView<AccountController> {
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven has no record for this account yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signing up does not create the account record on its own, so there '
          'is no name to show or change until setup runs.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Set up Haven', onPressed: controller.goToSetup),
      ],
    ),
  );
}

class _LimitsCard extends GetView<AccountController> {
  const _LimitsCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Not available in Haven yet',
    subtitle: 'These need a backend contract nobody has approved.',
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _notice(controller.passwordChange.value),
          _notice(controller.emailChange.value),
          _notice(controller.accountDeletion.value),
        ],
      ),
    ),
  );

  static Widget _notice(BlockedFailure? failure) => failure == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
          child: BlockedNotice.fromFailure(failure),
        );
}
