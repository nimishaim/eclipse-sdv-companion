enum CommandStatus { idle, pending, accepted, verified, failed }

class ControlCommand {
  final String id;
  final String name;
  final String parameter;
  final CommandStatus status;
  final String? statusMessage;
  final DateTime timestamp;
  final bool isSimulated;
  final bool requiresSafetyConfirmation;

  const ControlCommand({
    required this.id,
    required this.name,
    required this.parameter,
    required this.status,
    this.statusMessage,
    required this.timestamp,
    this.isSimulated = true,
    this.requiresSafetyConfirmation = false,
  });

  ControlCommand copyWith({
    String? id,
    String? name,
    String? parameter,
    CommandStatus? status,
    String? statusMessage,
    DateTime? timestamp,
    bool? isSimulated,
    bool? requiresSafetyConfirmation,
  }) {
    return ControlCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      parameter: parameter ?? this.parameter,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      timestamp: timestamp ?? this.timestamp,
      isSimulated: isSimulated ?? this.isSimulated,
      requiresSafetyConfirmation:
          requiresSafetyConfirmation ?? this.requiresSafetyConfirmation,
    );
  }
}
