/// Constants for the child profile step, mirroring the parent's
/// `ChildProfileConstants` (same four brackets from
/// `features/family/views/pages/child_create_page.dart`'s data source) so a
/// family sees one age vocabulary across both apps.
abstract final class ChildProfileConstants {
  static const List<String> ageBrackets = <String>['4-7', '8-11', '12-14', '15-17'];

  /// The app follows `haven_core` `validateDisplayName`, which caps at 60;
  /// the field enforces the same limit the repository will re-check.
  static const int maxNameLength = 60;
}
