import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/control_command.dart';
import 'vehicle_provider.dart';
import 'app_settings_provider.dart';

class ControlState {
  final List<ControlCommand> commandHistory;
  final ControlCommand? activeCommand;
  final bool isHazardActive;
  final String activeProfile;

  const ControlState({
    required this.commandHistory,
    this.activeCommand,
    this.isHazardActive = false,
    this.activeProfile = 'apm_dbw',
  });

  ControlState copyWith({
    List<ControlCommand>? commandHistory,
    ControlCommand? activeCommand,
    bool? isHazardActive,
    String? activeProfile,
  }) {
    return ControlState(
      commandHistory: commandHistory ?? this.commandHistory,
      activeCommand: activeCommand,
      isHazardActive: isHazardActive ?? this.isHazardActive,
      activeProfile: activeProfile ?? this.activeProfile,
    );
  }
}

class ControlNotifier extends Notifier<ControlState> {
  @override
  ControlState build() {
    return const ControlState(commandHistory: [], activeProfile: 'apm_dbw');
  }

  Future<void> sendCommand({
    required String name,
    required String parameter,
    bool requiresSafetyConfirmation = false,
  }) async {
    final isDemo = ref.read(appSettingsProvider).isDemoMode;
    final repo = ref.read(vehicleRepositoryProvider);

    final newCmd = ControlCommand(
      id: 'CMD-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      parameter: parameter,
      status: CommandStatus.pending,
      statusMessage: 'Transmitting command request to vehicle bus...',
      timestamp: DateTime.now(),
      isSimulated: isDemo,
      requiresSafetyConfirmation: requiresSafetyConfirmation,
    );

    state = state.copyWith(
      activeCommand: newCmd,
      commandHistory: [newCmd, ...state.commandHistory],
    );

    // Simulate acknowledgement phase
    await Future.delayed(const Duration(milliseconds: 300));
    final acceptedCmd = newCmd.copyWith(
      status: CommandStatus.accepted,
      statusMessage: 'Command received by vehicle gateway.',
    );
    _updateCommandInHistory(acceptedCmd);

    // Verification or execution phase
    await Future.delayed(const Duration(milliseconds: 400));
    final resultCmd = await repo.executeCommand(acceptedCmd);

    if (name == 'switch_vehicle_profile' &&
        resultCmd.status == CommandStatus.verified) {
      state = state.copyWith(activeProfile: parameter);
    }

    _updateCommandInHistory(resultCmd);
    state = state.copyWith(activeCommand: null);
  }

  void toggleHazardLights() {
    state = state.copyWith(isHazardActive: !state.isHazardActive);
    sendCommand(
      name: 'hazard_lights',
      parameter: state.isHazardActive ? 'ON' : 'OFF',
    );
  }

  void _updateCommandInHistory(ControlCommand updated) {
    final list = state.commandHistory.map((c) {
      return c.id == updated.id ? updated : c;
    }).toList();
    state = state.copyWith(
      activeCommand:
          updated.status == CommandStatus.verified ||
              updated.status == CommandStatus.failed
          ? null
          : updated,
      commandHistory: list,
    );
  }
}

final controlProvider = NotifierProvider<ControlNotifier, ControlState>(
  ControlNotifier.new,
);
