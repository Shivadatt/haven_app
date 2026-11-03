import 'package:flutter/material.dart';

import '../../app/theme/haven_colors.dart';
import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';
import 'haven_button.dart';

/// Explain a permission before asking for it, then ask.
///
/// The order is the point: Android shows the system dialog with no context, so
/// the reason has to be on screen first. [onRequest] reports what the operating
/// system answered — the widget never infers "granted" from the tap.
final class PermissionExplain extends StatefulWidget {
  const PermissionExplain({
    required this.title,
    required this.why,
    required this.icon,
    required this.onRequest,
    required this.onResult,
    this.alternative,
    super.key,
  });

  final String title;
  final String why;
  final IconData icon;
  final Future<bool> Function() onRequest;
  final ValueChanged<bool> onResult;

  /// What the parent can still do if the permission is refused, in one sentence.
  final String? alternative;

  @override
  State<PermissionExplain> createState() => _PermissionExplainState();
}

class _PermissionExplainState extends State<PermissionExplain> {
  bool _busy = false;
  bool? _answer;
  String? _note;

  Future<void> _request() async {
    setState(() => _busy = true);
    late bool granted;
    String? refusalNote;
    try {
      granted = await widget.onRequest();
    } catch (_) {
      granted = false;
      refusalNote =
          'The system did not answer. Open the phone settings to allow it.';
    }
    if (!mounted) {
      widget.onResult(granted);
      return;
    }
    setState(() {
      _busy = false;
      _answer = granted;
      _note = granted
          ? null
          : (refusalNote ??
                widget.alternative ??
                'Not allowed yet — nothing is being recorded.');
    });
    widget.onResult(granted);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: HavenSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: HavenText.headline),
                  const SizedBox(height: HavenSpacing.xs),
                  Text(
                    widget.why,
                    style: HavenText.body.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_answer == null) ...[
          const SizedBox(height: HavenSpacing.md),
          HavenButton(label: 'Allow', busy: _busy, onPressed: _request),
        ],
        if (_note != null) ...[
          const SizedBox(height: HavenSpacing.sm),
          Text(
            _note!,
            style: HavenText.caption.copyWith(
              color: _answer == true
                  ? HavenColors.good
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
