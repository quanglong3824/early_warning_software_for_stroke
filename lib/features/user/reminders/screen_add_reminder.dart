import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

class ScreenAddReminder extends StatefulWidget {
  const ScreenAddReminder({super.key});

  @override
  State<ScreenAddReminder> createState() => _ScreenAddReminderState();
}

class _ScreenAddReminderState extends State<ScreenAddReminder> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  final _database = FirebaseDatabase.instance.ref();
  
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên thuốc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Tạo reminder mới
      final reminderRef = _database.child('reminders').child(userId).push();
      final reminderId = reminderRef.key!;

      final reminderData = {
        'title': _titleController.text.trim(),
        'note': _noteController.text.trim(),
        'time': _formatTime(_selectedTime),
        'isActive': true,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      };

      await reminderRef.set(reminderData);

      // Lên lịch notification
      final notificationId = reminderId.hashCode;
      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: _titleController.text.trim(),
        body: _noteController.text.trim().isEmpty 
            ? 'Đã đến giờ uống thuốc' 
            : _noteController.text.trim(),
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        payload: reminderId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm nhắc nhở thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const borderColor = Color(0xFFDBDFE6);
    const textPrimary = Color(0xFF111318);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Thêm nhắc nhở'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nhắc nhở sẽ lặp lại hàng ngày vào giờ bạn đã chọn.',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tên thuốc *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Aspirin 100mg',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
                style: const TextStyle(color: textPrimary, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Uống sau bữa ăn sáng',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
                style: const TextStyle(color: textPrimary, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thời gian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatTime(_selectedTime),
                        style: const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: !_isLoading ? _saveReminder : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Lưu nhắc nhở',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
