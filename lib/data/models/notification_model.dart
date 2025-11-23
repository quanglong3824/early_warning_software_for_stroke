class NotificationModel {
  final String notificationId;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final int createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}
