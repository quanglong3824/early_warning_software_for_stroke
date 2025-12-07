class ConversationModel {
  final String conversationId;
  final String userId;
  final String doctorId;
  final String? doctorName;
  final String? patientName;
  final String? patientAvatar;
  final String? lastMessage;
  final int? lastMessageTime;
  final int userUnreadCount;
  final int doctorUnreadCount;
  final bool isOnline;
  final int createdAt;
  final int updatedAt;

  ConversationModel({
    required this.conversationId,
    required this.userId,
    required this.doctorId,
    this.doctorName,
    this.patientName,
    this.patientAvatar,
    this.lastMessage,
    this.lastMessageTime,
    required this.userUnreadCount,
    required this.doctorUnreadCount,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversationId'] ?? '',
      userId: json['userId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'],
      patientName: json['patientName'],
      patientAvatar: json['patientAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'],
      userUnreadCount: json['userUnreadCount'] ?? 0,
      doctorUnreadCount: json['doctorUnreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: json['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientName': patientName,
      'patientAvatar': patientAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'userUnreadCount': userUnreadCount,
      'doctorUnreadCount': doctorUnreadCount,
      'isOnline': isOnline,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class MessageModel {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String message;
  final String type; // text, image, file, prescription
  final String? prescriptionId; // For prescription messages
  final int timestamp;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.message,
    required this.type,
    this.prescriptionId,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'],
      message: json['message'] ?? '',
      type: json['type'] ?? 'text',
      prescriptionId: json['prescriptionId'],
      // Support both 'createdAt' (from Firebase) and 'timestamp' for backward compatibility
      timestamp: json['createdAt'] ?? json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      isRead: json['isRead'] ?? json['status'] == 'read',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type,
      'prescriptionId': prescriptionId,
      'createdAt': timestamp,  // Save as 'createdAt' in Firebase
      'isRead': isRead,
    };
  }
}

