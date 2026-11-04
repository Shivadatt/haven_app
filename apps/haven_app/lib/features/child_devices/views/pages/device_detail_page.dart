import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show BlockedFailure, HavenFailure;
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../telemetry/views/widgets/trail_card.dart';
import '../../controllers/device_detail_controller.dart';
import '../widgets/device_list_card.dart';

/// One device, as much of it as this build can see.
///
/// The record read and the two actions are stated separately: not being able to
/// list devices, not being able to revoke one and not being able to ask it to
/// re-check its rules are three different missing grants, and collapsing them
/// into one message would hide which one an owner has to settle.
final class DeviceDetailPage extends GetView<DeviceDetailController> {
  const DeviceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Device',
      body: HavenPageBody(
        // No Obx here: `hasDeviceId` is fixed when the route is built, and the
        // cards below each observe the state they actually render.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!controller.hasDeviceId)
                const _NoDeviceNamed()
              else ...[
                const _RecordCard(),
                const SizedBox(height: HavenSpacing.md),
                const _ReportsCard(),
                const SizedBox(height: HavenSpacing.md),
                const TelemetryCard(),
                const SizedBox(height: HavenSpacing.md),
                const _ActionsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends GetView<DeviceDetailController> {
  const _RecordCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What this device is',
    child: Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(HavenSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final HavenFailure? failure = controller.device.value?.failureOrNull;
      if (failure is BlockedFailure) return BlockedNotice.fromFailure(failure);
      if (failure != null) return _Retry(failure: failure);
      final Device? read = controller.device.value?.valueOrNull;
      if (read == null) {
        return const Text('The backend returned no device for this id.');
      }
      return DeviceRow(read);
    }),
  );
}

class _Retry extends GetView<DeviceDetailController> {
  const _Retry({required this.failure});

  final HavenFailure failure;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(failure.message, style: HavenText.body),
      if (failure.retryable) ...[
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Try again', onPressed: controller.load),
      ],
    ],
  );
}

/// The four reads that work for this device id even while its own row does not.
class _ReportsCard extends GetView<DeviceDetailController> {
  const _ReportsCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What the backend holds for this device',
    subtitle:
        'Each screen reads rows addressed to this device\'s id, and each read '
        'works while the device row itself does not.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HavenButton(
          label: 'App use it reported',
          primary: false,
          onPressed: controller.goToActivity,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Places it reported',
          primary: false,
          onPressed: controller.goToLocation,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Instructions addressed to it',
          primary: false,
          onPressed: controller.goToCommands,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Rule versions written for it',
          primary: false,
          onPressed: controller.goToPolicies,
        ),
      ],
    ),
  );
}

/// Revoking and recovery, both refused, with the grant each one is waiting on.
class _ActionsCard extends GetView<DeviceDetailController> {
  const _ActionsCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you could do with it',
    subtitle:
        'Taking a device out of Haven, or asking it to re-check its rules.',
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.revokeGap.value != null) ...[
            BlockedNotice.fromFailure(controller.revokeGap.value!),
            const SizedBox(height: HavenSpacing.sm),
          ],
          if (controller.recoveryGap.value != null)
            BlockedNotice.fromFailure(controller.recoveryGap.value!),
        ],
      ),
    ),
  );
}

/// The route was opened without a device named, which only happens from a stale
/// or hand-built link — there is no list to tap one out of yet.
class _NoDeviceNamed extends GetView<DeviceDetailController> {
  const _NoDeviceNamed();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'No device was named',
    child: Text(
      'Haven will not guess which device this screen was opened for. Open '
      'Devices and pick one from the list.',
      style: HavenText.body,
    ),
  );
}
