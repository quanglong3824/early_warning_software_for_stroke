import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Notification payload for deep linking
class NotificationPayload {
  final String type;
  final String? targetId;
  final String? route;
  final Map<String, dynamic>? data;

  NotificationPayload({
    required this.type,
    this.targetId,
    this.route,
    this.data,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] ?? 'general',
      targetId: json['targetId'],
      route: json['route'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'targetId': targetId,
      'route': route,
      'data': data,
    };
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling background message: ${message.messageId}');
  // Note: Cannot show local notification here as it requires initialization
  // The notification will be shown by FCM automatically
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  
  bool _initialized = false;
  String? _fcmToken;
  
  // Stream controller for notification taps
  final StreamController<NotificationPayload> _notificationTapController = 
      StreamController<NotificationPayload>.broadcast();
  
  /// Stream of notification taps for deep linking
  Stream<NotificationPayload> get onNotificationTap => _notificationTapController.stream;

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    // Use device local timezone by default, do not force specific location
    // tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize FCM
    await _initializeFCM();

    _initialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initializeFCM() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission
    await _requestFCMPermission();
    
    // Get initial token
    await _getAndSaveToken();
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenToDatabase(newToken);
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
    
    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  Future<void> _requestFCMPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    debugPrint('FCM Permission status: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    try {
      _fcmToken = await _messaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to database for a specific user
  Future<void> saveTokenForUser(String userId) async {
    if (_fcmToken == null) {
      await _getAndSaveToken();
    }
    
    if (_fcmToken != null && userId.isNotEmpty) {
      await _saveTokenToDatabase(_fcmToken!, userId: userId);
    }
  }

  Future<void> _saveTokenToDatabase(String token, {String? userId}) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _db.child('user_tokens').child(userId).set({
          'token': token,
          'updatedAt': ServerValue.timestamp,
          'platform': defaultTargetPlatform.name,
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Subscribe to a topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      // Show local notification for foreground messages
      showNotification(
        id: message.hashCode,
        title: notification.title ?? 'SEWS',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
    
    final payload = NotificationPayload(
      type: message.data['type'] ?? 'general',
      targetId: message.data['targetId'],
      route: message.data['route'],
      data: message.data,
    );
    
    _notificationTapController.add(payload);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!);
        final payload = NotificationPayload.fromJson(data);
        _notificationTapController.add(payload);
      } catch (e) {
        // If payload is not JSON, treat it as a simple type
        _notificationTapController.add(NotificationPayload(
          type: response.payload!,
        ));
      }
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check notification permission
  Future<bool> hasPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    String channelName = 'Thông báo',
    String? channelDescription,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription ?? 'Kênh thông báo chung',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule a local notification with timezone support
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? payload,
    String channelId = 'reminders_channel',
    String channelName = 'Nhắc nhở',
    String? channelDescription,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription ?? 'Kênh thông báo nhắc nhở',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadString = payload != null ? jsonEncode(payload) : null;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payloadString,
    );
  }

  /// Schedule a daily repeating notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Nhắc nhở',
      channelDescription: 'Kênh thông báo nhắc nhở uống thuốc',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payloadString = payload != null ? jsonEncode(payload) : null;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadString,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Schedule a medication reminder notification
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? prescriptionId,
  }) async {
    final payload = {
      'type': 'reminder',
      'route': '/reminders',
      'medicationName': medicationName,
      'dosage': dosage,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
    };

    await scheduleLocalNotification(
      id: id,
      title: 'Nhắc nhở uống thuốc',
      body: '$medicationName - $dosage',
      scheduledTime: scheduledTime,
      payload: payload,
      channelId: 'medication_reminders',
      channelName: 'Nhắc nhở uống thuốc',
      channelDescription: 'Thông báo nhắc nhở uống thuốc theo đơn',
    );
  }

  /// Schedule an appointment reminder notification
  Future<void> scheduleAppointmentReminder({
    required int id,
    required String doctorName,
    required DateTime appointmentTime,
    required DateTime reminderTime,
    String? appointmentId,
  }) async {
    final payload = {
      'type': 'appointment',
      'route': '/appointments',
      if (appointmentId != null) 'appointmentId': appointmentId,
    };

    await scheduleLocalNotification(
      id: id,
      title: 'Nhắc nhở lịch hẹn',
      body: 'Bạn có lịch hẹn với bác sĩ $doctorName',
      scheduledTime: reminderTime,
      payload: payload,
      channelId: 'appointment_reminders',
      channelName: 'Nhắc nhở lịch hẹn',
      channelDescription: 'Thông báo nhắc nhở lịch hẹn khám bệnh',
    );
  }

  /// Schedule a follow-up reminder (for missed medication doses)
  Future<void> scheduleFollowUpReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required int delayMinutes,
    String? prescriptionId,
  }) async {
    final scheduledTime = DateTime.now().add(Duration(minutes: delayMinutes));
    
    final payload = {
      'type': 'reminder',
      'route': '/reminders',
      'medicationName': medicationName,
      'dosage': dosage,
      'isFollowUp': true,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
    };

    await scheduleLocalNotification(
      id: id,
      title: 'Nhắc nhở uống thuốc (lần 2)',
      body: 'Bạn chưa uống $medicationName - $dosage',
      scheduledTime: scheduledTime,
      payload: payload,
      channelId: 'medication_reminders',
      channelName: 'Nhắc nhở uống thuốc',
      channelDescription: 'Thông báo nhắc nhở uống thuốc theo đơn',
    );
  }

  /// Cancel multiple notifications by IDs
  Future<void> cancelNotifications(List<int> ids) async {
    for (final id in ids) {
      await _notifications.cancel(id);
    }
  }

  /// Check if a notification with given ID is pending
  Future<bool> isNotificationPending(int id) async {
    final pending = await getPendingNotifications();
    return pending.any((n) => n.id == id);
  }

  /// Get route from notification type
  static String? getRouteForNotificationType(String type) {
    switch (type) {
      case 'prescription':
        return '/prescriptions';
      case 'appointment':
        return '/appointments';
      case 'sos':
        return '/sos-status';
      case 'chat':
        return '/chat';
      case 'payment':
        return '/pharmacy/order-history';
      case 'reminder':
        return '/reminders';
      case 'health':
        return '/health-history';
      case 'family':
        return '/family-management';
      default:
        return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}
