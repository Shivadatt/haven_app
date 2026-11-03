/// Identity, family and pairing tokens — the values that decide *who* something
/// is. Labels are parent-facing; `wire` is what the database stores.
library;

import 'enums_wire.dart';

enum ProfileRole implements WireLabel {
  unset('unset', 'Not set up yet'),
  parent('parent', 'Parent'),
  child('child', 'Child');

  const ProfileRole(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static ProfileRole? fromWire(String? v) => matchWire(values, v);
}

enum FamilyRole implements WireLabel {
  parent('parent', 'Parent'),
  child('child', 'Child');

  const FamilyRole(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static FamilyRole? fromWire(String? v) => matchWire(values, v);
}

enum FamilyMemberStatus implements WireLabel {
  active('active', 'Active'),
  removed('removed', 'Removed');

  const FamilyMemberStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static FamilyMemberStatus? fromWire(String? v) => matchWire(values, v);
}

enum PairingTokenPurpose implements WireLabel {
  code('code', 'Short code from the child device'),
  invite('invite', 'Invite for a Child ID');

  const PairingTokenPurpose(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static PairingTokenPurpose? fromWire(String? v) => matchWire(values, v);
}

enum PairingTokenStatus implements WireLabel {
  active('active', 'Still works'),
  redeemed('redeemed', 'Already used'),
  revoked('revoked', 'Cancelled'),
  expired('expired', 'Timed out');

  const PairingTokenStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static PairingTokenStatus? fromWire(String? v) => matchWire(values, v);
}

enum PairingRequestStatus implements WireLabel {
  pendingChild('pending_child', 'Waiting for approval'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Declined'),
  cancelled('cancelled', 'Cancelled'),
  expired('expired', 'Timed out');

  const PairingRequestStatus(this.wire, this.label);
  @override
  final String wire;
  @override
  final String label;

  static PairingRequestStatus? fromWire(String? v) => matchWire(values, v);
}
