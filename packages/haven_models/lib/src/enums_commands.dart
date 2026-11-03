/// Device, enforcement and command tokens — the values that describe what a
/// device is allowed to do and what was asked of it.
library;

import 'enums_wire.dart';

enum DeviceStatus implements WireLabel {
  pending('pending', 'Waiting to be set up'),
  active('active', 'Connected'),
  revoked('revoked', 'Removed');

  const DeviceStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static DeviceStatus? fromWire(String? v) => matchWire(values, v);
}

enum EnforcementMode implements WireLabel {
  none('none', 'No special controls'),
  deviceAdmin('device_admin', 'Device admin approved'),
  deviceOwner('device_owner', 'Device owner (fully managed)');

  const EnforcementMode(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static EnforcementMode? fromWire(String? v) => matchWire(values, v);
}

enum CommandType implements WireLabel {
  applyPolicy('apply_policy', 'Apply the current rules'),
  syncPolicy('sync_policy', 'Check for rule updates'),
  requestUsage('request_usage', 'Ask the device for its usage report'),
  requestLocation('request_location', 'Ask the device for its location'),
  endSession('end_session', 'End the remote session'),
  custom('custom', 'A custom instruction');

  const CommandType(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static CommandType? fromWire(String? v) => matchWire(values, v);
}

enum CommandStatus implements WireLabel {
  pending('pending', 'Queued'),
  delivered('delivered', 'Sent to the device'),
  succeeded('succeeded', 'Done'),
  failed('failed', 'Failed'),
  expired('expired', 'Never reached the device');

  const CommandStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static CommandStatus? fromWire(String? v) => matchWire(values, v);
}

/// `enforced` is only ever set from what the device reported back, never from
/// the fact that a policy row was written.
enum PolicyEnforcementStatus implements WireLabel {
  pending('pending', 'Waiting for the device'),
  enforced('enforced', 'Applied on the device'),
  failed('failed', 'Could not be applied'),
  unsupported('unsupported', 'This device cannot apply it');

  const PolicyEnforcementStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static PolicyEnforcementStatus? fromWire(String? v) => matchWire(values, v);
}
