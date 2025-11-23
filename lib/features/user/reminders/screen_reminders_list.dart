import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/prescription_service.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/prescription_models.dart';

class ScreenRemindersList extends StatefulWidget {
  const ScreenRemindersList({super.key});

  @override
  State<ScreenRemindersList> createState() => _ScreenRemindersListState();
}

class _ScreenRemindersListState extends State<ScreenRemindersList> {
  final _authService = AuthService();
  final _reminderService = ReminderService();
  final _notificationService = NotificationService();
  
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _notificationService.initialize();
    await _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _notificationService.hasPermission();
    if (mounted) setState(() => _hasPermission = hasPermission);
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    if (mounted) setState(() => _hasPermission = granted);
    
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cấp quyền thông báo trong cài đặt'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _toggleReminder(ReminderModel reminder, bool value) async {
    await _reminderService.toggleReminder(reminder.reminderId, value);
    
    if (value) {
      // Re-schedule notification
      // Note: This logic needs to be robust. For now, simple re-schedule.
      // In a real app, we might need to handle multiple times.
      // Assuming 'times' list has "HH:mm" strings.
      if (reminder.times.isNotEmpty) {
        final timeParts = reminder.times[0].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        await _notificationService.scheduleDailyNotification(
          id: reminder.reminderId.hashCode,
          title: reminder.medicationName,
          body: 'Đã đến giờ uống thuốc: ${reminder.medicationName}',
          hour: hour,
          minute: minute,
          payload: reminder.reminderId,
        );
      }
    } else {
      // Cancel notification
      await _notificationService.cancelNotification(reminder.reminderId.hashCode);
    }
  }

  Future<void> _deleteReminder(String reminderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhắc nhở?'),
        content: const Text('Bạn có chắc chắn muốn xóa nhắc nhở này không?'),
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

    if (confirm == true) {
      await _reminderService.deleteReminder(reminderId);
      await _notificationService.cancelNotification(reminderId.hashCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Nhắc nhở uống thuốc', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_hasPermission)
            IconButton(
              icon: const Icon(Icons.notifications_off, color: Colors.orange),
              onPressed: _requestPermission,
              tooltip: 'Bật thông báo',
            ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _authService.getUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userId = snapshot.data!;

          return StreamBuilder<List<ReminderModel>>(
            stream: _reminderService.getUserReminders(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final reminders = snapshot.data ?? [];

              if (reminders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có nhắc nhở nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/add-reminder'),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm nhắc nhở'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  final time = reminder.times.isNotEmpty ? reminder.times[0] : '??:??';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: reminder.isActive ? primary.withOpacity(0.1) : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medication,
                          color: reminder.isActive ? primary : Colors.grey,
                        ),
                      ),
                      title: Text(
                        reminder.medicationName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: reminder.isActive ? Colors.black : Colors.grey,
                          decoration: reminder.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(time, style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              if (reminder.dosage.isNotEmpty) ...[
                                Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(reminder.dosage, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: reminder.isActive,
                        onChanged: (val) => _toggleReminder(reminder, val),
                        activeColor: primary,
                      ),
                      onTap: () {
                        // Navigate to edit (converting model to map for compatibility if needed, or update Edit screen)
                        // For now, let's update Edit screen to accept ReminderModel or Map
                        // Or just pass arguments as Map for simplicity with existing route
                        Navigator.pushNamed(
                          context,
                          '/edit-reminder',
                          arguments: reminder.toJson(),
                        );
                      },
                      onLongPress: () => _deleteReminder(reminder.reminderId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-reminder'),
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
