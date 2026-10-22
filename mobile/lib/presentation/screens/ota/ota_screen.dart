import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/ota_status.dart';
import '../../../state/ota_provider.dart';
import '../../../state/telemetry_provider.dart';
import '../../../state/app_settings_provider.dart';
import '../../widgets/automotive_app_bar.dart';
import '../../widgets/confirmation_dialog.dart';

class OtaScreen extends ConsumerWidget {
  const OtaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ota = ref.watch(otaProvider);
    final telemetry = ref.watch(telemetryProvider).telemetry;
    final settings = ref.watch(appSettingsProvider);

    final isStationaryAndParked =
        telemetry.speedKmh < 0.5 && telemetry.gear == 'P';

    return Scaffold(
      appBar: const AutomotiveAppBar(title: 'Firmware & RAUC OTA'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Simulation banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ota.isSimulated
                    ? AppColors.statusSimulated.withValues(alpha: 0.12)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ota.isSimulated
                      ? AppColors.statusSimulated.withValues(alpha: 0.4)
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ota.isSimulated
                        ? Icons.science_outlined
                        : Icons.cloud_done_outlined,
                    color: ota.isSimulated
                        ? AppColors.statusSimulated
                        : AppColors.neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ota.isSimulated
                          ? 'DEMO OTA SIMULATOR: Staging and partition switching are visualized locally without modifying host partitions.'
                          : 'LIVE OTA PIPELINE: Connects to HawkBit DDI and RAUC D-Bus interface.',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // A/B Partition Slot Architecture Status Card
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RAUC DUAL-SLOT ARCHITECTURE',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.layers_outlined,
                          size: 18,
                          color: AppColors.electricCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Slot A
                        Expanded(
                          child: _buildPartitionSlotCard(
                            slotName: 'SLOT A (root_a)',
                            version: ota.currentVersion,
                            isActive: ota.activeSlot.contains('root_a'),
                            isTarget:
                                ota.inactiveSlot.contains('root_a') &&
                                ota.stage == OtaStage.stagingRauc,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Slot B
                        Expanded(
                          child: _buildPartitionSlotCard(
                            slotName: 'SLOT B (root_b)',
                            version: ota.activeSlot.contains('root_b')
                                ? ota.currentVersion
                                : ota.availableVersion,
                            isActive: ota.activeSlot.contains('root_b'),
                            isTarget:
                                ota.inactiveSlot.contains('root_b') &&
                                (ota.stage == OtaStage.stagingRauc ||
                                    ota.stage == OtaStage.readyForReboot),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildOtaInfoRow('Active Boot Entry', ota.activeSlot),
                    _buildOtaInfoRow('Standby Target', ota.inactiveSlot),
                    _buildOtaInfoRow(
                      'Bootloader Method',
                      'UEFI systemd-boot (A/B payload)',
                    ),
                    _buildOtaInfoRow(
                      'Container Store',
                      'Persistent /data/var/lib/container-management/',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Update Progress & Action Card
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SOFTWARE UPDATE LIFECYCLE',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          ota.stage.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStageColor(ota.stage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Available: ${ota.availableVersion}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target Package: ${ota.targetBundle}',
                      style: AppTypography.monospace.copyWith(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    if (ota.stage != OtaStage.idle &&
                        ota.stage != OtaStage.success) ...[
                      LinearProgressIndicator(
                        value: ota.progressPercent > 0
                            ? ota.progressPercent / 100
                            : null,
                        backgroundColor: AppColors.gaugeTrack,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStageColor(ota.stage),
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ota.statusMessage ?? 'Processing...',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${ota.progressPercent.toInt()}%',
                            style: AppTypography.monospace.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    if (ota.stage == OtaStage.idle) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.sync),
                              label: const Text('Check for Updates'),
                              onPressed: () {
                                ref
                                    .read(otaProvider.notifier)
                                    .checkForUpdates();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.electricCyan,
                                foregroundColor: AppColors.background,
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('Stage Update'),
                              onPressed: () async {
                                if (!settings.isDemoMode) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Live OTA trigger disabled: Vehicle edge has not authenticated HawkBit DDI agent.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                ref
                                    .read(otaProvider.notifier)
                                    .startSimulatedUpdate();
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else if (ota.stage == OtaStage.readyForReboot) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isStationaryAndParked
                                ? AppColors.neonGreen
                                : AppColors.crimsonAlert,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isStationaryAndParked
                                  ? Icons.check_circle
                                  : Icons.warning_rounded,
                              color: isStationaryAndParked
                                  ? AppColors.neonGreen
                                  : AppColors.crimsonAlert,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isStationaryAndParked
                                    ? 'Pre-reboot safety interlock satisfied: Vehicle parked (0 km/h, Gear P).'
                                    : 'SAFETY INTERLOCK VIOLATION: Skateboard must be parked and stationary before reboot.',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStationaryAndParked
                                ? AppColors.neonGreen
                                : AppColors.surfaceBorder,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('REBOOT INTO UPGRADED SLOT'),
                          onPressed: isStationaryAndParked
                              ? () async {
                                  final confirmed =
                                      await SafetyConfirmationDialog.show(
                                        context,
                                        title:
                                            'Confirm System Partition Reboot',
                                        message:
                                            'The autonomous skateboard system will restart and boot from ${ota.inactiveSlot}. The platform will temporarily disconnect.',
                                        actionLabel: 'REBOOT NOW',
                                        actionColor: AppColors.neonGreen,
                                        isDangerous: false,
                                      );
                                  if (confirmed) {
                                    ref
                                        .read(otaProvider.notifier)
                                        .executeSimulatedReboot();
                                  }
                                }
                              : null,
                        ),
                      ),
                    ] else if (ota.stage == OtaStage.success) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.neonGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.neonGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ota.statusMessage ??
                                    'Update successfully applied.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.neonGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(otaProvider.notifier).cancelUpdate();
                          },
                          child: const Text('Abort Update'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // HawkBit & RAUC Pipeline Architecture Explainer
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECLIPSE LEDA UPDATE ARCHITECTURE',
                      style: AppTypography.labelBadge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPipelineStep(
                      step: '1',
                      title: 'Eclipse HawkBit DDI',
                      desc: 'Cloud repository orchestrates targets, rollouts, and signed bundle URLs.',
                    ),
                    _buildPipelineStep(
                      step: '2',
                      title: 'Software Update Agent (SUA)',
                      desc: 'Edge daemon polls HawkBit, authenticates via token, and downloads .raucb bundle.',
                    ),
                    _buildPipelineStep(
                      step: '3',
                      title: 'RAUC Partition Controller',
                      desc: 'Verifies X.509 certs, flashes passive slot (root_b), switches boot order.',
                    ),
                    _buildPipelineStep(
                      step: '4',
                      title: 'Kanto Auto-Deployer (KAD)',
                      desc: 'Updates container manifests for kuksa-databroker & feedercan on persistent /data partition.',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getStageColor(OtaStage stage) {
    switch (stage) {
      case OtaStage.idle:
        return AppColors.textSecondary;
      case OtaStage.checking:
      case OtaStage.downloading:
        return AppColors.electricCyan;
      case OtaStage.stagingRauc:
      case OtaStage.verifyingBundle:
        return AppColors.purpleAccent;
      case OtaStage.readyForReboot:
      case OtaStage.installing:
        return AppColors.amberWarning;
      case OtaStage.success:
        return AppColors.neonGreen;
      case OtaStage.failed:
        return AppColors.crimsonAlert;
    }
  }

  Widget _buildPartitionSlotCard({
    required String slotName,
    required String version,
    required bool isActive,
    required bool isTarget,
  }) {
    final borderColor = isActive
        ? AppColors.neonGreen
        : (isTarget ? AppColors.electricCyan : AppColors.surfaceBorder);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: isActive || isTarget ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slotName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonGreen,
                    ),
                  ),
                ),
              if (isTarget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'STAGING',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.electricCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            version,
            style: AppTypography.monospace.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOtaInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.monospace.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required String step,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.electricCyan),
              ),
              child: Text(
                step,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.electricCyan,
                ),
              ),
            ),
            if (!isLast)
              Container(width: 1, height: 36, color: AppColors.surfaceBorder),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodyMedium.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
