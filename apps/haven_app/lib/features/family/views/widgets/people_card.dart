import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../../app/theme/haven_text.dart';
import '../../../../../core/utils/haven_time.dart';
import '../../data/family_models.dart';

/// A named group of family members, newest info first.
///
/// The dashboard and the family screen both list people, so they share this:
/// the same name, the same reason a name might be missing, and the same rule
/// that a member is never dropped from view because their profile row was not
/// provisioned.
class PeopleCard extends StatelessWidget {
  const PeopleCard({
    super.key,
    required this.title,
    required this.people,
    required this.emptyLine,
    this.onTap,
  });

  final String title;
  final List<FamilyPerson> people;

  /// What to say when the group is empty. Left to the caller because the reason
  /// differs: a family with no children yet is not the same as a dashboard that
  /// cannot pair one.
  final String emptyLine;

  /// Null when there is nothing to open — parents have no profile screen in this
  /// build, so they get no chevron and no dead tap target.
  final void Function(String userId)? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: people.isEmpty
          ? Text(emptyLine, style: HavenText.body)
          : Column(
              children: [
                for (final FamilyPerson person in people)
                  PersonRow(person: person, onTap: onTap),
              ],
            ),
    );
  }
}

class PersonRow extends StatelessWidget {
  const PersonRow({super.key, required this.person, this.onTap});

  final FamilyPerson person;
  final void Function(String userId)? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(person.name, style: HavenText.body),
      subtitle: Text(_subtitle(), style: HavenText.caption),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap == null ? null : () => onTap!(person.userId),
    );
  }

  String _subtitle() {
    if (!person.hasProfile) return 'This account has no name on file yet.';
    final String since = havenDay(person.member.createdAt) ?? 'an unknown date';
    return 'In the family since $since';
  }
}
