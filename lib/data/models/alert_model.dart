class AlertModel {
  final String id;
  final String patientId;
  final String patientName;
  final String level; // 'high', 'medium', 'low'
  final String message;
  final DateTime createdAt;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.level,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      level: json['level'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'level': level,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
