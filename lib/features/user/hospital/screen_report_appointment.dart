import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_service.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/doctor_models.dart';
import '../../user/appointments/screen_appointment_detail.dart';

class ScreenReportAppointment extends StatefulWidget {
  const ScreenReportAppointment({super.key});

  @override
  State<ScreenReportAppointment> createState() => _ScreenReportAppointmentState();
}

class _ScreenReportAppointmentState extends State<ScreenReportAppointment> {
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  final _doctorService = DoctorService();
  
  String? _userId;
  bool _showUpcoming = true;
  bool _showCreateForm = false;

  // Form fields
  final _reasonController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DoctorModel? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getUserId();
    setState(() => _userId = userId);
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFFFA000);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFFE6F4EA);
      case 'pending':
        return const Color(0xFFFFF3CD);
      case 'cancelled':
        return const Color(0xFFFFE4E6);
      case 'completed':
        return const Color(0xFFE3F2FD);
      default:
        return Colors.grey[200]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.event;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'pending':
        return 'Chờ xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  Future<void> _createAppointment() async {
    if (_userId == null) return;

    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _reasonController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final appointmentId = await _appointmentService.createAppointment(
      userId: _userId!,
      doctorId: _selectedDoctor!.doctorId,
      doctorName: _selectedDoctor!.name,
      appointmentTime: appointmentDateTime.millisecondsSinceEpoch,
      location: _locationController.text,
      reason: _reasonController.text,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (mounted) {
      if (appointmentId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lịch hẹn thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _showCreateForm = false;
          _selectedDoctor = null;
          _selectedDate = null;
          _selectedTime = null;
          _reasonController.clear();
          _locationController.clear();
          _notesController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi đặt lịch hẹn'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFFEF4444);
    const textPrimary = Color(0xFF111318);

    if (_userId == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Lịch hẹn'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Lịch hẹn của tôi',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCreateForm ? Icons.close : Icons.add,
              color: textPrimary,
            ),
            onPressed: () {
              setState(() => _showCreateForm = !_showCreateForm);
            },
          ),
        ],
      ),
      body: _showCreateForm
          ? _buildCreateForm()
          : Column(
              children: [
                // Tab Selector
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _showUpcoming = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _showUpcoming ? primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              'Sắp tới',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _showUpcoming ? primary : const Color(0xFF6B7280),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _showUpcoming = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_showUpcoming ? primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              'Lịch sử',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_showUpcoming ? primary : const Color(0xFF6B7280),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Appointments List
                Expanded(
                  child: StreamBuilder<List<AppointmentModel>>(
                    stream: _showUpcoming
                        ? _appointmentService.getUpcomingAppointments(_userId!)
                        : _appointmentService.getPastAppointments(_userId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }

                      final appointments = snapshot.data ?? [];

                      if (appointments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showUpcoming ? Icons.event_available : Icons.history,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showUpcoming
                                      ? 'Chưa có lịch hẹn sắp tới'
                                      : 'Chưa có lịch sử',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AppointmentCard(
                              appointment: appointment,
                              formatDate: _formatDate,
                              formatTime: _formatTime,
                              getStatusColor: _getStatusColor,
                              getStatusBgColor: _getStatusBgColor,
                              getStatusIcon: _getStatusIcon,
                              getStatusText: _getStatusText,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScreenAppointmentDetail(
                                      appointment: appointment,
                                    ),
                                  ),
                                );
                              },
                              onCancel: appointment.canCancel
                                  ? () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Hủy lịch hẹn'),
                                          content: const Text(
                                            'Bạn có chắc muốn hủy lịch hẹn này?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Không'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Hủy lịch',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await _appointmentService.cancelAppointment(
                                          appointment.appointmentId,
                                          'Hủy bởi người dùng',
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCreateForm() {
    const primary = Color(0xFF135BEC);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Đặt lịch hẹn mới',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111318),
          ),
        ),
        const SizedBox(height: 24),

        // Doctor Selection
        const Text(
          'Chọn bác sĩ',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<DoctorModel>>(
          stream: _doctorService.getAllDoctors(),
          builder: (context, snapshot) {
            final doctors = snapshot.data ?? [];
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DoctorModel>(
                  isExpanded: true,
                  value: _selectedDoctor,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Chọn bác sĩ'),
                  ),
                  items: doctors.map((doctor) {
                    return DropdownMenuItem(
                      value: doctor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(doctor.name),
                      ),
                    );
                  }).toList(),
                  onChanged: (doctor) {
                    setState(() => _selectedDoctor = doctor);
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Date Selection
        const Text(
          'Chọn ngày',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: primary),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Chọn ngày',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? const Color(0xFF111318)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time Selection
        const Text(
          'Chọn giờ',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() => _selectedTime = time);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: primary),
                const SizedBox(width: 12),
                Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Chọn giờ',
                  style: TextStyle(
                    color: _selectedTime != null
                        ? const Color(0xFF111318)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Reason
        const Text(
          'Lý do khám',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: 'Nhập lý do khám',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Location
        const Text(
          'Địa điểm',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Nhập địa điểm khám',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Notes
        const Text(
          'Ghi chú (không bắt buộc)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú thêm',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _createAppointment,
            child: const Text(
              'Đặt lịch hẹn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final String Function(int) formatDate;
  final String Function(int) formatTime;
  final Color Function(String) getStatusColor;
  final Color Function(String) getStatusBgColor;
  final IconData Function(String) getStatusIcon;
  final String Function(String) getStatusText;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.formatDate,
    required this.formatTime,
    required this.getStatusColor,
    required this.getStatusBgColor,
    required this.getStatusIcon,
    required this.getStatusText,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(appointment.status);
    final statusBgColor = getStatusBgColor(appointment.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(getStatusIcon(appointment.status),
                      color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    getStatusText(appointment.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red, size: 20),
                      onPressed: onCancel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.reason,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person,
                          color: Color(0xFF135BEC), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.doctorName ?? 'Bác sĩ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF135BEC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF6B7280), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${formatDate(appointment.appointmentTime)} - ${formatTime(appointment.appointmentTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF6B7280), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}