import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/appointment_service.dart';
import '../../../services/auth_service.dart';
import '../../../data/models/appointment_model.dart';
import 'screen_appointment_detail.dart';

class ScreenAppointments extends StatefulWidget {
  const ScreenAppointments({super.key});

  @override
  State<ScreenAppointments> createState() => _ScreenAppointmentsState();
}

class _ScreenAppointmentsState extends State<ScreenAppointments> {
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
    print('📍 Appointments Screen - User ID: $userId');
    setState(() => _userId = userId);
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('EEEE, dd/MM/yyyy - HH:mm').format(date);
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
        return Icons.task_alt;
      case 'pending':
        return Icons.pending_actions;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.check_circle;
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
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF6B7280);

    if (_userId == null) {
      return Scaffold(
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Lịch hẹn của tôi'),
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
            onPressed: () {
              // TODO: Navigate to create appointment screen
            },
            icon: const Icon(Icons.add, color: textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _showUpcoming = true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Sắp tới',
                            style: TextStyle(
                              color: _showUpcoming ? primary : textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_showUpcoming)
                            const SizedBox(
                              height: 3,
                              child: ColoredBox(color: primary),
                            )
                          else
                            const SizedBox(height: 3),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _showUpcoming = false),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Đã qua',
                            style: TextStyle(
                              color: !_showUpcoming ? primary : textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!_showUpcoming)
                            const SizedBox(
                              height: 3,
                              child: ColoredBox(color: primary),
                            )
                          else
                            const SizedBox(height: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _showUpcoming
                  ? _appointmentService.getUpcomingAppointments(_userId!)
                  : _appointmentService.getPastAppointments(_userId!),
              builder: (context, snapshot) {
                print('📍 Appointments Stream - ConnectionState: ${snapshot.connectionState}');
                print('📍 Appointments Stream - HasError: ${snapshot.hasError}');
                print('📍 Appointments Stream - Data count: ${snapshot.data?.length ?? 0}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('❌ Appointments Error: ${snapshot.error}');
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final appointments = snapshot.data ?? [];
                print('📍 Appointments loaded: ${appointments.length} items');
                for (var apt in appointments) {
                  print('  - ${apt.reason} at ${apt.location} (${apt.status})');
                }

                if (appointments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showUpcoming
                                ? 'Chưa có lịch hẹn sắp tới'
                                : 'Chưa có lịch hẹn đã qua',
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AppointmentCard(
                        icon: _getStatusIcon(appointment.status),
                        iconBg: _getStatusBgColor(appointment.status),
                        iconColor: _getStatusColor(appointment.status),
                        title: appointment.reason,
                        subtitle: appointment.doctorName ?? 'Bác sĩ',
                        location: appointment.location,
                        time: _formatDateTime(appointment.appointmentTime),
                        status: _getStatusText(appointment.status),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScreenAppointmentDetail(
                                appointment: appointment,
                              ),
                            ),
                          );
                          // Refresh if appointment was cancelled
                          if (result == true && mounted) {
                            setState(() {});
                          }
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

class _AppointmentCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String location;
  final String time;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const _AppointmentCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.time,
    required this.status,
    this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onCancel != null)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: onCancel,
              )
            else
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}