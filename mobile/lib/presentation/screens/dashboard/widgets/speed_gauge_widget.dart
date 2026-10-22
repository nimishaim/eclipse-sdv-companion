import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SpeedGaugeWidget extends StatelessWidget {
  final double speedKmh;
  final double maxSpeed;
  final String gear;

  const SpeedGaugeWidget({
    super.key,
    required this.speedKmh,
    this.maxSpeed = 60.0,
    required this.gear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _SpeedGaugePainter(speed: speedKmh, maxSpeed: maxSpeed),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speedKmh.toStringAsFixed(1),
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text('KM / H', style: AppTypography.telemetryUnit),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: gear == 'D'
                        ? AppColors.neonGreen
                        : (gear == 'R'
                              ? AppColors.crimsonAlert
                              : AppColors.surfaceBorder),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  'GEAR  $gear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: gear == 'D'
                        ? AppColors.neonGreen
                        : (gear == 'R'
                              ? AppColors.crimsonAlert
                              : AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;

  _SpeedGaugePainter({required this.speed, required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    final trackPaint = Paint()
      ..color = AppColors.gaugeTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final progress = (speed / maxSpeed).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * progress;

    if (activeSweep > 0) {
      final activePaint = Paint()
        ..shader = const SweepGradient(
          startAngle: 135 * (pi / 180),
          endAngle: 405 * (pi / 180),
          colors: [
            AppColors.electricCyan,
            AppColors.electricBlue,
            AppColors.neonGreen,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    final tickPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 12; i++) {
      final tickAngle = startAngle + (sweepAngle * (i / 12));
      final innerRadius = radius - 14;
      final outerRadius = radius - 8;

      final p1 = Offset(
        center.dx + innerRadius * cos(tickAngle),
        center.dy + innerRadius * sin(tickAngle),
      );
      final p2 = Offset(
        center.dx + outerRadius * cos(tickAngle),
        center.dy + outerRadius * sin(tickAngle),
      );

      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.maxSpeed != maxSpeed;
  }
}
