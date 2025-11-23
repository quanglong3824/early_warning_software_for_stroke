import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/enhanced_notification_service.dart';
import '../../../data/models/notification_model.dart';

class ScreenNotifications extends StatefulWidget {
  const ScreenNotifications({super.key});

  @override
  State<ScreenNotifications> createState() => _ScreenNotificationsState();
}

class _ScreenNotificationsState extends State<ScreenNotifications> {
  final _authService = AuthService();
  final _notificationService = EnhancedNotificationService();
  
  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: primary),
            onPressed: _markAllAsRead,
            tooltip: 'Đánh dấu tất cả đã đọc',
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _authService.getUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userId = snapshot.data!;

          return StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.getUserNotifications(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Không có thông báo nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationItem(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      await _notificationService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.userId, notification.notificationId);
    }
    // Handle navigation logic here if needed
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  String _getTimeAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    return '${difference.inDays} ngày trước';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'appointment': return Icons.calendar_today;
      case 'medication': return Icons.medication;
      case 'security': return Icons.security;
      case 'family': return Icons.people;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'appointment': return Colors.blue;
      case 'medication': return Colors.green;
      case 'security': return Colors.red;
      case 'family': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(notification.type).withOpacity(0.1),
          child: Icon(_getIcon(notification.type), color: _getColor(notification.type)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _getTimeAgo(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
