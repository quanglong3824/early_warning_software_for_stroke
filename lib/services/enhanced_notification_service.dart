import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/notification_model.dart';
import 'notification_service.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final NotificationService _notificationService = NotificationService();

  /// Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .child('notifications')
        .child(userId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final List<NotificationModel> notifications = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final notifData = Map<String, dynamic>.from(value as Map);
          notifications.add(NotificationModel.fromJson(notifData));
        });
      }
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Get unread count
  Stream<int> getUnreadCount(String userId) {
    return getUserNotifications(userId).map((notifications) {
      return notifications.where((n) => !n.isRead).length;
    });
  }

  /// Create notification and send push notification
  Future<String?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool sendPush = true,
  }) async {
    try {
      final notifRef = _db.child('notifications').child(userId).push();
      final notificationId = notifRef.key!;
      final now = DateTime.now().millisecondsSinceEpoch;

      final notification = NotificationModel(
        notificationId: notificationId,
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        isRead: false,
        createdAt: now,
      );

      await notifRef.set(notification.toJson());
      
      // Send FCM push notification if enabled
      if (sendPush) {
        await _sendFCMNotification(userId, title, message, type, data);
      }
      
      return notificationId;
    } catch (e) {
      print('Error creating notification: $e');
      return null;
    }
  }

  /// Send notification to multiple users
  Future<void> createNotificationForUsers({
    required List<String> userIds,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool sendPush = true,
  }) async {
    for (final userId in userIds) {
      await createNotification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        sendPush: sendPush,
      );
    }
  }

  /// Send notification to a topic (group notification)
  Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    // Topic notifications are handled by Firebase Cloud Functions
    // Store the notification request for the cloud function to process
    try {
      await _db.child('topic_notifications').push().set({
        'topic': topic,
        'title': title,
        'message': message,
        'data': data,
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
      });
    } catch (e) {
      print('Error sending topic notification: $e');
    }
  }

  /// Mark as read
  Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      await _db
          .child('notifications')
          .child(userId)
          .child(notificationId)
          .update({'isRead': true});
      return true;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final snapshot = await _db.child('notifications').child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (var key in data.keys) {
          await _db
              .child('notifications')
              .child(userId)
              .child(key)
              .update({'isRead': true});
        }
      }
      return true;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String userId, String notificationId) async {
    try {
      await _db
          .child('notifications')
          .child(userId)
          .child(notificationId)
          .remove();
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Clear all notifications
  Future<bool> clearAllNotifications(String userId) async {
    try {
      await _db.child('notifications').child(userId).remove();
      return true;
    } catch (e) {
      print('Error clearing notifications: $e');
      return false;
    }
  }

  /// Send FCM notification to a specific user
  Future<void> _sendFCMNotification(
    String userId,
    String title,
    String message,
    String type,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Get user's FCM token
      final tokenSnapshot = await _db.child('user_tokens').child(userId).get();
      
      if (!tokenSnapshot.exists) {
        print('No FCM token found for user: $userId');
        return;
      }
      
      final tokenData = Map<String, dynamic>.from(tokenSnapshot.value as Map);
      final fcmToken = tokenData['token'] as String?;
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM token is empty for user: $userId');
        return;
      }
      
      // Store the notification request for Firebase Cloud Function to send
      // This is the recommended approach as sending FCM from client requires server key
      await _db.child('fcm_notifications').push().set({
        'token': fcmToken,
        'title': title,
        'body': message,
        'data': {
          'type': type,
          'userId': userId,
          ...?data,
        },
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
      });
      
      print('FCM notification queued for user: $userId');
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  // ===== Notification Type Helpers =====

  /// Send prescription notification
  Future<String?> sendPrescriptionNotification({
    required String patientId,
    required String prescriptionId,
    required String doctorName,
  }) async {
    return await createNotification(
      userId: patientId,
      type: 'prescription',
      title: 'Đơn thuốc mới',
      message: 'Bác sĩ $doctorName đã kê đơn thuốc cho bạn',
      data: {
        'prescriptionId': prescriptionId,
        'route': '/prescriptions',
        'targetId': prescriptionId,
      },
    );
  }

  /// Send appointment notification
  Future<String?> sendAppointmentNotification({
    required String userId,
    required String appointmentId,
    required String status,
    String? doctorName,
    String? patientName,
  }) async {
    String title;
    String message;
    
    switch (status) {
      case 'confirmed':
        title = 'Lịch hẹn đã xác nhận';
        message = doctorName != null 
            ? 'Bác sĩ $doctorName đã xác nhận lịch hẹn của bạn'
            : 'Lịch hẹn của bạn đã được xác nhận';
        break;
      case 'cancelled':
        title = 'Lịch hẹn đã hủy';
        message = doctorName != null
            ? 'Bác sĩ $doctorName đã hủy lịch hẹn'
            : 'Lịch hẹn của bạn đã bị hủy';
        break;
      case 'rescheduled':
        title = 'Lịch hẹn đã đổi';
        message = 'Lịch hẹn của bạn đã được đổi sang thời gian mới';
        break;
      case 'new_request':
        title = 'Yêu cầu lịch hẹn mới';
        message = patientName != null
            ? 'Bệnh nhân $patientName đã gửi yêu cầu đặt lịch'
            : 'Có yêu cầu đặt lịch mới';
        break;
      default:
        title = 'Cập nhật lịch hẹn';
        message = 'Lịch hẹn của bạn đã được cập nhật';
    }
    
    return await createNotification(
      userId: userId,
      type: 'appointment',
      title: title,
      message: message,
      data: {
        'appointmentId': appointmentId,
        'status': status,
        'route': '/appointments',
        'targetId': appointmentId,
      },
    );
  }

  /// Send SOS notification
  Future<String?> sendSOSNotification({
    required String userId,
    required String sosId,
    required String status,
    String? patientName,
    String? doctorName,
  }) async {
    String title;
    String message;
    
    switch (status) {
      case 'acknowledged':
        title = 'SOS đã được tiếp nhận';
        message = doctorName != null
            ? 'Bác sĩ $doctorName đã tiếp nhận yêu cầu SOS của bạn'
            : 'Yêu cầu SOS của bạn đã được tiếp nhận';
        break;
      case 'new':
        title = '🚨 Cảnh báo SOS';
        message = patientName != null
            ? '$patientName đã kích hoạt SOS khẩn cấp!'
            : 'Có yêu cầu SOS khẩn cấp mới!';
        break;
      case 'resolved':
        title = 'SOS đã xử lý xong';
        message = 'Yêu cầu SOS của bạn đã được xử lý hoàn tất';
        break;
      default:
        title = 'Cập nhật SOS';
        message = 'Trạng thái SOS đã được cập nhật';
    }
    
    return await createNotification(
      userId: userId,
      type: 'sos',
      title: title,
      message: message,
      data: {
        'sosId': sosId,
        'status': status,
        'route': '/sos-status',
        'targetId': sosId,
      },
    );
  }

  /// Send chat notification
  Future<String?> sendChatNotification({
    required String userId,
    required String conversationId,
    required String senderName,
    required String messagePreview,
  }) async {
    return await createNotification(
      userId: userId,
      type: 'chat',
      title: 'Tin nhắn mới từ $senderName',
      message: messagePreview,
      data: {
        'conversationId': conversationId,
        'route': '/chat-detail',
        'targetId': conversationId,
      },
    );
  }

  /// Send payment notification
  Future<String?> sendPaymentNotification({
    required String userId,
    required String orderId,
    required String status,
    required double amount,
  }) async {
    String title;
    String message;
    
    switch (status) {
      case 'success':
        title = 'Thanh toán thành công';
        message = 'Đơn hàng của bạn đã được thanh toán thành công';
        break;
      case 'failed':
        title = 'Thanh toán thất bại';
        message = 'Thanh toán đơn hàng không thành công. Vui lòng thử lại';
        break;
      default:
        title = 'Cập nhật thanh toán';
        message = 'Trạng thái thanh toán đã được cập nhật';
    }
    
    return await createNotification(
      userId: userId,
      type: 'payment',
      title: title,
      message: message,
      data: {
        'orderId': orderId,
        'status': status,
        'amount': amount,
        'route': '/pharmacy/order-history',
        'targetId': orderId,
      },
    );
  }
}
