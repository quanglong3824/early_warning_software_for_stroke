import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

class ScreenRemindersList extends StatefulWidget {
  const ScreenRemindersList({super.key});

  @override
  State<ScreenRemindersList> createState() => _ScreenRemindersListState();
}

class _ScreenRemindersListState extends State<ScreenRemindersList> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  final _database = FirebaseDatabase.instance.ref();
  
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _notificationService.initialize();
    await _checkPermission();
    await _loadReminders();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _notificationService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    setState(() {
      _hasPermission = granted;
    });
    
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cấp quyền thông báo trong cài đặt'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final snapshot = await _database
          .child('reminders')
          .child(userId)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final reminders = <Map<String, dynamic>>[];
        
        data.forEach((key, value) {
          final reminder = Map<String, dynamic>.from(value as Map);
          reminder['id'] = key;
          reminders.add(reminder);
        });

        // Sắp xếp theo thời gian trong code
        reminders.sort((a, b) {
          final timeA = a['time'] as String? ?? '00:00';
          final timeB = b['time'] as String? ?? '00:00';
          return timeA.compareTo(timeB);
        });

        setState(() {
          _reminders = reminders;
        });
      } else {
        setState(() {
          _reminders = [];
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReminder(String reminderId, bool currentStatus) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final newStatus = !currentStatus;
      
      await _database
          .child('reminders')
          .child(userId)
          .child(reminderId)
          .update({'isActive': newStatus});

      // Cập nhật notification
      final reminder = _reminders.firstWhere((r) => r['id'] == reminderId);
      final notificationId = reminderId.hashCode;

      if (newStatus) {
        // Bật thông báo
        final timeParts = (reminder['time'] as String).split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        await _notificationService.scheduleDailyNotification(
          id: notificationId,
          title: reminder['title'] ?? 'Nhắc nhở',
          body: reminder['note'] ?? '',
          hour: hour,
          minute: minute,
          payload: reminderId,
        );
      } else {
        // Tắt thông báo
        await _notificationService.cancelNotification(notificationId);
      }

      await _loadReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteReminder(String reminderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa nhắc nhở này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      await _database
          .child('reminders')
          .child(userId)
          .child(reminderId)
          .remove();

      // Hủy notification
      final notificationId = reminderId.hashCode;
      await _notificationService.cancelNotification(notificationId);

      await _loadReminders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa nhắc nhở'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textSecondary = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Nhắc nhở uống thuốc'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed('/add-reminder');
              if (result == true) {
                _loadReminders();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_hasPermission)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_off, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Chưa cấp quyền thông báo',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cấp quyền để nhận nhắc nhở đúng giờ',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _requestPermission,
                          child: const Text('Cấp quyền'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _reminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có nhắc nhở nào',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).pushNamed('/add-reminder');
                                  if (result == true) {
                                    _loadReminders();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm nhắc nhở'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _reminders[index];
                            final isActive = reminder['isActive'] ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  Icons.medication,
                                  color: isActive ? primary : Colors.grey,
                                  size: 32,
                                ),
                                title: Text(
                                  reminder['title'] ?? 'Nhắc nhở',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      reminder['note'] ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          reminder['time'] ?? '',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: isActive,
                                      activeColor: primary,
                                      onChanged: (value) {
                                        _toggleReminder(reminder['id'], isActive);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: primary),
                                      onPressed: () async {
                                        final result = await Navigator.of(context).pushNamed(
                                          '/edit-reminder',
                                          arguments: reminder,
                                        );
                                        if (result == true) {
                                          _loadReminders();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteReminder(reminder['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
