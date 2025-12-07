import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';
import '../../../services/doctor_notification_service.dart';
import '../../../services/auth_service.dart';

/// Màn hình thông báo cho bác sĩ
/// Requirements: 10.4, 10.5
/// - Hiển thị danh sách thông báo từ Firebase
/// - Sắp xếp theo thời gian mới nhất
/// - Hiển thị trạng thái đã đọc/chưa đọc
/// - Đánh dấu đã đọc khi tap vào thông báo
class ScreenDoctorNotifications extends StatefulWidget {
  const ScreenDoctorNotifications({super.key});

  @override
  State<ScreenDoctorNotifications> createState() => _ScreenDoctorNotificationsState();
}

class _ScreenDoctorNotificationsState extends State<ScreenDoctorNotifications> {
  final _notificationService = DoctorNotificationService();
  final _authService = AuthService();
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final id = await _authService.getUserId();
    if (mounted) {
      setState(() {
        _doctorId = id;
      });
    }
  }

  /// Xử lý các action từ menu
  Future<void> _handleMenuAction(String action) async {
    if (_doctorId == null) return;

    switch (action) {
      case 'mark_all_read':
        final success = await _notificationService.markAllAsRead(_doctorId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                  ? 'Đã đánh dấu tất cả đã đọc' 
                  : 'Có lỗi xảy ra'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        break;
      case 'clear_all':
        final confirmed = await _showConfirmDialog(
          'Xóa tất cả thông báo',
          'Bạn có chắc chắn muốn xóa tất cả thông báo?',
        );
        if (confirmed == true) {
          final success = await _notificationService.clearAllNotifications(_doctorId!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success 
                    ? 'Đã xóa tất cả thông báo' 
                    : 'Có lỗi xảy ra'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
        break;
    }
  }

  /// Xử lý khi tap vào thông báo - đánh dấu đã đọc và điều hướng
  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (_doctorId == null) return;

    // Đánh dấu đã đọc (Requirements 10.5)
    if (!notification.isRead) {
      await _notificationService.markAsRead(_doctorId!, notification.notificationId);
    }

    // Điều hướng dựa trên loại thông báo
    if (mounted) {
      _navigateToNotificationTarget(notification);
    }
  }

  /// Điều hướng đến màn hình tương ứng với thông báo
  void _navigateToNotificationTarget(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return;

    final targetId = data['targetId'] as String?;

    switch (notification.type) {
      case 'sos':
        if (targetId != null) {
          Navigator.pushNamed(context, '/doctor/sos-case-detail', arguments: targetId);
        }
        break;
      case 'appointment':
        if (targetId != null) {
          Navigator.pushNamed(context, '/doctor/appointment-detail', arguments: targetId);
        }
        break;
      case 'chat':
        final conversationId = data['conversationId'] as String?;
        final patientName = data['patientName'] as String?;
        if (conversationId != null) {
          Navigator.pushNamed(
            context, 
            '/doctor/chat-detail',
            arguments: {
              'conversationId': conversationId,
              'patientName': patientName ?? 'Bệnh nhân',
            },
          );
        }
        break;
      case 'review':
        Navigator.pushNamed(context, '/doctor/reviews');
        break;
      case 'prescription':
        Navigator.pushNamed(context, '/doctor/prescriptions');
        break;
      default:
        // Không điều hướng cho các loại thông báo khác
        break;
    }
  }

  /// Xử lý khi swipe để xóa thông báo
  Future<void> _handleNotificationDismiss(NotificationModel notification) async {
    if (_doctorId == null) return;

    final success = await _notificationService.deleteNotification(
      _doctorId!, 
      notification.notificationId,
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa thông báo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Hiển thị dialog xác nhận
  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Thông báo',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_doctorId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: textPrimary),
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('Đánh dấu tất cả đã đọc'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _doctorId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<NotificationModel>>(
              // Notifications are sorted by newest first in the service (Requirements 10.4)
              stream: _notificationService.getNotifications(_doctorId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, 
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có thông báo nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationItem(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onDismiss: () => _handleNotificationDismiss(notification),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

/// Widget hiển thị một thông báo
class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF60646C);

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead 
                ? Colors.grey.shade200 
                : primary.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon theo loại thông báo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      color: _getIconColor(),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nội dung thông báo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.bold,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Chấm tròn chưa đọc
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lấy icon theo loại thông báo
  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'sos':
        return Icons.emergency;
      case 'appointment':
        return Icons.calendar_today;
      case 'chat':
        return Icons.chat_bubble;
      case 'review':
        return Icons.star;
      case 'prescription':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }

  /// Lấy màu icon theo loại thông báo
  Color _getIconColor() {
    switch (notification.type) {
      case 'sos':
        return Colors.red;
      case 'appointment':
        return const Color(0xFF135BEC);
      case 'chat':
        return Colors.green;
      case 'review':
        return Colors.orange;
      case 'prescription':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Lấy màu nền icon theo loại thông báo
  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case 'sos':
        return Colors.red.withOpacity(0.1);
      case 'appointment':
        return const Color(0xFF135BEC).withOpacity(0.1);
      case 'chat':
        return Colors.green.withOpacity(0.1);
      case 'review':
        return Colors.orange.withOpacity(0.1);
      case 'prescription':
        return Colors.purple.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  /// Format thời gian hiển thị
  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
