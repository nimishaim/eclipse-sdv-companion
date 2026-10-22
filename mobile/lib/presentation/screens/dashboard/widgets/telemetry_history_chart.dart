import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class TelemetryHistoryChart extends StatelessWidget {
  final List<double> values;
  final String title;
  final String unit;
  final Color lineColor;

  const TelemetryHistoryChart({
    super.key,
    required this.values,
    this.title = 'Speed Telemetry History (Last 30s)',
    this.unit = 'km/h',
    this.lineColor = AppColors.electricCyan,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxVal = values.reduce(max);
    final minVal = values.reduce(min);
    final currentVal = values.last;

    return Card(
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
                Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      size: 16,
                      color: AppColors.electricCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title.toUpperCase(),
                      style: AppTypography.labelBadge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${currentVal.toStringAsFixed(1)} $unit',
                  style: AppTypography.monospace.copyWith(
                    color: lineColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'MIN: ${minVal.toStringAsFixed(1)} $unit',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 10),
                ),
                const SizedBox(width: 12),
                Text(
                  'MAX: ${maxVal.toStringAsFixed(1)} $unit',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: values,
                  lineColor: lineColor,
                  minVal: min(minVal, 0.0),
                  maxVal: max(maxVal, 50.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final double minVal;
  final double maxVal;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.minVal,
    required this.maxVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final width = size.width;
    final height = size.height;
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.surfaceBorder.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    final points = <Offset>[];
    final stepX = width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final normalizedY = (values[i] - minVal) / range;
      final y = height - (normalizedY * height).clamp(0.0, height);
      points.add(Offset(i * stepX, y));
    }

    // Build smooth path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Draw gradient fill under the line
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, height)
      ..lineTo(points.first.dx, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw stroke line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Highlight the latest data point with glowing dot
    final lastPoint = points.last;
    final haloPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 6, haloPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
