import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/account_controller.dart';
import '../../data/account_repository.dart';
import '../widgets/account_identity_card.dart';
import '../widgets/account_limits_card.dart';
import '../widgets/account_name_card.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccountIdentityCard(info),
          const SizedBox(height: HavenSpacing.md),
          if (info.hasProfile)
            const AccountNameCard()
          else
            const AccountNeedsSetupCard(),
          const SizedBox(height: HavenSpacing.md),
          const AccountLimitsCard(),
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
