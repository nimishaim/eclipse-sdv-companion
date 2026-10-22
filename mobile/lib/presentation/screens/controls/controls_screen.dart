import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/control_command.dart';
import '../../../state/control_provider.dart';
import '../../../state/telemetry_provider.dart';
import '../../../state/app_settings_provider.dart';
import '../../widgets/automotive_app_bar.dart';
import '../../widgets/confirmation_dialog.dart';

class ControlsScreen extends ConsumerWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlState = ref.watch(controlProvider);
    final telemetry = ref.watch(telemetryProvider).telemetry;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: const AutomotiveAppBar(title: 'Vehicle Actuation & Controls'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safety Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.amberWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      settings.isDemoMode
                          ? 'DEMO ACTUATION: Commands are executed on virtual local skateboard state machine with verified feedback.'
                          : 'LIVE ACTUATION: Direct CAN writes are locked until two-way CAN actuation RPC endpoint is authenticated.',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Stop Card (High Consequence)
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: telemetry.emergencyStop
                      ? AppColors.crimsonAlert
                      : AppColors.surfaceBorder,
                  width: telemetry.emergencyStop ? 1.5 : 1,
                ),
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
                          'PRIMARY SAFETY SYSTEM',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.crimsonAlert,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (telemetry.emergencyStop
                                        ? AppColors.crimsonAlert
                                        : AppColors.neonGreen)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            telemetry.emergencyStop
                                ? 'E-STOP TRIPPED'
                                : 'SYSTEM NOMINAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: telemetry.emergencyStop
                                  ? AppColors.crimsonAlert
                                  : AppColors.neonGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Emergency Braking & Bus Disconnect',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Immediately cuts traction inverter torque, applies electromagnetic parking brake, and shifts APM transmission to Park.',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (!telemetry.emergencyStop)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.crimsonAlert,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.dangerous_outlined),
                          label: const Text('ENGAGE EMERGENCY STOP'),
                          onPressed: () async {
                            final confirmed =
                                await SafetyConfirmationDialog.show(
                                  context,
                                  title: 'Confirm Emergency Braking',
                                  message: 'Are you sure you want to engage Emergency Stop on the VIRYA APM Skateboard? This will immediately lock the brakes and halt the vehicle.',
                                  actionLabel: 'ENGAGE E-STOP',
                                  actionColor: AppColors.crimsonAlert,
                                  isDangerous: true,
                                );
                            if (confirmed) {
                              ref
                                  .read(controlProvider.notifier)
                                  .sendCommand(
                                    name: 'emergency_stop_trigger',
                                    parameter: 'HARD_STOP',
                                    requiresSafetyConfirmation: true,
                                  );
                            }
                          },
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amberWarning,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('RELEASE EMERGENCY STOP & RE-ARM'),
                          onPressed: () async {
                            final confirmed =
                                await SafetyConfirmationDialog.show(
                                  context,
                                  title: 'Confirm E-Stop Release',
                                  message: 'Verify that the vehicle pathway is completely clear and the platform is safe before re-arming the APM drive system.',
                                  actionLabel: 'RELEASE & RE-ARM',
                                  actionColor: AppColors.amberWarning,
                                  isDangerous: false,
                                );
                            if (confirmed) {
                              ref
                                  .read(controlProvider.notifier)
                                  .sendCommand(
                                    name: 'emergency_stop_release',
                                    parameter: 'ARM_READY',
                                    requiresSafetyConfirmation: true,
                                  );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Drive Selector (P, R, N, D)
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
                      'DRIVE-BY-WIRE GEAR SELECTION',
                      style: AppTypography.labelBadge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['P', 'R', 'N', 'D'].map((gear) {
                        final isSelected = telemetry.gear == gear;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: InkWell(
                              onTap: () {
                                ref
                                    .read(controlProvider.notifier)
                                    .sendCommand(
                                      name: 'set_gear',
                                      parameter: gear,
                                    );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.electricCyan.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.electricCyan
                                        : AppColors.surfaceBorder,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  gear,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.electricCyan
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Auxiliary Skateboard Controls (Hazard Lights & Vehicle Profile)
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
                      'VEHICLE PROFILE & SAFETY BEACON',
                      style: AppTypography.labelBadge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: controlState.isHazardActive
                              ? AppColors.amberWarning.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: controlState.isHazardActive
                              ? AppColors.amberWarning
                              : AppColors.textSecondary,
                        ),
                      ),
                      title: const Text('Hazard Warning Lights'),
                      subtitle: Text(
                        controlState.isHazardActive
                            ? 'Flashing (CAN ID 0x301)'
                            : 'Standby',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Switch(
                        value: controlState.isHazardActive,
                        activeThumbColor: AppColors.amberWarning,
                        onChanged: (_) {
                          ref
                              .read(controlProvider.notifier)
                              .toggleHazardLights();
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: AppColors.electricCyan,
                        ),
                      ),
                      title: const Text('Switch CAN DBC Profile'),
                      subtitle: Text(
                        'Active: ${controlState.activeProfile} (/data/var/config/vehicle/)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: DropdownButton<String>(
                        value: controlState.activeProfile,
                        dropdownColor: AppColors.surfaceElevated,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: 'apm_dbw',
                            child: Text('apm_dbw (Skateboard)'),
                          ),
                          DropdownMenuItem(
                            value: 'model3',
                            child: Text('model3 (Fallback)'),
                          ),
                        ],
                        onChanged: (profile) async {
                          if (profile != null &&
                              profile != controlState.activeProfile) {
                            final confirmed = await SafetyConfirmationDialog.show(
                              context,
                              title: 'Switch Vehicle DBC Profile',
                              message:
                                  'Switching profile will re-point active.dbc to $profile and restart feedercan. Do you wish to proceed?',
                              actionLabel: 'SWITCH PROFILE',
                              actionColor: AppColors.electricCyan,
                              isDangerous: false,
                            );
                            if (confirmed) {
                              ref
                                  .read(controlProvider.notifier)
                                  .sendCommand(
                                    name: 'switch_vehicle_profile',
                                    parameter: profile,
                                    requiresSafetyConfirmation: true,
                                  );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Command Verification Audit Log
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTUATION AUDIT TRAIL',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${controlState.commandHistory.length} EVENTS',
                          style: AppTypography.monospace.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (controlState.commandHistory.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'No actuation commands dispatched in this session.',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      ...controlState.commandHistory.take(6).map((cmd) {
                        return _buildCommandAuditItem(cmd);
                      }),
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

  Widget _buildCommandAuditItem(ControlCommand cmd) {
    Color statusColor;
    String statusText;
    IconData icon;

    switch (cmd.status) {
      case CommandStatus.pending:
        statusColor = AppColors.electricCyan;
        statusText = 'PENDING';
        icon = Icons.hourglass_top;
        break;
      case CommandStatus.accepted:
        statusColor = AppColors.amberWarning;
        statusText = 'ACCEPTED';
        icon = Icons.done;
        break;
      case CommandStatus.verified:
        statusColor = AppColors.neonGreen;
        statusText = 'VERIFIED';
        icon = Icons.verified_outlined;
        break;
      case CommandStatus.failed:
        statusColor = AppColors.crimsonAlert;
        statusText = 'FAILED / BLOCKED';
        icon = Icons.block;
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusText = 'IDLE';
        icon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    '${cmd.name} (${cmd.parameter})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (cmd.statusMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              cmd.statusMessage!,
              style: AppTypography.bodyMedium.copyWith(fontSize: 11),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.time(cmd.timestamp),
                style: AppTypography.monospace.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                cmd.isSimulated ? '[SIMULATED]' : '[LIVE EDGE]',
                style: TextStyle(
                  fontSize: 10,
                  color: cmd.isSimulated
                      ? AppColors.statusSimulated
                      : AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
