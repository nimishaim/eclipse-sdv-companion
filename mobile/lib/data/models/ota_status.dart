enum OtaStage {
  idle,
  checking,
  downloading,
  stagingRauc,
  verifyingBundle,
  readyForReboot,
  installing,
  success,
  failed,
}

class OtaStatus {
  final String currentVersion;
  final String availableVersion;
  final String activeSlot; // 'root_a' or 'root_b'
  final String inactiveSlot; // 'root_b' or 'root_a'
  final OtaStage stage;
  final double progressPercent; // 0.0 to 100.0
  final String? statusMessage;
  final bool hasUpdate;
  final String targetBundle;
  final DateTime lastChecked;
  final bool isSimulated;

  const OtaStatus({
    required this.currentVersion,
    required this.availableVersion,
    required this.activeSlot,
    required this.inactiveSlot,
    required this.stage,
    required this.progressPercent,
    this.statusMessage,
    required this.hasUpdate,
    required this.targetBundle,
    required this.lastChecked,
    this.isSimulated = false,
  });

  factory OtaStatus.initial({bool isSimulated = true}) {
    return OtaStatus(
      currentVersion: 'leda-genericx86-v0.4.1-rauc',
      availableVersion: 'leda-genericx86-v0.5.0-rauc',
      activeSlot: 'root_a (PARTLABEL=root_a)',
      inactiveSlot: 'root_b (PARTLABEL=root_b)',
      stage: OtaStage.idle,
      progressPercent: 0.0,
      statusMessage: 'System idle. Slot A active with systemd-boot.',
      hasUpdate: true,
      targetBundle: 'bundle-leda-apm-0.5.0.raucb',
      lastChecked: DateTime.now().subtract(const Duration(minutes: 15)),
      isSimulated: isSimulated,
    );
  }

  OtaStatus copyWith({
    String? currentVersion,
    String? availableVersion,
    String? activeSlot,
    String? inactiveSlot,
    OtaStage? stage,
    double? progressPercent,
    String? statusMessage,
    bool? hasUpdate,
    String? targetBundle,
    DateTime? lastChecked,
    bool? isSimulated,
  }) {
    return OtaStatus(
      currentVersion: currentVersion ?? this.currentVersion,
      availableVersion: availableVersion ?? this.availableVersion,
      activeSlot: activeSlot ?? this.activeSlot,
      inactiveSlot: inactiveSlot ?? this.inactiveSlot,
      stage: stage ?? this.stage,
      progressPercent: progressPercent ?? this.progressPercent,
      statusMessage: statusMessage ?? this.statusMessage,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      targetBundle: targetBundle ?? this.targetBundle,
      lastChecked: lastChecked ?? this.lastChecked,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}
