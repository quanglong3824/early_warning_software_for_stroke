import 'package:flutter/material.dart';
import '../../../data/models/doctor_models.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';

class ScreenDoctorDetail extends StatefulWidget {
  final DoctorModel doctor;

  const ScreenDoctorDetail({super.key, required this.doctor});

  @override
  State<ScreenDoctorDetail> createState() => _ScreenDoctorDetailState();
}

class _ScreenDoctorDetailState extends State<ScreenDoctorDetail> {
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isBooking = false;

  final List<String> _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '13:30', '14:00', '14:30', '15:00', '15:30', '16:00'
  ];

  Future<void> _bookAppointment() async {
    if (_selectedTime == null) {
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
      final timeParts = _selectedTime!.split(':');
      final appointmentTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      await _appointmentService.createAppointment(
        userId: userId,
        doctorId: widget.doctor.doctorId,
        doctorName: widget.doctor.name,
        appointmentTime: appointmentTime.millisecondsSinceEpoch,
        location: widget.doctor.hospital ?? 'Phòng khám',
        reason: 'Khám trực tiếp',
        notes: 'Đặt lịch khám qua ứng dụng',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context); // Go back to list
      Navigator.pop(context); // Go back to home/appointments
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isBooking = false);
    }
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
                              style: const TextStyle(
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/rate-doctor',
                        arguments: widget.doctor,
                      ),
                      icon: const Icon(Icons.star_border),
                      label: const Text('Viết đánh giá'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Thông tin bác sĩ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.doctor.bio ?? 'Chưa có thông tin giới thiệu',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
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
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primary : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Th ${date.weekday + 1}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Chọn giờ khám',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _timeSlots.map((time) {
                      final isSelected = time == _selectedTime;
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (selected) => setState(() => _selectedTime = selected ? time : null),
                        selectedColor: primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
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
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
