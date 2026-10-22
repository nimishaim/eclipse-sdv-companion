import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

class StaleIndicatorBanner extends StatelessWidget {
  final bool isStale;
  final bool isDisconnected;
  final DateTime lastUpdated;
  final VoidCallback? onReconnect;

  const StaleIndicatorBanner({
    super.key,
    required this.isStale,
    required this.isDisconnected,
    required this.lastUpdated,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    if (!isStale && !isDisconnected) return const SizedBox.shrink();

    final isError = isDisconnected;
    final color = isError ? AppColors.crimsonAlert : AppColors.amberWarning;
    final title = isError
        ? 'VEHICLE DISCONNECTED / OFFLINE'
        : 'TELEMETRY STALE (> 5 SECONDS)';
    final description = isError
        ? 'Cannot reach edge ingestion endpoint. Last signal was recorded at ${Formatters.time(lastUpdated)}.'
        : 'CAN signals are delayed or stopped. Last frame received ${Formatters.timeAgo(lastUpdated)}.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.cloud_off : Icons.history_toggle_off,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.labelBadge.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onReconnect != null) ...[
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onReconnect,
              child: const Text(
                'RETRY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
