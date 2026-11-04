import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/zones_models.dart';

/// The places the family named, and the boundary that comes with reading them.
final class ZonesCard extends StatelessWidget {
  const ZonesCard({required this.board, required this.onEdit, super.key});

  final ZoneBoard board;
  final void Function(String zoneId) onEdit;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Named places',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasZones)
          Text(
            'No place is named for this family yet. A device cannot be told when '
            'it has arrived somewhere Haven does not know about.',
            style: HavenText.body,
          )
        else
          for (int i = 0; i < board.zones.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.sm),
            ZoneRow(zone: board.zones[i], onEdit: onEdit),
          ],
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.createGap),
        const SizedBox(height: HavenSpacing.sm),
        BlockedNotice.fromFailure(board.presenceGap),
      ],
    ),
  );
}

/// One zone: what it is called, how wide it is, and whether it is being used.
final class ZoneRow extends StatelessWidget {
  const ZoneRow({required this.zone, required this.onEdit, super.key});

  final SafeZone zone;
  final void Function(String zoneId) onEdit;

  String get _name =>
      zone.name.isEmpty ? 'A place with no name yet' : zone.name;

  String get _radius => '${zone.radiusM.toStringAsFixed(0)} m across';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(_name, style: HavenText.body)),
          StatusChip(
            label: zone.active ? 'In use' : 'Paused',
            tone: zone.active ? StatusTone.good : StatusTone.neutral,
          ),
        ],
      ),
      Text(
        _radius,
        style: HavenText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: HavenSpacing.sm),
      HavenButton(
        label: 'Edit this place',
        primary: false,
        onPressed: () => onEdit(zone.id),
      ),
    ],
  );
}
