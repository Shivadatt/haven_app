import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../../../../shared/components/state_view.dart';
import '../../../../shared/components/status_chip.dart';
import '../../controllers/permissions_controller.dart';
import '../widgets/permission_card.dart';

/// `/permissions` — the permission dashboard (brief §4 E). Explanatory only:
/// Stage 1 requests nothing and reads nothing, and every card says so with
/// the same refusal vocabulary the rest of the product uses.
final class PermissionsPage extends GetView<PermissionsController> {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'Permissions',
      body: ChildPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ChildSpacing.md),
            const ChildStatusChip(
              key: ValueKey('permissions-none-requested'),
              label: 'No permission has been requested.',
              tone: StatusTone.neutral,
            ),
            const SizedBox(height: ChildSpacing.md),
            const Text(
              'Nothing is monitored yet. The list below explains what each '
              'capability will do once it exists — the actions stay off '
              'until the device support for them is real.',
              style: ChildText.body,
            ),
            Expanded(
              child: Obx(
                () => ChildStateView<List<PermissionCardState>>(
                  isLoading: controller.isLoading.value,
                  errorMessage: controller.errorMessage.value,
                  data: controller.cards.toList(),
                  emptyMessage: 'The capability list is empty.',
                  onRetry: controller.load,
                  onData: (context, items) => _CardList(items: items),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.items});

  final List<PermissionCardState> items;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: ChildSpacing.sm),
    children: [
      for (final item in items) PermissionCard(state: item, key: ValueKey(item.permission.wire)),
    ],
  );
}
