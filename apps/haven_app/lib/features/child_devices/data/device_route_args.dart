/// The argument the `deviceDetail` route is opened with.
///
/// It carries a device id and nothing else. The id is not a secret — it is a row
/// key the parent's own family is allowed to know about — but it is also not a
/// credential: the device lane authenticates with a separate device secret that
/// never appears in this app (see `docs/stage1/03-data-model.md` for the two
/// lanes). No screen can build one of these yet, because no screen can read a
/// device row; the class exists so the route the contract fixes has a typed
/// argument rather than a bare string a later screen could pass by accident.
final class DeviceRouteArgs {
  const DeviceRouteArgs({required this.deviceId});

  final String deviceId;

  /// Null for anything that is not this type, so a page opened from a stale or
  /// wrong route says so instead of reading a device that was never named.
  static DeviceRouteArgs? tryParse(Object? argument) {
    if (argument is DeviceRouteArgs) return argument;
    return null;
  }
}
