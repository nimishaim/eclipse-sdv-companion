import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/app_settings_provider.dart';
import '../../state/telemetry_provider.dart';
import '../../state/vehicle_provider.dart';
import 'status_badge.dart';

class AutomotiveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AutomotiveAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final telemetryState = ref.watch(telemetryProvider);
    final selectedVehicle = ref.watch(selectedVehicleProvider);

    Widget statusWidget;
    if (settings.isDemoMode) {
      statusWidget = StatusBadge.simulated();
    } else {
      switch (telemetryState.status) {
        case TelemetryConnectionStatus.liveConnected:
          statusWidget = telemetryState.isStale
              ? StatusBadge.stale()
              : StatusBadge.live();
          break;
        case TelemetryConnectionStatus.stale:
          statusWidget = StatusBadge.stale();
          break;
        case TelemetryConnectionStatus.disconnected:
        case TelemetryConnectionStatus.error:
          statusWidget = StatusBadge.disconnected();
          break;
        default:
          statusWidget = StatusBadge.simulated();
      }
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(width: 8),
              if (selectedVehicle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(
                    selectedVehicle.profile.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.electricCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            selectedVehicle?.name ?? 'VIRYA APM Skateboard',
            style: AppTypography.bodyMedium.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Center(child: statusWidget),
        const SizedBox(width: 12),
        ...?actions,
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.surfaceBorder, height: 1),
      ),
    );
  }
}
