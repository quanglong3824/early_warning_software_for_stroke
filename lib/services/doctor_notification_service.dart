import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../data/models/notification_model.dart';
import 'enhanced_notification_service.dart';

/// Service quản lý thông báo cho bác sĩ
/// Requirements: 10.1, 10.2, 10.3, 10.4, 10.5
class DoctorNotificationService {
  static final DoctorNotificationService _instance = DoctorNotificationService._internal();
  factory DoctorNotificationService() => _instance;
  DoctorNotificationService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final EnhancedNotificationService _enhancedNotificationService = EnhancedNotificationService();

  /// Lấy danh sách thông báo của bác sĩ theo thời gian thực
  /// Sắp xếp theo thời gian mới nhất (Requirements 10.4)
  Stream<List<NotificationModel>> getNotifications(String doctorId) {
    return _db
        .child('notifications')
        .child(doctorId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final List<NotificationModel> notifications = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          if (value != null) {
            final notifData = Map<String, dynamic>.from(value as Map);
            notifData['notificationId'] = key;
            notifications.add(NotificationModel.fromJson(notifData));
          }
        });
      }
      // Sắp xếp theo thời gian mới nhất (descending)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Lấy số lượng thông báo chưa đọc
  Stream<int> getUnreadCount(String doctorId) {
    return getNotifications(doctorId).map((notifications) {
      return notifications.where((n) => !n.isRead).length;
    });
  }

  /// Đánh dấu thông báo đã đọc (Requirements 10.5)
  Future<bool> markAsRead(String doctorId, String notificationId) async {
    try {
      await _db
          .child('notifications')
          .child(doctorId)
          .child(notificationId)
          .update({'isRead': true});
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<bool> markAllAsRead(String doctorId) async {
    try {
      final snapshot = await _db.child('notifications').child(doctorId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final updates = <String, dynamic>{};
        for (var key in data.keys) {
          updates['$key/isRead'] = true;
        }
        await _db.child('notifications').child(doctorId).update(updates);
      }
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }


  /// Gửi thông báo SOS mới cho tất cả bác sĩ đang trực (Requirements 10.1)
  Future<void> sendSOSNotification({
    required String sosId,
    required String patientName,
    required String patientId,
    String? location,
  }) async {
    try {
      // Lấy danh sách bác sĩ đang trực (có thể mở rộng logic này)
      final doctorsSnapshot = await _db.child('doctors').get();
      
      if (doctorsSnapshot.exists && doctorsSnapshot.value != null) {
        final doctors = Map<String, dynamic>.from(doctorsSnapshot.value as Map);
        
        for (var doctorId in doctors.keys) {
          final doctorData = doctors[doctorId];
          // Kiểm tra bác sĩ có đang hoạt động không
          if (doctorData != null && doctorData['isActive'] == true) {
            await _createNotification(
              userId: doctorId,
              type: 'sos',
              title: '🚨 Cảnh báo SOS khẩn cấp',
              message: 'Bệnh nhân $patientName đã kích hoạt SOS!${location != null ? '\nVị trí: $location' : ''}',
              data: {
                'sosId': sosId,
                'patientId': patientId,
                'patientName': patientName,
                'route': '/doctor/sos-case-detail',
                'targetId': sosId,
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending SOS notification: $e');
    }
  }

  /// Gửi thông báo lịch hẹn mới cho bác sĩ (Requirements 10.2)
  Future<String?> sendAppointmentNotification({
    required String doctorId,
    required String appointmentId,
    required String patientName,
    required String status,
    DateTime? appointmentTime,
  }) async {
    String title;
    String message;
    
    switch (status) {
      case 'new_request':
        title = '📅 Yêu cầu lịch hẹn mới';
        message = 'Bệnh nhân $patientName đã gửi yêu cầu đặt lịch khám';
        if (appointmentTime != null) {
          message += '\nThời gian: ${_formatDateTime(appointmentTime)}';
        }
        break;
      case 'cancelled':
        title = '❌ Lịch hẹn đã hủy';
        message = 'Bệnh nhân $patientName đã hủy lịch hẹn';
        break;
      case 'rescheduled':
        title = '🔄 Yêu cầu đổi lịch';
        message = 'Bệnh nhân $patientName yêu cầu đổi lịch hẹn';
        break;
      default:
        title = '📅 Cập nhật lịch hẹn';
        message = 'Lịch hẹn với bệnh nhân $patientName đã được cập nhật';
    }
    
    return await _createNotification(
      userId: doctorId,
      type: 'appointment',
      title: title,
      message: message,
      data: {
        'appointmentId': appointmentId,
        'patientName': patientName,
        'status': status,
        'route': '/doctor/appointment-detail',
        'targetId': appointmentId,
      },
    );
  }

  /// Gửi thông báo tin nhắn mới cho bác sĩ (Requirements 10.3)
  Future<String?> sendChatNotification({
    required String doctorId,
    required String conversationId,
    required String patientName,
    required String messagePreview,
  }) async {
    return await _createNotification(
      userId: doctorId,
      type: 'chat',
      title: '💬 Tin nhắn mới từ $patientName',
      message: messagePreview.length > 100 
          ? '${messagePreview.substring(0, 100)}...' 
          : messagePreview,
      data: {
        'conversationId': conversationId,
        'patientName': patientName,
        'route': '/doctor/chat-detail',
        'targetId': conversationId,
      },
    );
  }

  /// Gửi thông báo đánh giá mới
  Future<String?> sendReviewNotification({
    required String doctorId,
    required String reviewId,
    required String patientName,
    required int rating,
  }) async {
    return await _createNotification(
      userId: doctorId,
      type: 'review',
      title: '⭐ Đánh giá mới',
      message: 'Bệnh nhân $patientName đã đánh giá bạn $rating sao',
      data: {
        'reviewId': reviewId,
        'patientName': patientName,
        'rating': rating,
        'route': '/doctor/reviews',
        'targetId': reviewId,
      },
    );
  }

  /// Gửi thông báo đơn thuốc đã được mua
  Future<String?> sendPrescriptionPurchasedNotification({
    required String doctorId,
    required String prescriptionId,
    required String patientName,
  }) async {
    return await _createNotification(
      userId: doctorId,
      type: 'prescription',
      title: '💊 Đơn thuốc đã được mua',
      message: 'Bệnh nhân $patientName đã mua thuốc theo đơn của bạn',
      data: {
        'prescriptionId': prescriptionId,
        'patientName': patientName,
        'route': '/doctor/prescriptions',
        'targetId': prescriptionId,
      },
    );
  }

  /// Tạo thông báo mới trong Firebase
  Future<String?> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
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
      
      // Gửi FCM push notification
      await _sendFCMNotification(userId, title, message, type, data);
      
      return notificationId;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  /// Gửi FCM notification
  Future<void> _sendFCMNotification(
    String userId,
    String title,
    String message,
    String type,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Lấy FCM token của user
      final tokenSnapshot = await _db.child('user_tokens').child(userId).get();
      
      if (!tokenSnapshot.exists || tokenSnapshot.value == null) {
        debugPrint('No FCM token found for user: $userId');
        return;
      }
      
      final tokenData = Map<String, dynamic>.from(tokenSnapshot.value as Map);
      final fcmToken = tokenData['token'] as String?;
      
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM token is empty for user: $userId');
        return;
      }
      
      // Lưu notification request để Cloud Function xử lý
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
      
      debugPrint('FCM notification queued for user: $userId');
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
    }
  }

  /// Xóa thông báo
  Future<bool> deleteNotification(String doctorId, String notificationId) async {
    try {
      await _db
          .child('notifications')
          .child(doctorId)
          .child(notificationId)
          .remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Xóa tất cả thông báo
  Future<bool> clearAllNotifications(String doctorId) async {
    try {
      await _db.child('notifications').child(doctorId).remove();
      return true;
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      return false;
    }
  }

  /// Format DateTime thành chuỗi hiển thị
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
