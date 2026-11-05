import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/zone_create_controller.dart';
import '../../data/safe_zone_rules.dart';
import '../widgets/zone_boundary_preview.dart';
import '../widgets/zone_child_selector.dart';
import '../widgets/zone_editor_widgets.dart';

/// Form to create a new safe zone with boundary preview and child selector.
final class SafeZoneCreatePage extends GetView<SafeZoneCreateController> {
  const SafeZoneCreatePage({super.key});

  static const TextInputType _number = TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  );

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Add a safe place',
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Safe Place Details',
                subtitle: 'Name a place where your child spends time.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HavenField(
                      label: 'Place Name',
                      controller: controller.name,
                      maxLength: SafeZoneRules.nameMax,
                      helper: 'e.g. Home, School, Park',
                    ),
                    Obx(() => _Error(controller.duplicateWarning ?? controller.errors['name'])),
                    HavenField(
                      label: 'Latitude',
                      controller: controller.lat,
                      keyboardType: _number,
                      helper: 'Between -90 and 90',
                    ),
                    Obx(() => _Error(controller.errors['lat'])),
                    HavenField(
                      label: 'Longitude',
                      controller: controller.lng,
                      keyboardType: _number,
                      helper: 'Between -180 and 180',
                    ),
                    Obx(() => _Error(controller.errors['lng'])),
                    const SizedBox(height: HavenSpacing.md),
                    _RadiusSelector(controller: controller),
                    Obx(() => _Error(controller.errors['radius_m'])),
                    Obx(() {
                      final double r = controller.radiusM.value;
                      final double? curLat = double.tryParse(controller.lat.text.trim());
                      final double? curLng = double.tryParse(controller.lng.text.trim());
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: HavenSpacing.xs),
                        child: ZoneBoundaryPreviewCanvas(
                          radiusM: r,
                          lat: curLat,
                          lng: curLng,
                          onCoordinateSelected: controller.setCoordinates,
                        ),
                      );
                    }),
                    Obx(
                      () => ZoneChildSelector(
                        selectedChild: controller.associatedChild.value,
                        options: controller.availableChildren,
                        onChanged: (c) => controller.associatedChild.value = c,
                      ),
                    ),
                    const SizedBox(height: HavenSpacing.sm),
                    Obx(
                      () => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('In use'),
                        subtitle: const Text('Evaluate presence for this place'),
                        value: controller.active.value,
                        onChanged: (val) => controller.active.value = val,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HavenSpacing.md),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HavenButton(
                      label: 'Create safe place',
                      busy: controller.isSaving.value,
                      onPressed: controller.canCreate
                          ? controller.createZone
                          : null,
                    ),
                    ZoneWriteResult(
                      failure: controller.saveResult.value?.failureOrNull,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  const _RadiusSelector({required this.controller});
  final SafeZoneCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final double r = controller.radiusM.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Radius: ${r.round()} m'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Decrease 50m',
                    onPressed: () => controller.stepRadius(-50),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Increase 50m',
                    onPressed: () => controller.stepRadius(50),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            min: SafeZoneRules.radiusMin,
            max: SafeZoneRules.radiusMax,
            divisions: 99,
            value: r,
            label: '${r.round()} m',
            onChanged: controller.setRadius,
          ),
        ],
      );
    });
  }
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
      child: Text(
        message!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
