import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/child_profile_constants.dart';

/// Dialog to create a child profile.
class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key, required this.onAdd});

  final Future<bool> Function({
    required String name,
    String? ageBracket,
    String? avatar,
  }) onAdd;

  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function({
      required String name,
      String? ageBracket,
      String? avatar,
    }) onAdd,
  }) => showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AddChildDialog(onAdd: onAdd),
  );

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedAgeBracket = ChildProfileConstants.ageBrackets.first;
  String? _selectedAvatar = ChildProfileConstants.avatars.first;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? validationError = ChildProfileConstants.validateName(
      _nameController.text,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final bool ok = await widget.onAdd(
      name: _nameController.text.trim(),
      ageBracket: _selectedAgeBracket,
      avatar: _selectedAvatar,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Could not add child profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add child profile', style: HavenText.headline),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HavenField(
              label: 'Child name',
              controller: _nameController,
              maxLength: ChildProfileConstants.maxNameLength,
              helper: 'e.g. Ivy',
              enabled: !_isBusy,
            ),
            const SizedBox(height: HavenSpacing.md),
            Text('Age bracket', style: HavenText.caption),
            const SizedBox(height: HavenSpacing.xs),
            Wrap(
              spacing: HavenSpacing.xs,
              children: [
                for (final String bracket in ChildProfileConstants.ageBrackets)
                  ChoiceChip(
                    label: Text(bracket),
                    selected: _selectedAgeBracket == bracket,
                    onSelected: _isBusy
                        ? null
                        : (bool selected) {
                            if (selected) {
                              setState(() => _selectedAgeBracket = bracket);
                            }
                          },
                  ),
              ],
            ),
            const SizedBox(height: HavenSpacing.md),
            Text('Avatar', style: HavenText.caption),
            const SizedBox(height: HavenSpacing.xs),
            Wrap(
              spacing: HavenSpacing.xs,
              children: [
                for (final String av in ChildProfileConstants.avatars)
                  ChoiceChip(
                    label: Text(av, style: const TextStyle(fontSize: 20)),
                    selected: _selectedAvatar == av,
                    onSelected: _isBusy
                        ? null
                        : (bool selected) {
                            if (selected) {
                              setState(() => _selectedAvatar = av);
                            }
                          },
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: HavenSpacing.sm),
              Text(
                _error!,
                style: HavenText.caption.copyWith(color: HavenColors.bad),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isBusy ? null : _submit,
          child: _isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add child'),
        ),
      ],
    );
  }
}
