import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/reminder_service.dart';
import '../../../services/notification_service.dart';

class ScreenAddReminder extends StatefulWidget {
  const ScreenAddReminder({super.key});

  @override
  State<ScreenAddReminder> createState() => _ScreenAddReminderState();
}

class _ScreenAddReminderState extends State<ScreenAddReminder> {
  final _authService = AuthService();
  final _reminderService = ReminderService();
  final _notificationService = NotificationService();
  
  final _titleController = TextEditingController();
  final _noteController = TextEditingController(); // Using as dosage for now or separate? Model has dosage.
  // Let's add dosage controller
  final _dosageController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _dosageController.dispose();
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
      setState(() => _selectedTime = picked);
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
        const SnackBar(content: Text('Vui lòng nhập tên thuốc'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not found');

      final timeString = _formatTime(_selectedTime);

      final reminderId = await _reminderService.createReminder(
        userId: userId,
        prescriptionId: '', // Optional
        medicationName: _titleController.text.trim(),
        dosage: _dosageController.text.trim(),
        times: [timeString],
      );

      if (reminderId != null) {
        // Schedule notification
        await _notificationService.scheduleDailyNotification(
          id: reminderId.hashCode,
          title: 'Đến giờ uống thuốc',
          body: 'Hãy uống ${_titleController.text.trim()} ${_dosageController.text.trim()}',
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          payload: {'type': 'reminder', 'reminderId': reminderId},
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm nhắc nhở thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create reminder');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
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
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildLabel('Tên thuốc *'),
            _buildTextField(_titleController, 'Ví dụ: Aspirin'),
            const SizedBox(height: 16),
            _buildLabel('Liều lượng'),
            _buildTextField(_dosageController, 'Ví dụ: 1 viên, 100mg'),
            const SizedBox(height: 16),
            _buildLabel('Ghi chú'),
            _buildTextField(_noteController, 'Ví dụ: Uống sau ăn', maxLines: 3),
            const SizedBox(height: 16),
            _buildLabel('Thời gian'),
            _buildTimePicker(primary, textPrimary),
            const SizedBox(height: 32),
            _buildSubmitButton(primary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111318)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBDFE6)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTimePicker(Color primary, Color textPrimary) {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDBDFE6)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Row(
          children: [
            Icon(Icons.access_time, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatTime(_selectedTime),
                style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Color primary) {
    return SizedBox(
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Lưu nhắc nhở', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
