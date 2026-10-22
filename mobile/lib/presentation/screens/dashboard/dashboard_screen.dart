import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/telemetry_provider.dart';
import '../../../state/vehicle_provider.dart';
import '../../../state/app_settings_provider.dart';
import '../../widgets/automotive_app_bar.dart';
import 'widgets/speed_gauge_widget.dart';
import 'widgets/telemetry_card.dart';
import 'widgets/telemetry_history_chart.dart';
import 'widgets/stale_indicator_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryState = ref.watch(telemetryProvider);
    final telemetry = telemetryState.telemetry;
    final selectedVehicle = ref.watch(selectedVehicleProvider);
    final settings = ref.watch(appSettingsProvider);

    final isDisconnected =
        telemetryState.status == TelemetryConnectionStatus.disconnected ||
        telemetryState.status == TelemetryConnectionStatus.error;

    return Scaffold(
      appBar: const AutomotiveAppBar(title: 'Cockpit Dashboard'),
      body: RefreshIndicator(
        color: AppColors.electricCyan,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async {
          if (!settings.isDemoMode) {
            ref.read(telemetryProvider.notifier).refreshListener();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stale / Disconnected banner
              StaleIndicatorBanner(
                isStale: telemetryState.isStale,
                isDisconnected: isDisconnected,
                lastUpdated: telemetryState.lastReceived,
                onReconnect: () {
                  ref.read(appSettingsProvider.notifier).pingBackend();
                },
              ),

              // Hero Speedometer Card
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: telemetry.emergencyStop
                                      ? AppColors.crimsonAlert
                                      : AppColors.neonGreen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedVehicle?.name ?? 'VIRYA APM Skateboard',
                                style: AppTypography.titleMedium,
                              ),
                            ],
                          ),
                          Text(
                            telemetry.activeProfile?.toUpperCase() ?? 'APM_DBW',
                            style: AppTypography.monospace.copyWith(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SpeedGaugeWidget(
                        speedKmh: telemetry.speedKmh,
                        gear: telemetry.gear,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickStat(
                            'DRIVE MODE',
                            telemetry.emergencyStop
                                ? 'E-STOPPED'
                                : 'AUTONOMOUS',
                            telemetry.emergencyStop
                                ? AppColors.crimsonAlert
                                : AppColors.electricCyan,
                          ),
                          _buildQuickStat(
                            'CAN BUS',
                            '500 KBPS (can0)',
                            AppColors.textSecondary,
                          ),
                          _buildQuickStat(
                            'VSS BROKER',
                            'gRPC :55555',
                            AppColors.neonGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Telemetry Grid (Battery, Steering, Temp, Safety)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  TelemetryCard(
                    title: 'Battery SOC',
                    value: Formatters.speed(telemetry.batterySoc),
                    unit: '%',
                    icon: Icons.battery_charging_full_rounded,
                    accentColor: telemetry.batterySoc < 20
                        ? AppColors.crimsonAlert
                        : (telemetry.batterySoc < 50
                              ? AppColors.amberWarning
                              : AppColors.neonGreen),
                    subtext: '400V Traction Pack',
                  ),
                  TelemetryCard(
                    title: 'Steering Angle',
                    value: Formatters.speed(telemetry.steeringAngle.abs()),
                    unit:
                        '° ${telemetry.steeringAngle < -0.5 ? "L" : (telemetry.steeringAngle > 0.5 ? "R" : "C")}',
                    icon: Icons.alt_route_rounded,
                    accentColor: AppColors.electricCyan,
                    subtext: 'Drive-by-Wire Actuator',
                  ),
                  TelemetryCard(
                    title: 'Motor Temp',
                    value: Formatters.speed(telemetry.motorTempC),
                    unit: '°C',
                    icon: Icons.thermostat_outlined,
                    accentColor: telemetry.motorTempC > 65
                        ? AppColors.crimsonAlert
                        : AppColors.purpleAccent,
                    subtext: 'Inverter Coolant: 34°C',
                  ),
                  TelemetryCard(
                    title: 'Safety E-Stop',
                    value: telemetry.emergencyStop ? 'ACTIVE' : 'READY',
                    unit: '',
                    icon: telemetry.emergencyStop
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    accentColor: telemetry.emergencyStop
                        ? AppColors.crimsonAlert
                        : AppColors.neonGreen,
                    subtext: telemetry.emergencyStop
                        ? 'Hard Braking Engaged'
                        : 'Safe to Operate',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sparkline Chart
              TelemetryHistoryChart(
                values: telemetryState.speedHistory,
                title: 'Live Speed Trend',
                unit: 'km/h',
                lineColor: AppColors.electricCyan,
              ),
              const SizedBox(height: 16),

              // Signal Metadata & Provenance Card
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TELEMETRY PROVENANCE',
                            style: AppTypography.labelBadge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            Formatters.timeAgo(telemetryState.lastReceived),
                            style: AppTypography.monospace.copyWith(
                              color: AppColors.electricCyan,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildProvenanceRow(
                        'VSS Signal Path',
                        'Vehicle.Speed / Vehicle.Powertrain.*',
                      ),
                      _buildProvenanceRow(
                        'Ingestion Gateway',
                        settings.isDemoMode
                            ? 'Internal Virtual Model'
                            : settings.baseUrl,
                      ),
                      _buildProvenanceRow(
                        'Timestamp',
                        Formatters.dateTime(telemetry.timestamp),
                      ),
                      _buildProvenanceRow(
                        'Data Mode',
                        settings.isDemoMode
                            ? 'SIMULATED (Realistic VIRYA APM dynamic trajectory)'
                            : 'LIVE CAN / VSS INGESTION STREAM',
                        color: settings.isDemoMode
                            ? AppColors.statusSimulated
                            : AppColors.neonGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProvenanceRow(String key, String value, {Color? color}) {
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
              style: AppTypography.monospace.copyWith(
                fontSize: 11,
                color: color ?? AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
