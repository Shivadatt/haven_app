import 'package:flutter/material.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../core/device/device_information.dart';
import '../../../../shared/components/status_chip.dart';
import '../../controllers/child_policy_controller.dart';
import '../../data/child_policy_record.dart';

/// Renders policy provenance, version, updated timestamp, and overall state.
final class PolicyStatusCard extends StatelessWidget {
  const PolicyStatusCard({
    required this.provenance,
    required this.status,
    this.policyVersion,
    this.updatedAt,
    this.overallState,
    this.primaryReason,
    super.key,
  });

  final PolicyProvenance? provenance;
  final ChildPolicyStatus status;
  final int? policyVersion;
  final DateTime? updatedAt;
  final PolicyOverallState? overallState;
  final String? primaryReason;

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipTone) = _provenanceChip();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Policy status', style: ChildText.headline),
                ),
                ChildStatusChip(
                  key: const ValueKey('policy-status-chip'),
                  label: chipLabel,
                  tone: chipTone,
                ),
              ],
            ),
            const SizedBox(height: ChildSpacing.md),
            _infoLine('Version', _versionText()),
            if (updatedAt != null) ...[
              const SizedBox(height: ChildSpacing.xs),
              _infoLine('Last updated', formatDate(updatedAt!)),
            ],
            if (overallState != null) ...[
              const SizedBox(height: ChildSpacing.xs),
              _infoLine('Evaluation', _stateText(overallState!)),
            ],
            if (primaryReason != null && primaryReason!.isNotEmpty) ...[
              const SizedBox(height: ChildSpacing.sm),
              Text(primaryReason!, style: ChildText.caption),
            ],
          ],
        ),
      ),
    );
  }

  (String, StatusTone) _provenanceChip() {
    return switch (provenance) {
      PolicyProvenance.parentSynced => ('Active Family Rules', StatusTone.good),
      PolicyProvenance.inMemoryNeutral => ('Neutral Rules', StatusTone.neutral),
      null => ('Unverified', StatusTone.warning),
    };
  }

  String _versionText() {
    if (provenance == PolicyProvenance.inMemoryNeutral) {
      return 'In-memory default';
    }
    return policyVersion != null ? 'v$policyVersion' : DeviceFacts.unavailable;
  }

  String _stateText(PolicyOverallState state) {
    return switch (state) {
      PolicyOverallState.allowed => 'Allowed',
      PolicyOverallState.bedtimeActive => 'Bedtime active',
      PolicyOverallState.schoolActive => 'School active',
      PolicyOverallState.scheduleRestricted => 'Schedule restricted',
      PolicyOverallState.dailyLimitReached => 'Daily limit reached',
      PolicyOverallState.dailyLimitExceeded => 'Daily limit exceeded',
      PolicyOverallState.usageUnavailable => 'Usage unavailable',
    };
  }

  Widget _infoLine(String label, String value) {
    return Row(
      children: [
        Text(label, style: ChildText.label),
        const Spacer(),
        Text(value, style: ChildText.body),
      ],
    );
  }
}
