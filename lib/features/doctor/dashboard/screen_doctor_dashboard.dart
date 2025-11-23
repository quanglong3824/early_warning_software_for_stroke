import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../widgets/doctor_drawer.dart';
import '../../../widgets/doctor_bottom_nav.dart';
import '../../../mixins/account_status_check_mixin.dart';
import '../../../services/auth_service.dart';
import '../../../services/appointment_service.dart';
import '../../../data/models/appointment_model.dart';
import 'dart:math';

class ScreenDoctorDashboard extends StatefulWidget {
  const ScreenDoctorDashboard({super.key});

  @override
  State<ScreenDoctorDashboard> createState() => _ScreenDoctorDashboardState();
}

class _ScreenDoctorDashboardState extends State<ScreenDoctorDashboard> 
    with AccountStatusCheckMixin {
  
  final _authService = AuthService();
  final _appointmentService = AppointmentService();
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
    final alerts = appData.alerts; // Keep alerts from provider for now (or make dynamic later)

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
        title: const Text('Dashboard Trực Ca', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: textPrimary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin ca trực
            Container(
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
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _doctorId == null 
                        ? const SizedBox()
                        : StreamBuilder<List<AppointmentModel>>(
                            stream: _appointmentService.getDoctorAppointments(_doctorId!),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.map((e) => e.userId).toSet().length ?? 0;
                              return _buildInfoChip('$count Bệnh nhân', Icons.people);
                            }
                          ),
                      const SizedBox(width: 12),
                      _buildInfoChip('${alerts.where((a) => !a.isRead).length} Cảnh báo', Icons.warning_amber),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Thống kê nhanh
            const Text(
              'Thống kê hôm nay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 12),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Lịch hẹn', '8', Icons.calendar_today, Colors.blue),
                _buildStatCard('SOS', '2', Icons.emergency, Colors.red),
                _buildStatCard('Tư vấn', '12', Icons.chat_bubble, Colors.green),
                _buildStatCard('Đơn thuốc', '15', Icons.medication, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Bệnh nhân gần đây (Dynamic)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bệnh nhân gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/doctor/patients'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _doctorId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<AppointmentModel>>(
                    stream: _appointmentService.getDoctorAppointments(_doctorId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final appointments = snapshot.data ?? [];
                      if (appointments.isEmpty) {
                        return const Center(child: Text('Chưa có bệnh nhân nào'));
                      }

                      // Get unique patients
                      final uniquePatientIds = <String>{};
                      final uniquePatients = <AppointmentModel>[];
                      for (var apt in appointments) {
                        if (uniquePatientIds.add(apt.userId)) {
                          uniquePatients.add(apt);
                        }
                        if (uniquePatients.length >= 5) break; // Limit to 5
                      }

                      return Column(
                        children: uniquePatients.map((apt) => _PatientCardItem(userId: apt.userId)).toList(),
                      );
                    },
                  ),
            
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
              Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
}

class _PatientCardItem extends StatelessWidget {
  final String userId;

  const _PatientCardItem({required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance.ref();

    return FutureBuilder<DataSnapshot>(
      future: db.child('users').child(userId).get(),
      builder: (context, snapshot) {
        String name = 'Đang tải...';
        String status = 'Ổn định'; // Default status
        Color statusColor = Colors.green;

        if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.value != null) {
          final dynamic value = snapshot.data!.value;
          Map<dynamic, dynamic> data = {};
          if (value is Map) {
            data = value;
          } else if (value is List) {
             // Should not happen for a single user object, but safe to handle
             // Actually for a single object, List is unlikely unless keys are 0,1...
             // But if it's a List, we can't easily map it to user fields unless we know the schema.
             // For 'users/userId', it should be a Map.
             // If it's not a Map, we skip.
          }
          
          if (value is Map) {
             final userData = Map<String, dynamic>.from(value);
             name = userData['name'] ?? 'Bệnh nhân';
          }
        }

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
                child: Icon(Icons.person, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('ID: ${userId.substring(0, min(8, userId.length))}...', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
                    'userId': userId,
                    'patientName': name,
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

