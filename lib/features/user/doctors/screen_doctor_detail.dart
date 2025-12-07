import 'package:flutter/material.dart';
import '../../../data/models/doctor_models.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_schedule_service.dart';
import '../../../services/chat_service.dart';
import '../chat/screen_chat_detail.dart';

class ScreenDoctorDetail extends StatefulWidget {
  final DoctorModel doctor;

  const ScreenDoctorDetail({super.key, required this.doctor});

  @override
  State<ScreenDoctorDetail> createState() => _ScreenDoctorDetailState();
}

class _ScreenDoctorDetailState extends State<ScreenDoctorDetail> {
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  final _scheduleService = DoctorScheduleService();
  final _chatService = ChatService();
  
  bool _isStartingChat = false;
  
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedSlot;
  bool _isBooking = false;
  bool _isLoadingSlots = false;
  List<TimeSlot> _availableSlots = [];
  DoctorAvailability? _doctorAvailability;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    try {
      // Load doctor availability
      _doctorAvailability = await _scheduleService.getDoctorAvailability(widget.doctor.doctorId);
      
      // Get available slots for selected date
      final slots = await _scheduleService.getAvailableSlots(
        widget.doctor.doctorId,
        _selectedDate,
      );
      
      setState(() {
        _availableSlots = slots;
      });
    } catch (e) {
      debugPrint('Error loading slots: $e');
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  bool _isDateOnLeave(DateTime date) {
    if (_doctorAvailability == null) return false;
    return _scheduleService.isOnLeave(date, _doctorAvailability!.leaves);
  }

  bool _isDayWorking(DateTime date) {
    if (_doctorAvailability == null) return true; // Assume working if no schedule
    final daySchedule = _doctorAvailability!.weeklySchedule.daySlots[date.weekday];
    return daySchedule?.isWorking ?? false;
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ khám')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not found');

      // Combine date and time
      final appointmentTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedSlot!.startTime.hour,
        _selectedSlot!.startTime.minute,
      );

      // Book the slot using the schedule service
      await _scheduleService.bookSlot(
        widget.doctor.doctorId,
        appointmentTime,
        userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context); // Go back to list
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  String _formatTimeSlot(TimeSlot slot) {
    final startHour = slot.startTime.hour.toString().padLeft(2, '0');
    final startMinute = slot.startTime.minute.toString().padLeft(2, '0');
    final endHour = slot.endTime.hour.toString().padLeft(2, '0');
    final endMinute = slot.endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF135BEC);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.doctor.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.doctor.name)}&background=random',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorInfo(primary),
                  const SizedBox(height: 24),
                  _buildDateSelector(primary),
                  const SizedBox(height: 24),
                  _buildTimeSlots(primary),
                  const SizedBox(height: 32),
                  _buildBookButton(primary),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.doctor.specialization ?? 'Chưa cập nhật',
                    style: TextStyle(
                      fontSize: 16,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work, color: Colors.blue, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.doctor.yearsOfExperience ?? 0} năm KN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isStartingChat ? null : _startChat,
                icon: _isStartingChat 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: const Text('Nhắn tin'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/rate-doctor',
                  arguments: widget.doctor,
                ),
                icon: const Icon(Icons.star_border),
                label: const Text('Đánh giá'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Thông tin bác sĩ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.doctor.bio ?? 'Chưa có thông tin giới thiệu',
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDateSelector(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ngày khám',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, // Next 2 weeks
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isOnLeave = _isDateOnLeave(date);
              final isWorking = _isDayWorking(date);
              final isAvailable = !isOnLeave && isWorking;
              
              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        setState(() => _selectedDate = date);
                        _loadAvailableSlots();
                      }
                    : null,
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : isAvailable
                            ? Colors.white
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : isAvailable
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? Colors.grey
                                  : Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? Colors.black
                                  : Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (isOnLeave)
                        Text(
                          'Nghỉ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[300],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn giờ khám',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_isLoadingSlots)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Không có lịch trống trong ngày này',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng chọn ngày khác',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableSlots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return ChoiceChip(
                label: Text(_formatTimeSlot(slot)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedSlot = selected ? slot : null);
                },
                selectedColor: primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBookButton(Color primary) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isBooking || _selectedSlot == null ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isBooking
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Đặt lịch ngay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  Future<void> _startChat() async {
    setState(() => _isStartingChat = true);
    
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Vui lòng đăng nhập để nhắn tin');
      }

      // Create or get existing conversation
      final conversationId = await _chatService.createOrGetConversation(
        userId: userId,
        doctorId: widget.doctor.doctorId,
        doctorName: widget.doctor.name,
      );

      if (conversationId == null) {
        throw Exception('Không thể tạo cuộc trò chuyện');
      }

      if (!mounted) return;

      // Navigate to chat detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreenChatDetail(
            conversationId: conversationId,
            title: widget.doctor.name,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
    }
  }
}
