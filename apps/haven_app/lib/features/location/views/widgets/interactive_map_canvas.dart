import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/location_controller.dart';
import 'map_painter.dart';

/// Interactive canvas rendering offline coordinate map, child pins and safe zones.
class InteractiveMapCanvas extends GetView<LocationController> {
  const InteractiveMapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) => controller.updatePan(details.delta),
              child: Obx(
                () => CustomPaint(
                  painter: MapPainter(
                    fix: controller.activeLine,
                    zones: controller.safeZones,
                    selectedZone: controller.selectedZone.value,
                    zoom: controller.zoom.value,
                    panOffset: controller.panOffset.value,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),
          ),
          // Coordinate mode chip (DEMO / MANUAL)
          Positioned(
            top: HavenSpacing.xs,
            left: HavenSpacing.xs,
            child: Obx(() {
              if (controller.isDemoCoordinate) {
                return _BadgeChip(
                  label: 'DEMO COORDINATES',
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                );
              }
              if (controller.isManualCoordinate) {
                return _BadgeChip(
                  label: 'MANUALLY ENTERED',
                  color: Colors.blue.shade800,
                  bgColor: Colors.blue.shade50,
                );
              }
              return const SizedBox.shrink();
            }),
          ),
          // Zoom & Recenter controls
          Positioned(
            bottom: HavenSpacing.xs,
            right: HavenSpacing.xs,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: controller.zoomIn,
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: controller.zoomOut,
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.my_location,
                  tooltip: 'Recenter map',
                  onPressed: controller.recenter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color, required this.bgColor});
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
