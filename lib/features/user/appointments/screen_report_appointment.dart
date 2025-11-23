import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/appointment_model.dart';
import 'screen_appointment_detail.dart';

class ScreenReportAppointment extends StatefulWidget {
  const ScreenReportAppointment({super.key});

  @override
  State<ScreenReportAppointment> createState() => _ScreenReportAppointmentState();
}

class _ScreenReportAppointmentState extends State<ScreenReportAppointment> {
  final _appointmentService = AppointmentService();
  final _authService = AuthService();
  
  String? _userId;
  bool _showUpcoming = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _authService.getUserId();
    print('📍 Report Appointments - User ID: $userId');
    setState(() => _userId = userId);
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('EEEE, dd/MM/yyyy - HH:mm').format(date);
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
          title: const Text('Lịch hẹn & Báo cáo'),
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
          'Lịch hẹn & Báo cáo',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _appointmentService.getUserAppointments(_userId!),
              builder: (context, snapshot) {
                final all = snapshot.data ?? [];
                final upcoming = all.where((a) => a.isUpcoming).length;
                final past = all.where((a) => a.isPast).length;
                
                return Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        icon: Icons.upcoming,
                        label: 'Sắp tới',
                        value: '$upcoming',
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.history,
                        label: 'Đã qua',
                        value: '$past',
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${snapshot.error}'),
                      ],
                    ),
                  );
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
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _showUpcoming
                                ? 'Chưa có lịch hẹn sắp tới'
                                : 'Chưa có lịch sử lịch hẹn',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showUpcoming
                                ? 'Các lịch hẹn của bạn sẽ hiển thị ở đây'
                                : 'Lịch sử các lịch hẹn đã qua sẽ hiển thị ở đây',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
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
                      child: _EnhancedAppointmentCard(
                        appointment: appointment,
                        formatDate: _formatDate,
                        formatTime: _formatTime,
                        getStatusColor: _getStatusColor,
                        getStatusBgColor: _getStatusBgColor,
                        getStatusIcon: _getStatusIcon,
                        getStatusText: _getStatusText,
                        onTap: () async {
                          await Navigator.push(
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
                                  final success = await _appointmentService
                                      .cancelAppointment(
                                    appointment.appointmentId,
                                    'Hủy bởi người dùng',
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Đã hủy lịch hẹn'
                                              : 'Lỗi khi hủy lịch hẹn',
                                        ),
                                        backgroundColor:
                                            success ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }
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
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnhancedAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final String Function(int) formatDate;
  final String Function(int) formatTime;
  final Color Function(String) getStatusColor;
  final Color Function(String) getStatusBgColor;
  final IconData Function(String) getStatusIcon;
  final String Function(String) getStatusText;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _EnhancedAppointmentCard({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(getStatusIcon(appointment.status), color: statusColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    getStatusText(appointment.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: onCancel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reason
                  Text(
                    appointment.reason,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Doctor
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF135BEC),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bác sĩ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              appointment.doctorName ?? 'Chưa cập nhật',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF135BEC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Date & Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDate(appointment.appointmentTime),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111318),
                              ),
                            ),
                            Text(
                              formatTime(appointment.appointmentTime),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appointment.location,
                          style: const TextStyle(
                            fontSize: 14,
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
