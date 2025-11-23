import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../data/models/notification_model.dart';

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

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

  /// Create notification
  Future<String?> createNotification({
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
      
      // TODO: Send FCM push notification here
      // await _sendFCMNotification(userId, title, message, data);
      
      return notificationId;
    } catch (e) {
      print('Error creating notification: $e');
      return null;
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

  // TODO: Implement FCM
  // Future<void> _sendFCMNotification(
  //   String userId,
  //   String title,
  //   String message,
  //   Map<String, dynamic>? data,
  // ) async {
  //   // Get user FCM token from database
  //   // Send push notification via Firebase Cloud Messaging
  // }
}
