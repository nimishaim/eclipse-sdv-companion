import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/vehicle_provider.dart';
import '../../../state/telemetry_provider.dart';
import '../../../state/app_settings_provider.dart';
import '../../widgets/automotive_app_bar.dart';
import '../../widgets/status_badge.dart';

class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesFutureProvider);
    final selectedVehicle = ref.watch(selectedVehicleProvider);
    final telemetryState = ref.watch(telemetryProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: const AutomotiveAppBar(title: 'Vehicle & VSS Architecture'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: settings.isDemoMode
                    ? AppColors.statusSimulated.withValues(alpha: 0.12)
                    : AppColors.statusLive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: settings.isDemoMode
                      ? AppColors.statusSimulated.withValues(alpha: 0.4)
                      : AppColors.statusLive.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    settings.isDemoMode
                        ? Icons.science_outlined
                        : Icons.sensors_outlined,
                    color: settings.isDemoMode
                        ? AppColors.statusSimulated
                        : AppColors.statusLive,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      settings.isDemoMode
                          ? 'DEMO MODE: Running autonomous skateboard simulation. Telemetry and DBC profiles are modeled locally.'
                          : 'LIVE MODE: Streaming vehicle signals from edge Kuksa broker and Jetson backend.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Selector Dropdown Card
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
                          'INVENTORY / FLEET INSTANCE',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (selectedVehicle?.isOnline == true)
                          StatusBadge.live()
                        else
                          StatusBadge.disconnected(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    vehiclesAsync.when(
                      data: (list) {
                        return DropdownButtonFormField<String>(
                          initialValue: selectedVehicle?.id,
                          decoration: const InputDecoration(
                            labelText: 'Active Autonomous Platform',
                            prefixIcon: Icon(
                              Icons.directions_car,
                              color: AppColors.electricCyan,
                            ),
                          ),
                          dropdownColor: AppColors.surfaceElevated,
                          items: list.map((v) {
                            return DropdownMenuItem<String>(
                              value: v.id,
                              child: Text(
                                '${v.name} (${v.id})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              ref
                                  .read(selectedVehicleIdProvider.notifier)
                                  .select(id);
                            }
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Failed to load vehicle list: $err',
                        style: const TextStyle(color: AppColors.crimsonAlert),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedVehicle != null) ...[
                      _buildDetailRow('Platform VIN', selectedVehicle.vin),
                      _buildDetailRow(
                        'Active Profile',
                        selectedVehicle.profile,
                      ),
                      _buildDetailRow(
                        'OS Environment',
                        selectedVehicle.hardwarePlatform,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // COVESA VSS Signal Specification Catalog
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
                      children: [
                        const Icon(
                          Icons.hub_outlined,
                          size: 18,
                          color: AppColors.electricCyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'COVESA VSS SIGNAL MATRIX (kuksa.val)',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSignalItem(
                      path: 'Vehicle.Speed',
                      dbcSource: 'DI_vehicleSpeed (CAN 0x116)',
                      currentVal:
                          '${telemetryState.telemetry.speedKmh.toStringAsFixed(1)} km/h',
                      status: 'STREAMING',
                    ),
                    const Divider(),
                    _buildSignalItem(
                      path: 'Vehicle.Powertrain.TractionBattery.StateOfCharge.Current',
                      dbcSource: 'BMS_StateOfCharge (CAN 0x220)',
                      currentVal:
                          '${telemetryState.telemetry.batterySoc.toStringAsFixed(1)} %',
                      status: 'STREAMING',
                    ),
                    const Divider(),
                    _buildSignalItem(
                      path: 'Vehicle.Chassis.SteeringWheel.Angle',
                      dbcSource: 'STEER_SteeringAngle (CAN 0x082)',
                      currentVal:
                          '${telemetryState.telemetry.steeringAngle.toStringAsFixed(1)}°',
                      status: 'STREAMING',
                    ),
                    const Divider(),
                    _buildSignalItem(
                      path: 'Vehicle.Powertrain.Transmission.CurrentGear',
                      dbcSource: 'GEAR_SelectedGear (CAN 0x140)',
                      currentVal: telemetryState.telemetry.gear,
                      status: 'STREAMING',
                    ),
                    const Divider(),
                    _buildSignalItem(
                      path: 'Vehicle.Powertrain.ElectricMotor.Temperature',
                      dbcSource: 'INV_MotorTemp (CAN 0x310)',
                      currentVal:
                          '${telemetryState.telemetry.motorTempC.toStringAsFixed(1)} °C',
                      status: 'STREAMING',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hardware & Software Stack Details
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
                      children: [
                        const Icon(
                          Icons.memory,
                          size: 18,
                          color: AppColors.neonGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EDGE ECU SUBSYSTEM SPECIFICATIONS',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Edge Node',
                      'Eclipse Leda Yocto Linux (genericx86-64)',
                    ),
                    _buildDetailRow(
                      'Boot Provider',
                      'UEFI systemd-boot (A/B rootfs)',
                    ),
                    _buildDetailRow(
                      'CAN Controller',
                      'PEAK PCAN-USB transceiver (can0 @ 500kbps)',
                    ),
                    _buildDetailRow(
                      'CAN Feeder',
                      'feedercan (dbc2val) - AF_CAN SOCK_RAW',
                    ),
                    _buildDetailRow(
                      'Vehicle Data Broker',
                      'kuksa-databroker (v0.4.1 gRPC :55555)',
                    ),
                    _buildDetailRow(
                      'Edge Container Runtime',
                      'Eclipse Kanto (kanto-cm daemon)',
                    ),
                    _buildDetailRow(
                      'Central Ingestion Node',
                      'NVIDIA Jetson (FastAPI :8000)',
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

  Widget _buildDetailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.monospace.copyWith(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalItem({
    required String path,
    required String dbcSource,
    required String currentVal,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricCyan,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Source: $dbcSource',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currentVal,
                style: AppTypography.monospace.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
