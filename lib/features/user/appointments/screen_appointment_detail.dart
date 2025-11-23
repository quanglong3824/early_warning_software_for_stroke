import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/appointment_model.dart';
import '../../../services/appointment_service.dart';

class ScreenAppointmentDetail extends StatefulWidget {
  final AppointmentModel appointment;

  const ScreenAppointmentDetail({
    super.key,
    required this.appointment,
  });

  @override
  State<ScreenAppointmentDetail> createState() => _ScreenAppointmentDetailState();
}

class _ScreenAppointmentDetailState extends State<ScreenAppointmentDetail> {
  final _appointmentService = AppointmentService();
  late AppointmentModel _appointment;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('EEEE, dd/MM/yyyy - HH:mm').format(date);
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.event;
    }
  }

  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch hẹn'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _appointmentService.cancelAppointment(
      _appointment.appointmentId,
      'Hủy bởi người dùng',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã hủy lịch hẹn' : 'Lỗi khi hủy lịch hẹn'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    final statusColor = _getStatusColor(_appointment.status);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết lịch hẹn',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(_appointment.status),
                      size: 40,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(_appointment.status),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(_appointment.appointmentTime),
                    style: const TextStyle(
                      fontSize: 16,
                      color: textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Appointment Details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin lịch hẹn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    Icons.medical_services,
                    'Lý do khám',
                    _appointment.reason,
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons.person,
                    'Bác sĩ',
                    _appointment.doctorName ?? 'Chưa xác định',
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons.location_on,
                    'Địa điểm',
                    _appointment.location,
                  ),
                  if (_appointment.department != null) ...[
                    const Divider(height: 32),
                    _buildInfoRow(
                      Icons.business,
                      'Khoa',
                      _appointment.department!,
                    ),
                  ],
                  if (_appointment.building != null ||
                      _appointment.floor != null ||
                      _appointment.room != null) ...[
                    const Divider(height: 32),
                    _buildInfoRow(
                      Icons.room,
                      'Phòng',
                      [
                        if (_appointment.building != null) 'Tòa ${_appointment.building}',
                        if (_appointment.floor != null) 'Tầng ${_appointment.floor}',
                        if (_appointment.room != null) 'Phòng ${_appointment.room}',
                      ].join(', '),
                    ),
                  ],
                  if (_appointment.notes != null && _appointment.notes!.isNotEmpty) ...[
                    const Divider(height: 32),
                    _buildInfoRow(
                      Icons.note,
                      'Ghi chú',
                      _appointment.notes!,
                    ),
                  ],
                ],
              ),
            ),

            // Timeline
            if (_appointment.confirmedAt != null ||
                _appointment.cancelledAt != null ||
                _appointment.rescheduledAt != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch sử',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      'Tạo lịch hẹn',
                      _formatDate(_appointment.createdAt),
                      Colors.blue,
                    ),
                    if (_appointment.confirmedAt != null)
                      _buildTimelineItem(
                        'Đã xác nhận',
                        _formatDate(_appointment.confirmedAt!),
                        Colors.green,
                      ),
                    if (_appointment.rescheduledAt != null)
                      _buildTimelineItem(
                        'Đã đổi lịch',
                        _formatDate(_appointment.rescheduledAt!),
                        Colors.orange,
                        subtitle: _appointment.rescheduleReason,
                      ),
                    if (_appointment.cancelledAt != null)
                      _buildTimelineItem(
                        'Đã hủy',
                        _formatDate(_appointment.cancelledAt!),
                        Colors.red,
                        subtitle: _appointment.cancelReason,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _appointment.canCancel
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _cancelAppointment,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy lịch hẹn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF135BEC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF135BEC), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111318),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    Color color, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
