import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/safe_zone_presence.dart';

/// Local presence calculator and summary widget. Converts refusal #11.
final class SafeZonePresenceWidget extends StatefulWidget {
  const SafeZonePresenceWidget({required this.zones, super.key});

  final List<SafeZone> zones;

  @override
  State<SafeZonePresenceWidget> createState() => _SafeZonePresenceWidgetState();
}

class _SafeZonePresenceWidgetState extends State<SafeZonePresenceWidget> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  List<SafeZonePresenceResult>? _results;
  String? _summary;

  @override
  void initState() {
    super.initState();
    if (widget.zones.isNotEmpty) {
      _latController.text = widget.zones.first.lat.toString();
      _lngController.text = widget.zones.first.lng.toString();
      _evaluate();
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _evaluate() {
    final double? lat = double.tryParse(_latController.text.trim());
    final double? lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      setState(() {
        _results = null;
        _summary = 'Enter valid test latitude and longitude';
      });
      return;
    }
    setState(() {
      _results = SafeZonePresenceCalculator.evaluateAll(
        zones: widget.zones,
        lat: lat,
        lng: lng,
      );
      _summary = SafeZonePresenceCalculator.summarizePresence(
        zones: widget.zones,
        lat: lat,
        lng: lng,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.zones.isEmpty) return const SizedBox.shrink();

    final bool isInside = _results?.any((r) => r.isInside) ?? false;

    return SectionCard(
      title: 'Safe Zone Presence (Local)',
      subtitle: 'Calculated using local Haversine distance.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HavenField(
                  label: 'Test Lat',
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: HavenSpacing.sm),
              Expanded(
                child: HavenField(
                  label: 'Test Lng',
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: HavenSpacing.xs),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Calculate Presence',
                onPressed: _evaluate,
              ),
            ],
          ),
          const SizedBox(height: HavenSpacing.sm),
          Row(
            children: [
              StatusChip(
                label: isInside ? 'Inside' : 'Outside',
                tone: isInside ? StatusTone.good : StatusTone.neutral,
              ),
              const SizedBox(width: HavenSpacing.sm),
              Expanded(
                child: Text(
                  _summary ?? 'Checking...',
                  style: HavenText.caption,
                ),
              ),
            ],
          ),
          if (_results != null && _results!.isNotEmpty) ...[
            const SizedBox(height: HavenSpacing.sm),
            const Divider(),
            for (final r in _results!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(r.summary, style: HavenText.caption),
              ),
          ],
        ],
      ),
    );
  }
}
