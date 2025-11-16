import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/family_service.dart';

class ScreenNotifications extends StatefulWidget {
  const ScreenNotifications({super.key});

  @override
  State<ScreenNotifications> createState() => _ScreenNotificationsState();
}

class _ScreenNotificationsState extends State<ScreenNotifications> {
  final _authService = AuthService();
  final _familyService = FamilyService();
  
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final notifications = await _familyService.getNotifications(userId);

      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    await _familyService.markAsRead(userId, notificationId);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    await _familyService.markAllAsRead(userId);
    _loadNotifications();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đánh dấu tất cả là đã đọc'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'family_request':
        return Icons.person_add;
      case 'family_accepted':
        return Icons.check_circle;
      case 'family_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'family_request':
        return Colors.blue;
      case 'family_accepted':
        return Colors.green;
      case 'family_rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        title: const Text(
          'Thông báo',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có thông báo nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] ?? false;
                      final type = notification['type'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notification['id']);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.3),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getColor(type).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIcon(type),
                                    color: _getColor(type),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'] ?? '',
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['message'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTime(notification['createdAt']),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
