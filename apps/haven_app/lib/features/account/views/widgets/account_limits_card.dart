import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show BlockedFailure;

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/account_controller.dart';

/// Explains operations with no backend support yet rather than showing dead controls.
final class AccountLimitsCard extends GetView<AccountController> {
  const AccountLimitsCard({super.key});

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
