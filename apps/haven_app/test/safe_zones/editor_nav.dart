import 'package:haven_app/features/safe_zones/controllers/zone_editor_controller.dart';

import 'fakes.dart';

/// The two side effects the editor is allowed to have, recorded rather than
/// performed: closing its own screen and replacing the stack with setup.
final class EditorNav {
  final List<String> replaces = [];
  int closed = 0;
}

/// The editor as the bindings build it.
(SafeZoneEditorController, EditorNav) editor(
  FakeSafeZonesRepository repo, {
  String zoneId = 'z1',
}) {
  final EditorNav nav = EditorNav();
  return (
    SafeZoneEditorController(
      zoneId: zoneId,
      repository: repo,
      replace: (String route, Object? arg) => nav.replaces.add(route),
      close: () => nav.closed++,
    ),
    nav,
  );
}
