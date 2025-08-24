class EmergencyAction {
  final String id;
  final String journeyId;
  final String userId;
  final String action;
  final String audioUrl;

  EmergencyAction({required this.id, required this.journeyId, required this.userId, required this.action, required this.audioUrl});

  factory EmergencyAction.fromJson(Map<String, dynamic> json) => EmergencyAction(
    id: json['_id'] ?? '',
    journeyId: json['journeyId'],
    userId: json['userId'],
    action: json['action'],
    audioUrl: json['audioUrl'] ?? '',
  );
}
