import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/app_settings_provider.dart';
import '../../../state/auth_provider.dart';
import '../../widgets/automotive_app_bar.dart';
import '../auth/demo_auth_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ref.read(appSettingsProvider).baseUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const AutomotiveAppBar(title: 'Settings & Edge Diagnostics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Switcher Card
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: settings.isDemoMode
                      ? AppColors.statusSimulated
                      : AppColors.neonGreen,
                  width: 1.2,
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
                          'DATA SOURCE MODE',
                          style: AppTypography.labelBadge.copyWith(
                            color: settings.isDemoMode
                                ? AppColors.statusSimulated
                                : AppColors.neonGreen,
                          ),
                        ),
                        Switch(
                          value: !settings.isDemoMode,
                          activeThumbColor: AppColors.neonGreen,
                          inactiveThumbColor: AppColors.statusSimulated,
                          onChanged: (isLive) {
                            ref
                                .read(appSettingsProvider.notifier)
                                .setDemoMode(!isLive);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settings.isDemoMode
                          ? 'Demo Mode Active (Simulated APM Skateboard)'
                          : 'Live Mode Active (Central Node Stream)',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settings.isDemoMode
                          ? 'Using local autonomous simulation with realistic dynamic telemetry, gear changes, E-Stop safety interlocks, and RAUC A/B updates.'
                          : 'Connecting to external FastAPI ingestion gateway and WebSocket streamer. Stale data warning will trip if frames pause > 5s.',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingestion Backend Configuration Card
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
                      'CENTRAL INGESTION GATEWAY (JETSON / NGROK)',
                      style: AppTypography.labelBadge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _urlController,
                      style: AppTypography.monospace,
                      decoration: InputDecoration(
                        labelText: 'Backend Base URL',
                        hintText: 'http://10.1.30.193:8000',
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: AppColors.electricCyan,
                          ),
                          onPressed: () {
                            ref
                                .read(appSettingsProvider.notifier)
                                .setBaseUrl(_urlController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Backend base URL saved successfully.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildPresetChip(
                          label: 'Local Jetson (:8000)',
                          url: ApiConstants.defaultLocalBaseUrl,
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          label: 'ngrok Gateway',
                          url: ApiConstants.defaultNgrokBaseUrl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        icon: settings.isPinging
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.network_ping, size: 18),
                        label: const Text('Test Connection & Latency (Ping)'),
                        onPressed: settings.isPinging
                            ? null
                            : () {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setBaseUrl(_urlController.text.trim());
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .pingBackend();
                              },
                      ),
                    ),
                    if (settings.lastPing != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (settings.lastPing!.isHealthy
                                      ? AppColors.neonGreen
                                      : AppColors.crimsonAlert)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (settings.lastPing!.isHealthy
                                        ? AppColors.neonGreen
                                        : AppColors.crimsonAlert)
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              settings.lastPing!.isHealthy
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: settings.lastPing!.isHealthy
                                  ? AppColors.neonGreen
                                  : AppColors.crimsonAlert,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                settings.lastPing!.isHealthy
                                    ? 'Connected (${settings.lastPing!.latencyMs} ms, HTTP ${settings.lastPing!.statusCode})'
                                    : 'Connection failed: ${settings.lastPing!.errorMessage ?? "Unreachable"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: settings.lastPing!.isHealthy
                                      ? AppColors.neonGreen
                                      : AppColors.crimsonAlert,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Operator Profile / Demo Auth Card
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
                          'OPERATOR DEMO PROFILE',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DemoAuthScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Switch Role',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (authState.operator != null) ...[
                      Text(
                        authState.operator!.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${authState.operator!.role} • ${authState.operator!.accessLevel}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.electricCyan,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authState.operator!.email,
                        style: AppTypography.monospace.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ] else ...[
                      const Text('No operator session authenticated.'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Network Topology & Port Diagnostics
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
                          Icons.lan_outlined,
                          size: 18,
                          color: AppColors.electricCyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SDV NETWORK PORT MATRIX',
                          style: AppTypography.labelBadge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPortRow(
                      'feedercan → kuksa-databroker',
                      '55555',
                      'gRPC (In-Vehicle VSS)',
                    ),
                    _buildPortRow(
                      'telemetry → kuksa-databroker',
                      '55555',
                      'gRPC (VSS Subscription)',
                    ),
                    _buildPortRow(
                      'telemetry (VM) → Jetson',
                      '8000',
                      'HTTP POST /api/v1/telemetry',
                    ),
                    _buildPortRow(
                      'Jetson → Companion App',
                      '8000',
                      'WebSocket /ws/telemetry',
                    ),
                    _buildPortRow(
                      'ngrok Gateway Relay',
                      '443',
                      'HTTPS / WSS Reverse Proxy',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Build Information
            Center(
              child: Column(
                children: [
                  const Text(
                    'Eclipse SDV Companion • VIRYA APM v1.0.0+1',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Eclipse Leda genericx86-64 • Kuksa v0.4.1 • Kanto CM',
                    style: AppTypography.monospace.copyWith(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({required String label, required String url}) {
    return ActionChip(
      backgroundColor: AppColors.surfaceElevated,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        _urlController.text = url;
        ref.read(appSettingsProvider.notifier).setBaseUrl(url);
      },
    );
  }

  Widget _buildPortRow(String flow, String port, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flow,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Text(
              ':$port',
              style: AppTypography.monospace.copyWith(
                fontSize: 11,
                color: AppColors.electricCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
