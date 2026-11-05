import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_scaffold.dart';
import '../../controllers/extension_requests_controller.dart';
import '../widgets/extension_request_card.dart';

class ExtensionRequestsPage extends GetView<ExtensionRequestsController> {
  const ExtensionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Screen-Time Requests',
      onRefresh: controller.load,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Add Sample Request',
          onPressed: controller.generateSample,
        ),
      ],
      body: HavenPageBody(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = controller.displayedRequests;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HavenSpacing.sm),
              _TabSelector(controller: controller),
              const SizedBox(height: HavenSpacing.md),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      controller.currentTab.value == 0
                          ? 'No pending screen-time extension requests.'
                          : 'No extension history.',
                      style: HavenText.caption,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: HavenSpacing.xl),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: HavenSpacing.md),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ExtensionRequestCard(
                        request: item,
                        onApprove: (granted, note) => controller.approve(
                          item.id,
                          grantedMinutes: granted,
                          note: note,
                        ),
                        onReject: (note) =>
                            controller.reject(item.id, note: note),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.controller});
  final ExtensionRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.currentTab.value;
      return SegmentedButton<int>(
        segments: [
          ButtonSegment(
            value: 0,
            label: Text('Pending (${controller.pendingRequests.length})'),
          ),
          ButtonSegment(
            value: 1,
            label: Text('History (${controller.historyRequests.length})'),
          ),
        ],
        selected: {tab},
        onSelectionChanged: (selected) {
          controller.currentTab.value = selected.first;
        },
      );
    });
  }
}
