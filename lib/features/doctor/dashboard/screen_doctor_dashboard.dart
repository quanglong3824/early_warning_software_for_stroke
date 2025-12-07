import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../widgets/doctor_drawer.dart';
import '../../../widgets/doctor_bottom_nav.dart';
import '../../../mixins/account_status_check_mixin.dart';
import '../../../services/auth_service.dart';
import '../../../services/doctor_dashboard_service.dart';
import 'dart:math';

class ScreenDoctorDashboard extends StatefulWidget {
  const ScreenDoctorDashboard({super.key});

  @override
  State<ScreenDoctorDashboard> createState() => _ScreenDoctorDashboardState();
}

class _ScreenDoctorDashboardState extends State<ScreenDoctorDashboard>
    with AccountStatusCheckMixin {
  final _authService = AuthService();
  final _dashboardService = DoctorDashboardService();
  String? _doctorName;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    final name = await _authService.getUserName();
    final id = await _authService.getUserId();
    if (mounted) {
      setState(() {
        _doctorName = name;
        _doctorId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const textPrimary = Color(0xFF111318);

    final appData = Provider.of<AppDataProvider>(context);
    final alerts = appData.alerts;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );

        if (shouldLogout == true && context.mounted) {
          Navigator.of(context).pushReplacementNamed('/doctor/login');
        }
      },
      child: Scaffold(
        drawer: DoctorDrawer(doctorName: _doctorName ?? 'Bác sĩ'),
        backgroundColor: bgLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: textPrimary, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          centerTitle: true,
          title: const Text('Dashboard Trực Ca',
              style:
                  TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: textPrimary, size: 28),
              onPressed: () => Navigator.pushNamed(context, '/doctor/notifications'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin ca trực
              _buildShiftInfoCard(alerts.where((a) => !a.isRead).length),
              const SizedBox(height: 24),

              // Thống kê nhanh
              const Text(
                'Thống kê hôm nay',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary),
              ),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Bệnh nhân gần đây
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bệnh nhân gần đây',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/doctor/patients'),
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentPatientsList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: const DoctorBottomNav(currentIndex: 0),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/doctor/sos-queue'),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.emergency),
          label: const Text('SOS Queue'),
        ),
      ),
    );
  }

  /// Build shift info card with real-time patient count
  Widget _buildShiftInfoCard(int alertCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF135BEC), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ca trực hiện tại',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ca Sáng: 07:00 - 15:00',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _doctorId == null
                  ? const SizedBox()
                  : StreamBuilder<int>(
                      stream:
                          _dashboardService.getTotalPatientCount(_doctorId!),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _buildInfoChip('$count Bệnh nhân', Icons.people);
                      },
                    ),
              const SizedBox(width: 12),
              _buildInfoChip('$alertCount Cảnh báo', Icons.warning_amber),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stats grid with real-time data from Firebase
  Widget _buildStatsGrid() {
    if (_doctorId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        // Lịch hẹn hôm nay - Requirements 1.1
        StreamBuilder<int>(
          stream: _dashboardService.getTodayAppointmentCount(_doctorId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildStatCardLoading(
                  'Lịch hẹn', Icons.calendar_today, Colors.blue);
            }
            if (snapshot.hasError) {
              return _buildStatCardError(
                  'Lịch hẹn', Icons.calendar_today, Colors.blue);
            }
            return _buildStatCard('Lịch hẹn', '${snapshot.data ?? 0}',
                Icons.calendar_today, Colors.blue);
          },
        ),
        // SOS đang hoạt động - Requirements 1.2
        StreamBuilder<int>(
          stream: _dashboardService.getActiveSOSCount(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildStatCardLoading('SOS', Icons.emergency, Colors.red);
            }
            if (snapshot.hasError) {
              return _buildStatCardError('SOS', Icons.emergency, Colors.red);
            }
            return _buildStatCard(
                'SOS', '${snapshot.data ?? 0}', Icons.emergency, Colors.red);
          },
        ),
        // Tin nhắn chưa đọc - Requirements 1.3
        StreamBuilder<int>(
          stream: _dashboardService.getUnreadMessageCount(_doctorId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildStatCardLoading(
                  'Tư vấn', Icons.chat_bubble, Colors.green);
            }
            if (snapshot.hasError) {
              return _buildStatCardError(
                  'Tư vấn', Icons.chat_bubble, Colors.green);
            }
            return _buildStatCard('Tư vấn', '${snapshot.data ?? 0}',
                Icons.chat_bubble, Colors.green);
          },
        ),
        // Đơn thuốc hôm nay - Requirements 1.4
        StreamBuilder<int>(
          stream: _dashboardService.getTodayPrescriptionCount(_doctorId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildStatCardLoading(
                  'Đơn thuốc', Icons.medication, Colors.orange);
            }
            if (snapshot.hasError) {
              return _buildStatCardError(
                  'Đơn thuốc', Icons.medication, Colors.orange);
            }
            return _buildStatCard('Đơn thuốc', '${snapshot.data ?? 0}',
                Icons.medication, Colors.orange);
          },
        ),
      ],
    );
  }

  /// Build recent patients list with real-time data - Requirements 1.6
  Widget _buildRecentPatientsList() {
    if (_doctorId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<PatientSummary>>(
      stream: _dashboardService.getRecentPatients(_doctorId!, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('Lỗi: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final patients = snapshot.data ?? [];
        if (patients.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Chưa có bệnh nhân nào'),
            ),
          );
        }

        return Column(
          children: patients
              .map((patient) => _PatientCardItem(patient: patient))
              .toList(),
        );
      },
    );
  }
}

// Helper widgets
Widget _buildInfoChip(String label, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    ),
  );
}

Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            Icon(icon, color: color, size: 24),
          ],
        ),
        Text(
          value,
          style:
              TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}

Widget _buildStatCardLoading(String title, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            Icon(icon, color: color, size: 24),
          ],
        ),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    ),
  );
}

Widget _buildStatCardError(String title, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            Icon(icon, color: color, size: 24),
          ],
        ),
        const Icon(Icons.error_outline, color: Colors.red, size: 28),
      ],
    ),
  );
}

class _PatientCardItem extends StatelessWidget {
  final PatientSummary patient;

  const _PatientCardItem({required this.patient});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high_risk':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'stable':
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'high_risk':
        return 'Nguy cơ cao';
      case 'warning':
        return 'Cảnh báo';
      case 'stable':
      default:
        return 'Ổn định';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(patient.status);
    final statusText = _getStatusText(patient.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: patient.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      patient.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, color: statusColor),
                    ),
                  )
                : Icon(Icons.person, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        'ID: ${patient.id.substring(0, min(8, patient.id.length))}...',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () => Navigator.pushNamed(
              context,
              '/doctor/patient-profile',
              arguments: {
                'userId': patient.id,
                'patientName': patient.name,
              },
            ),
          ),
        ],
      ),
    );
  }
}
