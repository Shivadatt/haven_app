import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/location_controller.dart';

/// Info panel showing selected safe-zone details and Haversine distance.
class SelectedZoneInfoPanel extends GetView<LocationController> {
  const SelectedZoneInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final zone = controller.selectedZone.value;
      if (zone == null) return const SizedBox.shrink();

      final dist = controller.distanceToZone(zone);
      final isInside = controller.isInsideZone(zone);

      return Card(
        margin: const EdgeInsets.only(top: HavenSpacing.sm),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(HavenSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 20, color: Colors.teal),
                      const SizedBox(width: HavenSpacing.xs),
                      Text(zone.name, style: HavenText.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.selectZone(null),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Safe-zone radius: ${zone.radiusM.round()} m', style: HavenText.caption),
              if (dist != null) ...[
                const SizedBox(height: HavenSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isInside ? Colors.green.shade100 : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isInside ? 'INSIDE ZONE' : 'OUTSIDE ZONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isInside ? Colors.green.shade900 : Colors.brown.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: HavenSpacing.sm),
                    Text(
                      dist >= 1000
                          ? '${(dist / 1000).toStringAsFixed(2)} km from center'
                          : '${dist.round()} m from center',
                      style: HavenText.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

/// Panel showing active child fix telemetry details when tapped or selected.
class ChildDeviceInfoPanel extends GetView<LocationController> {
  const ChildDeviceInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isChildSelected.value) return const SizedBox.shrink();
      final line = controller.activeLine;
      if (line == null) return const SizedBox.shrink();

      return Card(
        margin: const EdgeInsets.only(top: HavenSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(HavenSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.devices, size: 18),
                      const SizedBox(width: HavenSpacing.xs),
                      Text('Device: ${line.whose}', style: HavenText.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => controller.selectChild(false),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${line.recorded} · ${line.accuracy}', style: HavenText.caption),
              Text(line.delay, style: HavenText.caption),
              if (controller.showsCoordinates.value)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Exact: ${line.coordinates} (${line.source})',
                    style: HavenText.caption.copyWith(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Honest offline explanation indicating no live GPS tracking in Phase 2.
class OfflineMapExplanationCard extends StatelessWidget {
  const OfflineMapExplanationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: HavenSpacing.xs),
              const Text('Phase 2 Offline Coordinate Canvas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'This map renders reported historical coordinates and configured safe zones on an offline '
            'canvas without external tile servers. Live real-time GPS tracking is not active in Phase 2.',
            style: HavenText.caption,
          ),
        ],
      ),
    );
  }
}
