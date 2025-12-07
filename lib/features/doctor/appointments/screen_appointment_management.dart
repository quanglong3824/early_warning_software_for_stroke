import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/appointment_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/doctor_bottom_nav.dart';
import 'screen_appointment_request_detail.dart';

class ScreenAppointmentManagement extends StatefulWidget {
  const ScreenAppointmentManagement({super.key});

  @override
  State<ScreenAppointmentManagement> createState() =>
      _ScreenAppointmentManagementState();
}

class _ScreenAppointmentManagementState
    extends State<ScreenAppointmentManagement>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final userId = await _authService.getUserId();
    if (userId != null && mounted) {
      setState(() {
        _doctorId = userId;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lịch hẹn'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Sắp tới'),
            Tab(text: 'Yêu cầu'),
          ],
        ),
      ),
      body: _doctorId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayAppointments(),
                _buildUpcomingAppointments(),
                _buildPendingRequests(),
              ],
            ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 2),
    );
  }

  Widget _buildTodayAppointments() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getTodayAppointments(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Không có lịch hẹn hôm nay',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return _buildAppointmentList(appointments, showActions: true);
      },
    );
  }

  Widget _buildUpcomingAppointments() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getUpcomingDoctorAppointments(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Không có lịch hẹn sắp tới',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return _buildAppointmentList(appointments, showActions: true);
      },
    );
  }

  Widget _buildPendingRequests() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _appointmentService.getPendingRequests(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Không có yêu cầu đang chờ',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return _buildAppointmentList(appointments, isPending: true);
      },
    );
  }


  Widget _buildAppointmentList(List<AppointmentModel> appointments,
      {bool showActions = false, bool isPending = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment,
            showActions: showActions, isPending: isPending);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment,
      {bool showActions = false, bool isPending = false}) {
    final dateTime =
        DateTime.fromMillisecondsSinceEpoch(appointment.appointmentTime);
    final timeStr = DateFormat('HH:mm').format(dateTime);
    final dateStr = DateFormat('dd/MM/yyyy').format(dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isPending) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScreenAppointmentRequestDetail(
                  appointmentId: appointment.appointmentId,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(appointment.status)
                        .withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName ?? 'Bệnh nhân',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$timeStr - $dateStr',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(appointment.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.medical_services,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.reason,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              if (appointment.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.location,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
              if (showActions || isPending) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildActionButtons(appointment, isPending: isPending),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildActionButtons(AppointmentModel appointment,
      {bool isPending = false}) {
    if (isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRejectDialog(appointment),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Từ chối',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmAppointment(appointment),
              icon: const Icon(Icons.check),
              label: const Text('Xác nhận'),
            ),
          ),
        ],
      );
    }

    // Actions cho lịch hẹn đã xác nhận
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (appointment.status == 'confirmed') ...[
          OutlinedButton.icon(
            onPressed: () => _showRescheduleDialog(appointment),
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Đổi lịch'),
          ),
          ElevatedButton.icon(
            onPressed: () => _completeAppointment(appointment),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
        if (appointment.status == 'pending') ...[
          OutlinedButton.icon(
            onPressed: () => _showRejectDialog(appointment),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            label: const Text('Từ chối',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmAppointment(appointment),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Xác nhận'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Đã từ chối';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  Future<void> _confirmAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lịch hẹn'),
        content: Text(
            'Bạn có chắc muốn xác nhận lịch hẹn với ${appointment.patientName ?? "bệnh nhân"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _appointmentService
          .confirmAppointment(appointment.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã xác nhận lịch hẹn'
                : 'Không thể xác nhận lịch hẹn'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(AppointmentModel appointment) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối lịch hẹn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn từ chối lịch hẹn với ${appointment.patientName ?? "bệnh nhân"}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối',
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _appointmentService.rejectAppointment(
          appointment.appointmentId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Đã từ chối lịch hẹn' : 'Không thể từ chối lịch hẹn'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRescheduleDialog(AppointmentModel appointment) async {
    DateTime selectedDate = DateTime.fromMillisecondsSinceEpoch(appointment.appointmentTime);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    final reasonController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đổi lịch hẹn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Giờ'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do đổi lịch',
                    hintText: 'Nhập lý do đổi lịch...',
                    border: OutlineInputBorder(),
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
                final newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                Navigator.pop(context, {
                  'newTime': newDateTime.millisecondsSinceEpoch,
                  'reason': reasonController.text.trim(),
                });
              },
              child: const Text('Đổi lịch'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final success = await _appointmentService.rescheduleAppointment(
        appointmentId: appointment.appointmentId,
        newTime: result['newTime'] as int,
        reason: result['reason'] as String?,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã đổi lịch hẹn' : 'Không thể đổi lịch hẹn'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành lịch hẹn'),
        content: Text(
            'Xác nhận hoàn thành lịch hẹn với ${appointment.patientName ?? "bệnh nhân"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _appointmentService
          .completeAppointment(appointment.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã hoàn thành lịch hẹn'
                : 'Không thể hoàn thành lịch hẹn'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
