/// Remote-session, signalling and alert tokens.
///
/// `consent_recorded` — not a status here — is what makes a session live; the
/// status only tracks the negotiated lifecycle around it.
library;

import 'enums_wire.dart';

enum SessionKind implements WireLabel {
  audio('audio', 'A call with audio'),
  video('video', 'A video session');

  const SessionKind(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static SessionKind? fromWire(String? v) => matchWire(values, v);
}

enum SessionStatus implements WireLabel {
  requested('requested', 'Requested'),
  accepted('accepted', 'Accepted, starting'),
  active('active', 'Running'),
  declined('declined', 'Declined'),
  ended('ended', 'Ended'),
  expired('expired', 'Expired'),
  failed('failed', 'Failed');

  const SessionStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static SessionStatus? fromWire(String? v) => matchWire(values, v);
}

enum SignalKind implements WireLabel {
  offer('offer', 'Connection offer'),
  answer('answer', 'Connection answer'),
  ice('ice', 'Network path');

  const SignalKind(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static SignalKind? fromWire(String? v) => matchWire(values, v);
}

enum AlertType implements WireLabel {
  lowBattery('low_battery', 'Battery is low'),
  offline('offline', 'Device went offline'),
  geofenceEnter('geofence_enter', 'Arrived at a safe place'),
  geofenceExit('geofence_exit', 'Left a safe place'),
  appBlocked('app_blocked', 'An app was blocked'),
  permissionMissing('permission_missing', 'A permission was removed'),
  other('other', 'Something else');

  const AlertType(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static AlertType? fromWire(String? v) => matchWire(values, v);
}

enum AlertSeverity implements WireLabel {
  info('info', 'For information'),
  warning('warning', 'Worth a look'),
  critical('critical', 'Needs attention now');

  const AlertSeverity(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static AlertSeverity? fromWire(String? v) => matchWire(values, v);
}
