import 'package:flutter/material.dart';

/// Premium dark automotive color palette designed for high legibility
/// in cockpit environments and autonomous vehicle monitoring stations.
class AppColors {
  AppColors._();

  // Backgrounds & Surface hierarchy
  static const Color background = Color(0xFF090D12);
  static const Color surface = Color(0xFF111720);
  static const Color surfaceElevated = Color(0xFF18202C);
  static const Color surfaceHighlight = Color(0xFF222D3E);
  static const Color surfaceBorder = Color(0xFF263346);

  // Brand & Electric Accent Colors
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color amberWarning = Color(0xFFFFB300);
  static const Color crimsonAlert = Color(0xFFFF3D57);
  static const Color purpleAccent = Color(0xFFB388FF);

  // Status Indicators
  static const Color statusLive = Color(0xFF00E676);
  static const Color statusSimulated = Color(0xFFFF9100);
  static const Color statusStale = Color(0xFFFFB300);
  static const Color statusDisconnected = Color(0xFFFF3D57);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Chart & Gauge Colors
  static const Color gaugeTrack = Color(0xFF1E2837);
  static const Color gaugeFill = Color(0xFF00E5FF);
  static const Color gaugeCritical = Color(0xFFFF3D57);
}
