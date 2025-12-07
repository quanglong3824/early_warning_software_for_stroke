import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/reminder_service.dart';
import '../../../services/notification_service.dart';

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
  double _adherenceRate = 0.0;
  bool _isLoadingAdherence = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _notificationService.initialize();
    await _checkPermission();
    await _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await _authService.getUserId();
    if (mounted && userId != null) {
      setState(() => _userId = userId);
      await _loadAdherenceRate(userId);
    }
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

  /// Load adherence rate for the last 30 days
  /// Implements Requirements 7.5 - display adherence percentage
  Future<void> _loadAdherenceRate(String userId) async {
    setState(() => _isLoadingAdherence = true);
    
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    
    final rate = await _reminderService.getAdherenceRate(userId, startDate, endDate);
    
    if (mounted) {
      setState(() {
        _adherenceRate = rate;
        _isLoadingAdherence = false;
      });
    }
  }

  Future<void> _toggleReminder(ReminderModel reminder, bool value) async {
    await _reminderService.toggleReminder(reminder.reminderId, value);
    
    if (value) {
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
          payload: {'type': 'reminder', 'reminderId': reminder.reminderId},
        );
      }
    } else {
      await _notificationService.cancelNotification(reminder.reminderId.hashCode);
    }
  }

  /// Mark medication as taken
  /// Implements Requirements 7.3 - log event with timestamp
  Future<void> _markAsTaken(ReminderModel reminder) async {
    final now = DateTime.now();
    
    // Find the closest scheduled time for today
    DateTime scheduledTime = now;
    if (reminder.times.isNotEmpty) {
      for (final timeStr in reminder.times) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        
        // Use the closest past time or current time
        if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
          scheduledTime = scheduled;
        }
      }
    }
    
    final success = await _reminderService.markAsTaken(
      reminder.reminderId, 
      scheduledTime,
    );
    
    if (success && mounted) {
      // Cancel any pending follow-up reminders
      await _reminderService.cancelFollowUpReminder(reminder.reminderId, scheduledTime);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã ghi nhận uống ${reminder.medicationName}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: Colors.white,
            onPressed: () {
              // Could implement undo functionality here
            },
          ),
        ),
      );
      
      // Refresh adherence rate
      if (_userId != null) {
        await _loadAdherenceRate(_userId!);
      }
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

  Color _getAdherenceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getAdherenceMessage(double rate) {
    if (rate >= 80) return 'Tuyệt vời! Bạn đang tuân thủ tốt';
    if (rate >= 60) return 'Khá tốt, cố gắng duy trì nhé';
    if (rate > 0) return 'Cần cải thiện việc uống thuốc đúng giờ';
    return 'Chưa có dữ liệu';
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

          return Column(
            children: [
              // Adherence Rate Card - Implements Requirements 7.5
              _buildAdherenceCard(primary),
              
              // Reminders List
              Expanded(
                child: StreamBuilder<List<ReminderModel>>(
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
                      return _buildEmptyState(primary);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = reminders[index];
                        return _buildReminderCard(reminder, primary);
                      },
                    );
                  },
                ),
              ),
            ],
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

  /// Build adherence rate card
  /// Implements Requirements 7.5 - display adherence percentage
  Widget _buildAdherenceCard(Color primary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tỷ lệ tuân thủ (30 ngày)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              if (_isLoadingAdherence)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _isLoadingAdherence ? '--' : '${_adherenceRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _isLoadingAdherence ? Colors.grey : _getAdherenceColor(_adherenceRate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _isLoadingAdherence ? 0 : _adherenceRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isLoadingAdherence ? Colors.grey : _getAdherenceColor(_adherenceRate),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoadingAdherence ? '' : _getAdherenceMessage(_adherenceRate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primary) {
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

  Widget _buildReminderCard(ReminderModel reminder, Color primary) {
    final time = reminder.times.isNotEmpty ? reminder.times[0] : '??:??';
    final adherence = reminder.adherenceRate;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
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
                if (reminder.logs.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: _getAdherenceColor(adherence),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tuân thủ: ${adherence.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getAdherenceColor(adherence),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Switch(
              value: reminder.isActive,
              onChanged: (val) => _toggleReminder(reminder, val),
              activeColor: primary,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/edit-reminder',
                arguments: reminder.toJson(),
              );
            },
            onLongPress: () => _deleteReminder(reminder.reminderId),
          ),
          
          // Mark as Taken Button - Implements Requirements 7.3
          if (reminder.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OutlinedButton.icon(
                onPressed: () => _markAsTaken(reminder),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Đã uống thuốc'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
