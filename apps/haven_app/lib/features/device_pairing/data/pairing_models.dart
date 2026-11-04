import 'package:haven_models/haven_models.dart';

/// One pairing request, said the way a parent reads it: which child, what state
/// the backend has it in, and when the row says it closes.
///
/// `childName` is resolved from the family's own member list, never from a column
/// of this table — `pairing_requests` holds user ids, not names.
final class PairingLine {
  const PairingLine({required this.request, required this.childName});

  final PairingRequest request;
  final String childName;

  String get statusLabel =>
      request.requestStatus?.label ?? 'No status recorded';

  bool get isWaiting => request.isPending;

  String get who =>
      isWaiting ? '$childName has not approved yet' : 'Pairing for $childName';
}

/// What the pairing screen actually read. An empty [lines] is a real answer:
/// nothing has been requested for this family.
final class PairingBoard {
  const PairingBoard({
    required this.familyId,
    this.familyName,
    required this.lines,
  });

  final String familyId;

  /// Null when the family row has not been read alongside these requests; the
  /// screen then speaks of "your family" rather than inventing a name.
  final String? familyName;
  final List<PairingLine> lines;

  bool get hasLines => lines.isNotEmpty;

  /// The first request still waiting on the child, newest first. The screen
  /// needs a real id before it can ask the backend to withdraw anything.
  PairingLine? get firstWaiting {
    for (final PairingLine line in lines) {
      if (line.isWaiting) return line;
    }
    return null;
  }

  /// How many requests the screen asks the backend for. The window is a page
  /// size, not a count: a parent is told what was read, never what exists.
  static const int window = 20;

  String get counted {
    final int waiting = lines.where((PairingLine l) => l.isWaiting).length;
    return waiting == 0
        ? '${lines.length} '
              '${lines.length == 1 ? 'request' : 'requests'} read, none waiting.'
        : '${lines.length} '
              '${lines.length == 1 ? 'request' : 'requests'} read, '
              '$waiting waiting on the child.';
  }
}
