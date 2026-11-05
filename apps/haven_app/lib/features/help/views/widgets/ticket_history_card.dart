import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/section_card.dart';
import '../../../../shared/components/status_chip.dart';
import '../../data/help_models.dart';

class TicketHistoryCard extends StatelessWidget {
  const TicketHistoryCard({super.key, required this.tickets});

  final List<SupportTicket> tickets;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: 'Locally Saved Tickets (${tickets.length})',
      subtitle: 'Stored safely on this phone',
      child: Column(
        children: tickets.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.subject, style: HavenText.headline),
              subtitle: Text(
                '${t.category} • ${_formatTime(t.createdAt)}\n${t.description}',
                style: HavenText.caption,
              ),
              trailing: t.isDraft
                  ? const StatusChip(label: 'Draft', tone: StatusTone.warning)
                  : const StatusChip(label: 'Saved', tone: StatusTone.good),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
