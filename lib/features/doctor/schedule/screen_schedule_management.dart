import 'package:flutter/material.dart';
import '../../../services/doctor_schedule_service.dart';
import '../../../services/health_chart_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/enhanced_notification_service.dart';
import '../../../widgets/doctor_bottom_nav.dart';

class ScreenScheduleManagement extends StatefulWidget {
  const ScreenScheduleManagement({super.key});

  @override
  State<ScreenScheduleManagement> createState() => _ScreenScheduleManagementState();
}

class _ScreenScheduleManagementState extends State<ScreenScheduleManagement>
    with SingleTickerProviderStateMixin {
  final _scheduleService = DoctorScheduleService();
  final _authService = AuthService();
  final _notificationService = EnhancedNotificationService();
  
  late TabController _tabController;
  String? _doctorId;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Weekly schedule state
  final Map<int, DaySchedule> _weeklySchedule = {};
  final List<String> _dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  
  // Leave records
  List<LeaveRecord> _leaves = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSchedule();
    _loadData();
  }
  
  void _initializeSchedule() {
    // Initialize default schedule for all days
    for (int i = 1; i <= 7; i++) {
      _weeklySchedule[i] = DaySchedule(
        isWorking: i <= 5, // Mon-Fri working by default
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        slotDurationMinutes: 30,
      );
    }
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _doctorId = await _authService.getUserId();
      if (_doctorId == null) return;
      
      final availability = await _scheduleService.getDoctorAvailability(_doctorId!);
      if (availability != null) {
        setState(() {
          // Load weekly schedule
          availability.weeklySchedule.daySlots.forEach((day, schedule) {
            _weeklySchedule[day] = schedule;
          });
          _leaves = availability.leaves;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWeeklySchedule() async {
    if (_doctorId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final schedule = WeeklySchedule(daySlots: _weeklySchedule);
      await _scheduleService.setWeeklySchedule(_doctorId!, schedule);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu lịch làm việc'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _addLeave() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddLeaveDialog(),
    );
    
    if (result == null || _doctorId == null) return;
    
    try {
      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;
      final reason = result['reason'] as String?;
      
      await _scheduleService.setLeave(
        _doctorId!,
        DateRange(start: startDate, end: endDate),
        reason: reason,
      );
      
      // Reload leaves
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm ngày nghỉ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
  
  Future<void> _removeLeave(LeaveRecord leave) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ngày nghỉ'),
        content: const Text('Bạn có chắc chắn muốn xóa ngày nghỉ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    
    if (confirm != true || _doctorId == null) return;
    
    try {
      await _scheduleService.removeLeave(_doctorId!, leave.leaveId);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa ngày nghỉ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    const bgLight = Color(0xFFF6F6F8);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Quản lý lịch làm việc'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'Lịch hàng tuần'),
            Tab(text: 'Ngày nghỉ'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyScheduleTab(),
                _buildLeavesTab(),
              ],
            ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildWeeklyScheduleTab() {
    const primary = Color(0xFF135BEC);
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayNumber = index + 1;
              final schedule = _weeklySchedule[dayNumber]!;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: schedule.isWorking
                              ? primary.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _dayNames[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: schedule.isWorking ? primary : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        _getFullDayName(dayNumber),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: schedule.isWorking
                          ? Text(
                              '${_formatTime(schedule.startTime!)} - ${_formatTime(schedule.endTime!)}',
                              style: TextStyle(color: Colors.grey[600]),
                            )
                          : const Text(
                              'Nghỉ',
                              style: TextStyle(color: Colors.grey),
                            ),
                      trailing: Switch(
                        value: schedule.isWorking,
                        onChanged: (value) {
                          setState(() {
                            _weeklySchedule[dayNumber] = DaySchedule(
                              isWorking: value,
                              startTime: schedule.startTime ?? const TimeOfDay(hour: 8, minute: 0),
                              endTime: schedule.endTime ?? const TimeOfDay(hour: 17, minute: 0),
                              slotDurationMinutes: schedule.slotDurationMinutes,
                              bookedSlots: schedule.bookedSlots,
                            );
                          });
                        },
                        activeColor: primary,
                      ),
                    ),
                    if (schedule.isWorking) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTimeSelector(
                                label: 'Bắt đầu',
                                time: schedule.startTime!,
                                onTap: () => _selectTime(dayNumber, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeSelector(
                                label: 'Kết thúc',
                                time: schedule.endTime!,
                                onTap: () => _selectTime(dayNumber, false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveWeeklySchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Lưu lịch làm việc',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeavesTab() {
    const primary = Color(0xFF135BEC);
    
    return Column(
      children: [
        Expanded(
          child: _leaves.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có ngày nghỉ nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn nút bên dưới để thêm ngày nghỉ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaves.length,
                  itemBuilder: (context, index) {
                    final leave = _leaves[index];
                    final startDate = DateTime.fromMillisecondsSinceEpoch(leave.startDate);
                    final endDate = DateTime.fromMillisecondsSinceEpoch(leave.endDate);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_busy,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: leave.reason != null && leave.reason!.isNotEmpty
                            ? Text(leave.reason!)
                            : const Text('Không có lý do'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeLeave(leave),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addLeave,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Thêm ngày nghỉ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectTime(int dayNumber, bool isStart) async {
    final schedule = _weeklySchedule[dayNumber]!;
    final initialTime = isStart ? schedule.startTime! : schedule.endTime!;
    
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (time == null) return;
    
    setState(() {
      _weeklySchedule[dayNumber] = DaySchedule(
        isWorking: schedule.isWorking,
        startTime: isStart ? time : schedule.startTime,
        endTime: isStart ? schedule.endTime : time,
        slotDurationMinutes: schedule.slotDurationMinutes,
        bookedSlots: schedule.bookedSlots,
      );
    });
  }
  
  String _getFullDayName(int day) {
    switch (day) {
      case 1: return 'Thứ Hai';
      case 2: return 'Thứ Ba';
      case 3: return 'Thứ Tư';
      case 4: return 'Thứ Năm';
      case 5: return 'Thứ Sáu';
      case 6: return 'Thứ Bảy';
      case 7: return 'Chủ Nhật';
      default: return '';
    }
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


class _AddLeaveDialog extends StatefulWidget {
  @override
  State<_AddLeaveDialog> createState() => _AddLeaveDialogState();
}

class _AddLeaveDialogState extends State<_AddLeaveDialog> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null) return;
    
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = date;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    
    return AlertDialog(
      title: const Text('Thêm ngày nghỉ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ngày bắt đầu',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ngày kết thúc',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lý do (tùy chọn)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Nhập lý do nghỉ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'startDate': _startDate,
              'endDate': _endDate,
              'reason': _reasonController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: primary),
          child: const Text('Thêm', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
