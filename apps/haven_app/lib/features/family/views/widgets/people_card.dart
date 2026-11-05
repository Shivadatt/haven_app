import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../../app/theme/haven_text.dart';
import '../../../../../core/utils/haven_time.dart';
import '../../data/family_models.dart';

/// A named group of family members, newest info first.
class PeopleCard extends StatelessWidget {
  const PeopleCard({
    super.key,
    required this.title,
    required this.people,
    required this.emptyLine,
    this.onTap,
    this.trailing,
  });

  final String title;
  final List<FamilyPerson> people;
  final String emptyLine;
  final void Function(String userId)? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      trailing: trailing,
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
      leading: person.avatar != null
          ? Text(person.avatar!, style: const TextStyle(fontSize: 24))
          : null,
      title: Text(person.name, style: HavenText.body),
      subtitle: Text(_subtitle(), style: HavenText.caption),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap == null ? null : () => onTap!(person.userId),
    );
  }

  String _subtitle() {
    if (!person.hasProfile) return 'This account has no name on file yet.';
    final String since = havenDay(person.member.createdAt) ?? 'an unknown date';
    final String base = 'In the family since $since';
    if (person.ageBracket != null) {
      return '$base • Ages ${person.ageBracket}';
    }
    return base;
  }
}
