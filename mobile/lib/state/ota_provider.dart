import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/ota_status.dart';
import 'app_settings_provider.dart';

class OtaNotifier extends Notifier<OtaStatus> {
  Timer? _simulationTimer;

  @override
  OtaStatus build() {
    ref.onDispose(() {
      _simulationTimer?.cancel();
    });
    return OtaStatus.initial(isSimulated: true);
  }

  Future<void> checkForUpdates() async {
    final isDemo = ref.read(appSettingsProvider).isDemoMode;

    state = state.copyWith(
      stage: OtaStage.checking,
      statusMessage: 'Connecting to Eclipse HawkBit DDI (Direct Device Integration) API...',
      isSimulated: isDemo,
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!isDemo) {
      state = state.copyWith(
        stage: OtaStage.idle,
        statusMessage: 'HawkBit DDI endpoint unreachable on target vehicle node. Live OTA update triggers disabled.',
        hasUpdate: false,
        lastChecked: DateTime.now(),
      );
      return;
    }

    state = state.copyWith(
      stage: OtaStage.idle,
      statusMessage: 'Update bundle available: leda-genericx86-v0.5.0-rauc',
      hasUpdate: true,
      availableVersion: 'leda-genericx86-v0.5.0-rauc',
      targetBundle: 'bundle-leda-apm-0.5.0.raucb',
      lastChecked: DateTime.now(),
    );
  }

  void startSimulatedUpdate() {
    final isDemo = ref.read(appSettingsProvider).isDemoMode;
    if (!isDemo) {
      state = state.copyWith(
        stage: OtaStage.failed,
        statusMessage: 'Live update prohibited: No verified SUA/RAUC endpoint detected on vehicle edge.',
      );
      return;
    }

    _simulationTimer?.cancel();
    state = state.copyWith(
      stage: OtaStage.downloading,
      progressPercent: 0.0,
      statusMessage: 'Downloading RAUC bundle over encrypted HTTP channel...',
      isSimulated: true,
    );

    int progress = 0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) {
      progress += 5;
      if (progress <= 40) {
        state = state.copyWith(
          stage: OtaStage.downloading,
          progressPercent: progress.toDouble(),
          statusMessage: 'Downloading bundle ($progress% completed)...',
        );
      } else if (progress <= 75) {
        state = state.copyWith(
          stage: OtaStage.stagingRauc,
          progressPercent: progress.toDouble(),
          statusMessage:
              'RAUC writing image to inactive partition: ${state.inactiveSlot} ($progress%)...',
        );
      } else if (progress < 100) {
        state = state.copyWith(
          stage: OtaStage.verifyingBundle,
          progressPercent: progress.toDouble(),
          statusMessage:
              'Verifying X.509 bundle signature and rootfs hash ($progress%)...',
        );
      } else {
        timer.cancel();
        state = state.copyWith(
          stage: OtaStage.readyForReboot,
          progressPercent: 100.0,
          statusMessage: 'Staging complete. systemd-boot entry updated. Ready to reboot into new partition.',
        );
      }
    });
  }

  void executeSimulatedReboot() {
    _simulationTimer?.cancel();
    final previousActive = state.activeSlot;
    final previousInactive = state.inactiveSlot;

    state = state.copyWith(
      stage: OtaStage.installing,
      statusMessage: 'Rebooting into upgraded system partition...',
    );

    Timer(const Duration(seconds: 2), () {
      state = state.copyWith(
        stage: OtaStage.success,
        currentVersion: state.availableVersion,
        activeSlot: previousInactive,
        inactiveSlot: previousActive,
        hasUpdate: false,
        statusMessage:
            'System reboot complete. Now running active on $previousInactive.',
      );
    });
  }

  void cancelUpdate() {
    _simulationTimer?.cancel();
    state = state.copyWith(
      stage: OtaStage.idle,
      progressPercent: 0.0,
      statusMessage: 'Update aborted by operator.',
    );
  }
}

final otaProvider = NotifierProvider<OtaNotifier, OtaStatus>(OtaNotifier.new);
