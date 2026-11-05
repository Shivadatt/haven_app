/// Data models for local pairing simulation.
///
/// Encapsulates the simulated session, pairing code lifecycle, and created device.
final class SimulatedPairingSession {
  SimulatedPairingSession({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.isRedeemed = false,
    this.isCancelled = false,
  });

  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool isRedeemed;
  bool isCancelled;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime =>
      isExpired ? Duration.zero : expiresAt.difference(DateTime.now());

  bool get isValid => !isExpired && !isRedeemed && !isCancelled;

  void cancel() {
    isCancelled = true;
  }

  void redeem() {
    isRedeemed = true;
  }
}

/// A simulated device successfully paired and stored locally.
final class SimulatedDevice {
  const SimulatedDevice({
    required this.id,
    required this.familyId,
    required this.childUserId,
    required this.childName,
    required this.displayName,
    required this.platform,
    required this.status,
    required this.pairedAt,
  });

  final String id;
  final String familyId;
  final String childUserId;
  final String childName;
  final String displayName;
  final String platform;
  final String status;
  final DateTime pairedAt;
}
