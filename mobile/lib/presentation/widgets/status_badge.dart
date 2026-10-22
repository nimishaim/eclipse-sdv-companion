import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.live() {
    return const StatusBadge(
      label: 'LIVE VSS',
      color: AppColors.statusLive,
      icon: Icons.wifi,
    );
  }

  factory StatusBadge.simulated() {
    return const StatusBadge(
      label: 'SIMULATED DEMO',
      color: AppColors.statusSimulated,
      icon: Icons.science_outlined,
    );
  }

  factory StatusBadge.stale() {
    return const StatusBadge(
      label: 'DATA STALE (>5s)',
      color: AppColors.statusStale,
      icon: Icons.timer_outlined,
    );
  }

  factory StatusBadge.disconnected() {
    return const StatusBadge(
      label: 'OFFLINE / DISCONNECTED',
      color: AppColors.statusDisconnected,
      icon: Icons.wifi_off,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.labelBadge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
