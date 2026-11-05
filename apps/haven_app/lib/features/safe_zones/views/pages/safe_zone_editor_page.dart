import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/zone_editor_controller.dart';
import '../../data/safe_zone_rules.dart';
import '../widgets/zone_boundary_preview.dart';
import '../widgets/zone_child_selector.dart';
import '../widgets/zone_editor_widgets.dart';

/// Changing one place the family already named with boundary preview and duplicate check.
final class SafeZoneEditorPage extends GetView<SafeZoneEditorController> {
  const SafeZoneEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Change this place',
      body: HavenPageBody(
        child: Obx(
          () => StateView<SafeZone>(
            isLoading: controller.isLoading.value,
            result: controller.zone.value,
            onRetry: controller.load,
            onData: (BuildContext context, SafeZone zone) => _Form(zone),
          ),
        ),
      ),
    );
  }
}

class _Form extends GetView<SafeZoneEditorController> {
  const _Form(this.read);
  final SafeZone read;

  static const TextInputType _num = TextInputType.numberWithOptions(decimal: true, signed: true);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'What this place is',
          subtitle: 'Named for this family since ${read.createdAt.day}/${read.createdAt.month}/${read.createdAt.year}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HavenField(label: 'What to call it', controller: controller.name, maxLength: SafeZoneRules.nameMax),
              Obx(() => controller.duplicateWarning != null
                  ? Text(controller.duplicateWarning!, style: TextStyle(color: Theme.of(context).colorScheme.error))
                  : const ZoneFieldError('name')),
              HavenField(label: 'Latitude', controller: controller.lat, keyboardType: _num, helper: 'Between -90 and 90.'),
              const ZoneFieldError('lat'),
              HavenField(label: 'Longitude', controller: controller.lng, keyboardType: _num, helper: 'Between -180 and 180.'),
              const ZoneFieldError('lng'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: HavenField(
                      label: 'How wide, in metres',
                      controller: controller.radiusM,
                      keyboardType: _num,
                      helper: 'Between ${SafeZoneRules.radiusMin.toInt()} and ${SafeZoneRules.radiusMax.toInt()} m.',
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: '-50m', onPressed: () => controller.stepRadius(-50)),
                  IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: '+50m', onPressed: () => controller.stepRadius(50)),
                ],
              ),
              const ZoneFieldError('radius_m'),
              Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In use'),
                subtitle: const Text('A paused place is not evaluated.'),
                value: controller.active.value,
                onChanged: (next) => controller.active.value = next,
              )),
              Obx(() {
                controller.revision.value;
                final r = double.tryParse(controller.radiusM.text.trim()) ?? 150.0;
                final lat = double.tryParse(controller.lat.text.trim());
                final lng = double.tryParse(controller.lng.text.trim());
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: HavenSpacing.xs),
                  child: ZoneBoundaryPreviewCanvas(radiusM: r, lat: lat, lng: lng, onCoordinateSelected: controller.setCoordinates),
                );
              }),
              Obx(() => ZoneChildSelector(
                selectedChild: controller.associatedChild.value,
                options: const ['All Children'],
                onChanged: (c) => controller.associatedChild.value = c,
              )),
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HavenButton(
              label: 'Save the change',
              busy: controller.isSaving.value,
              onPressed: controller.canSave && controller.hasChanges ? controller.save : null,
            ),
            ZoneWriteResult(failure: controller.saveResult.value?.failureOrNull),
          ],
        )),
        const SizedBox(height: HavenSpacing.md),
        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HavenButton(label: 'Remove this place', primary: false, onPressed: () => _remove(context)),
            ZoneWriteResult(failure: controller.deleteResult.value?.failureOrNull),
          ],
        )),
      ],
    ),
  );

  Future<void> _remove(BuildContext context) async {
    final agreed = await ConfirmSheet.confirm(
      context,
      title: 'Remove this place?',
      body: 'The name, the position and the width of ${read.name} go away.',
      confirmLabel: 'Remove it',
      destructive: true,
    );
    if (agreed) await controller.delete();
  }
}
