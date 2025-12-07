import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/reminder_service.dart';
import '../../../services/notification_service.dart';

class ScreenEditReminder extends StatefulWidget {
  final Map<String, dynamic> reminder; // Accepting Map for compatibility with route args
  
  const ScreenEditReminder({super.key, required this.reminder});

  @override
  State<ScreenEditReminder> createState() => _ScreenEditReminderState();
}

class _ScreenEditReminderState extends State<ScreenEditReminder> {
  final _authService = AuthService();
  final _reminderService = ReminderService(); // Note: ReminderService doesn't have update method yet? Check service.
  // Checked service: It has toggleReminder and deleteReminder, but not updateReminder details.
  // I need to add updateReminder to ReminderService or use direct DB call here for now, OR add it to service.
  // Better to add to service. I will assume I'll add it.
  
  final _notificationService = NotificationService();
  
  late TextEditingController _titleController;
  late TextEditingController _dosageController;
  late TextEditingController _noteController;
  
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder['medicationName'] ?? widget.reminder['title'] ?? '');
    _dosageController = TextEditingController(text: widget.reminder['dosage'] ?? '');
    _noteController = TextEditingController(text: widget.reminder['note'] ?? ''); // Note might not be in model but in map
    
    // Parse time
    String timeString = '08:00';
    if (widget.reminder['times'] != null && (widget.reminder['times'] as List).isNotEmpty) {
      timeString = (widget.reminder['times'] as List)[0];
    } else if (widget.reminder['time'] != null) {
      timeString = widget.reminder['time'];
    }
    
    final timeParts = timeString.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dosageController.dispose();
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
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _updateReminder() async {
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

      final reminderId = widget.reminder['reminderId'] ?? widget.reminder['id'];
      final timeString = _formatTime(_selectedTime);

      // Since ReminderService doesn't have update method yet, I'll implement it in service first.
      // But I can't edit service file in the same turn easily if I want to be safe.
      // Actually I can. I will edit service file in next step.
      // For now, I'll assume it exists or use direct DB call as fallback?
      // No, let's use direct DB call here for now to be safe, or wait.
      // I will use direct DB call here for update to avoid blocking, then refactor service later if needed.
      // Actually, better to add to service.
      
      // Let's assume I will add `updateReminder` to `ReminderService`.
      // await _reminderService.updateReminder(...)
      
      // Temporary direct DB call to ensure it works immediately
      // Wait, I should use the service if I want to be consistent.
      // I'll add the method to the service in the next tool call.
      
      // For now, I will use a placeholder method that I will implement in service.
      // Or I can just use direct DB call here since I have access to FirebaseDatabase.
      // But I removed FirebaseDatabase import to clean up.
      // Let's re-add it or better, implement in service.
      
      // I will implement `updateReminder` in `PrescriptionService` (where ReminderService is) in the next step.
      // So here I will call it.
      
      await _reminderService.updateReminder(
        reminderId: reminderId,
        medicationName: _titleController.text.trim(),
        dosage: _dosageController.text.trim(),
        times: [timeString],
      );

      // Update notification
      final isActive = widget.reminder['isActive'] ?? true;
      if (isActive) {
        await _notificationService.cancelNotification(reminderId.hashCode);
        await _notificationService.scheduleDailyNotification(
          id: reminderId.hashCode,
          title: 'Đến giờ uống thuốc',
          body: 'Hãy uống ${_titleController.text.trim()} ${_dosageController.text.trim()}',
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          payload: reminderId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật nhắc nhở!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
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
        title: const Text('Chỉnh sửa nhắc nhở'),
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
        onPressed: !_isLoading ? _updateReminder : null,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Cập nhật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
